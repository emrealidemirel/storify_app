import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/models/story_model.dart';
import 'package:flutter_story_app/pages/story_page.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthRepository extends Fake implements AuthRepository {
  @override
  User? getCurrentUser() => null;
}

class _StoryRepository extends StoryRepository {
  final continuation = Completer<Story?>();
  int requests = 0;

  @override
  Future<Story?> startNewStory(
    String theme,
    String gender,
    String language,
  ) async {
    return Story(
      text: 'Mevcut hikâye',
      choices: ['İlerle', 'Bekle', 'Araştır'],
    );
  }

  @override
  Future<Story?> continueStory(
    String history,
    String choice,
    String theme,
    String gender,
    String language, {
    List<String> previousChoices = const [],
  }) {
    requests++;
    return continuation.future;
  }
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'GPT_TOKEN=test-only');
    SharedPreferences.setMockInitialValues({'aiConsent:v1:test-user': true});
  });
  tearDown(dotenv.clean);

  for (final dark in [false, true]) {
    testWidgets('story remains visible during continuation, dark=$dark', (
      tester,
    ) async {
      final repository = _StoryRepository();
      final cubit = StoryCubit(
        storyRepository: repository,
        languageCode: 'tr',
        aiUserId: () => 'test-user',
      );
      final auth = AuthCubit(authRepository: _AuthRepository());
      addTearDown(cubit.close);
      addTearDown(auth.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: auth),
          ],
          child: Builder(
            builder:
                (context) => MaterialApp(
                  theme:
                      dark
                          ? AppTheme.darkTheme(context)
                          : AppTheme.lightTheme(context),
                  home: const StoryPage(continueFromLast: false),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mevcut hikâye'), findsOneWidget);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scroll.position.pixels;

      await tester.tap(find.text('İlerle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mevcut hikâye'), findsOneWidget);
      for (final choice in ['İlerle', 'Bekle', 'Araştır']) {
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, choice),
        );
        expect(button.onPressed, isNull);
      }
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable).first),
        same(scroll),
      );
      expect(scroll.position.pixels, offset);
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.color, dark ? AppTheme.gold : AppTheme.espresso);
      await tester.tap(find.text('İlerle'));
      expect(repository.requests, 1);

      repository.continuation.complete(
        Story(text: 'Yeni bölüm', choices: ['Yürü', 'Dinlen', 'Dön']),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mevcut hikâye'), findsOneWidget);
      expect(find.text('Yeni bölüm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yürü'))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
