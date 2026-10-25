import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/repositories/guest_story_repository.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Any accidental AI repository access fails, without requiring API credentials.
class _NoAI extends Fake implements StoryRepository {}

const _themes = [
  'theme_adventure',
  'theme_fantasy',
  'theme_mystery',
  'theme_scifi',
  'theme_horror',
  'theme_romantic',
  'theme_historical',
  'theme_comedy',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in ['tr', 'en']) {
    for (final gender in ['gender_female', 'gender_male']) {
      test(
        'every $language/$gender guest path ends after five choices',
        () async {
          final repository = GuestStoryRepository();
          for (final theme in _themes) {
            final story = await repository.load(theme, language, gender);
            final reached = <String>{};
            var endings = 0;
            void visit(
              String id,
              List<String> path,
              Set<String> labels,
              Set<String> texts,
            ) {
              expect(
                path,
                isNot(contains(id)),
                reason: '$theme contains a cycle',
              );
              expect(
                story.chapters,
                contains(id),
                reason: '$theme has a broken link',
              );
              reached.add(id);
              final chapter = story.chapters[id]!;
              expect(chapter.text.trim(), isNotEmpty);
              expect(chapter.text, isNot(contains('{name}')));
              expect(
                chapter.text,
                isNot(contains(gender == 'gender_female' ? 'Arda' : 'Ada')),
              );
              expect(
                texts,
                isNot(contains(chapter.text)),
                reason: '$theme repeats a passage',
              );
              if (chapter.choices.isEmpty) {
                endings++;
                expect(
                  path.length,
                  5,
                  reason: '$theme ends at the wrong depth',
                );
                return;
              }
              expect(chapter.choices.length, inInclusiveRange(2, 3));
              final currentLabels = chapter.choices.map((c) => c.label).toSet();
              expect(currentLabels.length, chapter.choices.length);
              for (final choice in chapter.choices) {
                expect(choice.label.trim(), isNotEmpty);
                expect(
                  labels,
                  isNot(contains(choice.label)),
                  reason: '$theme repeats a choice',
                );
                visit(choice.next, [...path, id], {...labels, choice.label}, {
                  ...texts,
                  chapter.text,
                });
              }
            }

            visit('start', [], {}, {});
            expect(reached, story.chapters.keys.toSet());
            expect(endings, greaterThan(1));
          }
        },
      );
    }

    test('guest completes five $language continuations without AI', () async {
      await SharedPreferences.getInstance().then(
        (p) => p.setString('languageCode', language),
      );
      final cubit = StoryCubit(
        storyRepository: _NoAI(),
        languageCode: language,
      );
      addTearDown(cubit.close);
      await cubit.startNewStory(
        theme: 'theme_adventure',
        gender: 'gender_female',
      );
      for (var step = 0; step < 5; step++) {
        final loaded = cubit.state as StoryLoaded;
        expect(loaded.isGuest, isTrue);
        expect(loaded.storyText.length, step + 1);
        expect(loaded.isComplete, isFalse);
        await cubit.continueStory(
          loaded.choices[step % loaded.choices.length],
          loaded.storyText,
        );
      }
      final ending = cubit.state as StoryLoaded;
      expect(ending.isGuest, isTrue);
      expect(ending.isComplete, isTrue);
      expect(ending.storyText.length, 6);
    });
  }

  test(
    'both languages have the same themes, chapters, and choice destinations',
    () async {
      final tr =
          jsonDecode(await rootBundle.loadString('assets/stories/tr.json'))
              as Map;
      final en =
          jsonDecode(await rootBundle.loadString('assets/stories/en.json'))
              as Map;
      expect(tr.keys.toSet(), _themes.toSet());
      expect(en.keys.toSet(), _themes.toSet());
      for (final theme in _themes) {
        final trNodes = tr[theme]['nodes'] as Map;
        final enNodes = en[theme]['nodes'] as Map;
        expect(trNodes.keys.toSet(), enNodes.keys.toSet());
        for (final node in trNodes.keys) {
          expect(
            (trNodes[node]['choices'] as List).map((c) => c['next']).toList(),
            (enNodes[node]['choices'] as List).map((c) => c['next']).toList(),
          );
        }
      }
    },
  );
}
