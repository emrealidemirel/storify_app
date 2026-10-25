import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
// The SDK exposes exceptions but not their error payload constructors.
// ignore: implementation_imports
import 'package:chat_gpt_sdk/src/model/error/openai_error.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/models/story_model.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingRepository extends StoryRepository {
  FailingRepository(this.failure);
  final Object failure;

  @override
  Future<Story?> startNewStory(
    String theme,
    String gender,
    String language,
  ) async {
    throw failure;
  }

  @override
  Future<Story?> continueStory(
    String history,
    String choice,
    String theme,
    String gender,
    String language, {
    List<String> previousChoices = const [],
  }) async {
    throw failure;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    dotenv.loadFromString(envString: 'GPT_TOKEN=test-only');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(dotenv.clean);

  for (final continuing in [false, true]) {
    test(
      'quota blocks retry, preserves history, continuation=$continuing',
      () async {
        final failure = OpenAIRateLimitError(
          code: 429,
          data: OpenAIError.fromJson({
            'error': {
              'type': 'insufficient_quota',
              'code': 'new_billing_code',
              'message': 'sensitive-provider-details',
            },
          }, 'sensitive-provider-details'),
        );
        final cubit = StoryCubit(
          storyRepository: FailingRepository(failure),
          languageCode: 'en',
          aiUserId: () => 'test-user',
        );
        cubit.stories = ['Existing story'];
        final result = cubit.stream.firstWhere((state) => state is StoryError);
        if (continuing) {
          cubit.continueStory('Next', ['Existing story']);
        } else {
          cubit.startNewStory();
        }
        final state = await result as StoryError;
        expect(state.canRetry, isFalse);
        expect(state.errorMessage, 'story_quota_error');
        expect(
          state.errorMessage,
          isNot(contains('sensitive-provider-details')),
        );
        expect(cubit.stories, ['Existing story']);
        await cubit.close();
      },
    );
  }

  test('temporary rate limit allows retry', () async {
    final cubit = StoryCubit(
      storyRepository: FailingRepository(OpenAIRateLimitError(code: 429)),
      languageCode: 'en',
      aiUserId: () => 'test-user',
    );
    final result = cubit.stream.firstWhere((state) => state is StoryError);
    cubit.startNewStory();
    final state = await result as StoryError;
    expect(state.canRetry, isTrue);
    expect(state.errorMessage, 'story_rate_limit_error');
    await cubit.close();
  });
}
