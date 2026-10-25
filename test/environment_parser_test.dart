import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/utils/environment_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = EnvironmentParser();
  tearDown(dotenv.clean);

  test('existing JSON API key is available to the story repository', () {
    dotenv.loadFromString(
      envString: '{"OPENAI_API_KEY": "local-test-token"}',
      parser: parser,
    );
    expect(StoryRepository().isConfigured, isTrue);
    expect(dotenv.env['GPT_TOKEN'], 'local-test-token');
  });

  test('dotenv format supports both key names and surrounding quotes', () {
    expect(
      parser.parse(['GPT_TOKEN="local-test-token"'])['GPT_TOKEN'],
      'local-test-token',
    );
    expect(
      parser.parse(['OPENAI_API_KEY=local-test-token'])['GPT_TOKEN'],
      'local-test-token',
    );
  });

  test('repository reads updated configuration instead of caching a token', () {
    dotenv.loadFromString(envString: 'GPT_TOKEN=old-test-token');
    final repository = StoryRepository();
    dotenv.loadFromString(envString: 'GPT_TOKEN="  new-test-token  "');
    expect(repository.token, 'new-test-token');
  });

  test('repository supports OPENAI_API_KEY without a custom parser', () {
    dotenv.loadFromString(envString: 'OPENAI_API_KEY="  test-token  "');
    final repository = StoryRepository();
    expect(repository.isConfigured, isTrue);
    expect(repository.token, 'test-token');
  });

  test('nonempty GPT_TOKEN takes precedence and empty values fall back', () {
    expect(
      parser.parse([
        'GPT_TOKEN=primary',
        'OPENAI_API_KEY=secondary',
      ])['GPT_TOKEN'],
      'primary',
    );
    expect(
      parser.parse(['GPT_TOKEN=', 'OPENAI_API_KEY=secondary'])['GPT_TOKEN'],
      'secondary',
    );
    expect(parser.parse(['GPT_TOKEN='])['GPT_TOKEN'], isEmpty);
  });

  test('invalid JSON errors do not expose configuration contents', () {
    expect(
      () => parser.parse(['{"OPENAI_API_KEY": "local-test-token"']),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('local-test-token')),
        ),
      ),
    );
  });
}
