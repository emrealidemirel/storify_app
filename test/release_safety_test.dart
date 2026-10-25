import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/services/content_safety_service.dart';
import 'package:flutter_story_app/services/firebase_auth_service.dart';
import 'package:flutter_story_app/services/firebase_storage_service.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Info extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

class _Credential extends Fake implements UserCredential {}

class _User extends Fake implements User {
  final List<String> calls;
  bool failReauth = false;
  _User(this.calls);
  @override
  String get uid => 'owner';
  @override
  String get email => 'owner@example.com';
  @override
  List<UserInfo> get providerData => [_Info()];
  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    calls.add('reauth');
    if (failReauth) throw FirebaseAuthException(code: 'wrong-password');
    return _Credential();
  }

  @override
  Future<void> delete() async {
    calls.add('delete-auth');
  }
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  final User currentUser;
  _Auth(this.currentUser);
}

class _Storage extends FirebaseStorageService {
  final List<String> calls;
  bool fail = false;
  _Storage(this.calls);
  @override
  Future<void> deleteUserData(String userId) async {
    expect(userId, 'owner');
    calls.add('delete-files');
    if (fail) throw StateError('Storage unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'GPT_TOKEN=test-only');
  });
  tearDown(dotenv.clean);

  test(
    'account deletion reauthenticates, removes files, then auth and local data',
    () async {
      final calls = <String>[];
      final service = FirebaseAuthService(
        auth: _Auth(_User(calls)),
        storage: _Storage(calls),
      );
      await PreferencesService.saveLanguageCode('tr');
      await PreferencesService.saveLastStories(['Private story']);
      await PreferencesService.saveStoryOwner('owner');
      await PreferencesService.setAIConsent('owner', true);
      await service.deleteAccount('  valid password  ');
      expect(calls, ['reauth', 'delete-files', 'delete-auth']);
      expect(await PreferencesService.getLastStories(), isNull);
      expect(await PreferencesService.getStoryOwner(), isNull);
      expect(await PreferencesService.hasAIConsent('owner'), isFalse);
      expect(await PreferencesService.getLanguageCode(), 'tr');
    },
  );

  test(
    'failed file cleanup preserves auth so deletion can be retried',
    () async {
      final calls = <String>[];
      final storage = _Storage(calls)..fail = true;
      final service = FirebaseAuthService(
        auth: _Auth(_User(calls)),
        storage: storage,
      );
      await expectLater(
        service.deleteAccount('password'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(calls, ['reauth', 'delete-files']);
      storage.fail = false;
      await service.deleteAccount('password');
      expect(calls.last, 'delete-auth');
    },
  );

  test('reauth failure never removes any user data', () async {
    final calls = <String>[];
    final user = _User(calls)..failReauth = true;
    final service = FirebaseAuthService(
      auth: _Auth(user),
      storage: _Storage(calls),
    );
    await expectLater(
      service.deleteAccount('wrong'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(calls, ['reauth']);
  });

  test('AI permission belongs to the account and can be withdrawn', () async {
    await PreferencesService.setAIConsent('owner', true);
    expect(await PreferencesService.hasAIConsent('owner'), true);
    expect(await PreferencesService.hasAIConsent('other'), false);
    await PreferencesService.setAIConsent('owner', false);
    expect(await PreferencesService.hasAIConsent('owner'), false);
  });

  test('image signature check rejects disguised non-image files', () {
    expect(
      () => FirebaseStorageService.imageContentType(utf8.encode('<script>')),
      throwsFormatException,
    );
    expect(
      FirebaseStorageService.imageContentType([255, 216, 255, 0]),
      'image/jpeg',
    );
    expect(
      FirebaseStorageService.imageContentType([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]),
      'image/png',
    );
  });

  test('safety checks include choices and block flagged stories', () async {
    final repository = StoryRepository(
      canUseAI: () => true,
      requestCompletion:
          (_) async => jsonEncode({
            'text': 'A new passage',
            'choices': ['Open door', 'Read note', 'Ask guard'],
          }),
      checkSafety: (input) async {
        expect(input, contains('Ask guard'));
        return false;
      },
    );
    await expectLater(
      repository.startNewStory('Mystery', 'Female', 'en'),
      throwsA(isA<UnsafeStoryException>()),
    );
  });

  test(
    'moderation uses current endpoint and rejects incomplete responses',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/moderations');
        expect(jsonDecode(request.body)['input'], 'Passage');
        return http.Response('{"results":[]}', 200);
      });
      await expectLater(
        ContentSafetyService(client: client).isSafe('Passage', 'test-only'),
        throwsFormatException,
      );
      client.close();
    },
  );

  test(
    'moderation outage fails closed without exposing provider body',
    () async {
      final client = MockClient(
        (_) async => http.Response('sensitive provider response', 500),
      );
      try {
        await ContentSafetyService(
          client: client,
        ).isSafe('Passage', 'test-only');
        fail('Expected failure');
      } on FormatException catch (e) {
        expect(e.toString(), isNot(contains('sensitive provider response')));
      }
      client.close();
    },
  );
}
