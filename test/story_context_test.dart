import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/models/story_model.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends StoryRepository {
  final contexts = <List<String>>[];
  int chapter = 0;
  bool failNext = false;

  Story _next() {
    chapter++;
    return Story(
      text: 'Chapter $chapter',
      choices: ['Action $chapter A', 'Action $chapter B', 'Action $chapter C'],
    );
  }

  @override
  Future<Story?> startNewStory(
    String theme,
    String gender,
    String language,
  ) async => _next();

  @override
  Future<Story?> continueStory(
    String history,
    String choice,
    String theme,
    String gender,
    String language, {
    List<String> previousChoices = const [],
  }) async {
    contexts.add(List.of(previousChoices));
    if (failNext) {
      failNext = false;
      throw const FormatException('Invalid response');
    }
    return _next();
  }
}

StoryCubit _cubit(_Repository repository) => StoryCubit(
  storyRepository: repository,
  languageCode: 'en',
  aiUserId: () => 'test-user',
);

Future<void> _continue(StoryCubit cubit) async {
  final loaded = cubit.state as StoryLoaded;
  await cubit.continueStory(loaded.choices.first, loaded.storyText);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    dotenv.loadFromString(envString: 'GPT_TOKEN=test-only');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(dotenv.clean);

  test(
    'all offered choices survive saving and restoring; new stories reset them',
    () async {
      final repository = _Repository();
      final original = _cubit(repository);
      await original.startNewStory();
      final firstChoices = (original.state as StoryLoaded).choices;
      await _continue(original);
      final secondChoices = (original.state as StoryLoaded).choices;
      expect(repository.contexts.single, firstChoices);
      await original.close();

      final restored = _cubit(repository);
      addTearDown(restored.close);
      await restored.continueToLastStory();
      await _continue(restored);
      expect(repository.contexts.last, [...firstChoices, ...secondChoices]);

      await restored.startNewStory();
      final freshChoices = (restored.state as StoryLoaded).choices;
      await _continue(restored);
      expect(repository.contexts.last, freshChoices);
      await restored.resetStory();
      expect(await PreferencesService.getOfferedChoices(), isNull);
    },
  );

  test(
    'failed continuation does not lose the choice history on retry',
    () async {
      final repository = _Repository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.startNewStory();
      final loaded = cubit.state as StoryLoaded;
      repository.failNext = true;
      await _continue(cubit);
      expect(cubit.state, isA<StoryError>());
      await cubit.continueStory(loaded.choices.first, loaded.storyText);
      expect(repository.contexts, [loaded.choices, loaded.choices]);
    },
  );

  test(
    'older saved stories use their known choices as repetition context',
    () async {
      await PreferencesService.saveStoryOwner('test-user');
      await PreferencesService.saveLastStories(['Old saved chapter']);
      await PreferencesService.saveLastChoices([
        'Open door',
        'Read note',
        'Ask guard',
      ]);
      final repository = _Repository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.continueToLastStory();
      await _continue(cubit);
      expect(repository.contexts.single, [
        'Open door',
        'Read note',
        'Ask guard',
      ]);
    },
  );
}
