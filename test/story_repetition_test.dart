import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

String _response(String text, List<String> choices) =>
    jsonEncode({'text': text, 'choices': choices});

void main() {
  setUp(() => dotenv.loadFromString(envString: 'GPT_TOKEN=test-only'));
  tearDown(dotenv.clean);

  test(
    'repeated past choice is revised with the original context intact',
    () async {
      var calls = 0;
      final repository = StoryRepository(
        canUseAI: () => true,
        checkSafety: (_) async => true,
        requestCompletion: (request) async {
          calls++;
          final original = jsonDecode(request.messages[1]['content'] as String);
          expect(original['story_so_far'], 'Deniz kilitli kapının önündeydi.');
          expect(original['selected_choice'], 'Anahtarı dene');
          expect(original['previous_choices'], ['İçeri gir']);
          if (calls == 1) {
            return _response('Kilit açıldı.', [
              'İÇERİ GİR!',
              'Nöbetçiye seslen',
              'Mektubu oku',
            ]);
          }
          expect(
            jsonDecode(request.messages.last['content'] as String)['task'],
            'revise',
          );
          return _response('Kapı açılınca bir mektup yere düştü.', [
            'Mektubu oku',
            'Nöbetçiye seslen',
            'Koridoru dinle',
          ]);
        },
      );
      final story = await repository.continueStory(
        'Deniz kilitli kapının önündeydi.',
        'Anahtarı dene',
        'Gizem',
        'Kadın',
        'tr',
        previousChoices: ['İçeri gir'],
      );
      expect(calls, 2);
      expect(story!.choices, [
        'Mektubu oku',
        'Nöbetçiye seslen',
        'Koridoru dinle',
      ]);
    },
  );

  test('repeated passage is revised even when its choices are new', () async {
    var calls = 0;
    final repository = StoryRepository(
      canUseAI: () => true,
      checkSafety: (_) async => true,
      requestCompletion:
          (_) async => _response(
            ++calls == 1
                ? 'THE DOOR OPENED!'
                : 'A guard emerged from the doorway.',
            ['Speak to guard', 'Show the letter', 'Inspect the doorway'],
          ),
    );
    final story = await repository.continueStory(
      'She turned the key.\nThe door opened.',
      'Step inside',
      'Mystery',
      'Female',
      'en',
    );
    expect(calls, 2);
    expect(story!.text, 'A guard emerged from the doorway.');
  });

  test(
    'duplicate choices are never returned and retries are bounded',
    () async {
      var calls = 0;
      final repository = StoryRepository(
        canUseAI: () => true,
        checkSafety: (_) async => true,
        requestCompletion: (_) async {
          calls++;
          return _response('A bell rang.', [
            'Read the note',
            'READ THE NOTE!',
            'Ask the guard',
          ]);
        },
      );
      await expectLater(
        repository.startNewStory('Mystery', 'Female', 'en'),
        throwsFormatException,
      );
      expect(calls, 2);
    },
  );
}
