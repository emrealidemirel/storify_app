import 'package:flutter_story_app/services/content_safety_service.dart';
import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/models/story_model.dart';
import 'package:flutter_story_app/services/story_prompts.dart';

class StoryRepository {
  final bool Function() canUseAI;
  final Future<String?> Function(ChatCompleteText request)? requestCompletion;
  final Future<bool> Function(String input)? checkSafety;
  StoryRepository({
    bool Function()? canUseAI,
    this.requestCompletion,
    this.checkSafety,
  }) : canUseAI = canUseAI ?? (() => false);

  void _requireAccount() {
    if (!canUseAI()) throw StateError('Registered account required.');
  }

  String get token {
    final configuredToken = dotenv.env['GPT_TOKEN']?.trim() ?? '';
    return configuredToken.isNotEmpty
        ? configuredToken
        : dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
  }

  bool get isConfigured => token.trim().isNotEmpty;

  Future<Story?> startNewStory(
    String storyTheme,
    String gender,
    String languageCode,
  ) => _generate(
    StoryPrompts.messages(
      theme: storyTheme,
      gender: gender,
      languageCode: languageCode,
    ),
  );

  Future<Story?> continueStory(
    String storySoFar,
    String choice,
    String storyTheme,
    String gender,
    String languageCode, {
    List<String> previousChoices = const [],
  }) => _generate(
    StoryPrompts.messages(
      theme: storyTheme,
      gender: gender,
      languageCode: languageCode,
      storySoFar: storySoFar,
      selectedChoice: choice,
      previousChoices: previousChoices,
    ),
    previousChoices: previousChoices,
    storySoFar: storySoFar,
  );

  static String _normalize(String text) =>
      text
          .replaceAll('İ', 'i')
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
          .trim();

  Future<Story?> _generate(
    List<Map<String, dynamic>> messages, {
    List<String> previousChoices = const [],
    String storySoFar = '',
  }) async {
    if (storySoFar.length > 90000 || previousChoices.length > 120) {
      throw const FormatException('Story context exceeds the session limit.');
    }
    final oldChoices = previousChoices.map(_normalize).toSet();
    for (var attempt = 0; attempt < 2; attempt++) {
      _requireAccount();
      if (!isConfigured) throw StateError('Missing GPT_TOKEN configuration.');
      final request = ChatCompleteText(
        messages: messages,
        maxToken: 300,
        model: ChatModelFromValue(model: 'gpt-4o-mini'),
        responseFormat: ResponseFormat.jsonObject,
      );
      final String? content;
      if (requestCompletion != null) {
        content = await requestCompletion!(request);
      } else {
        final openAI = OpenAI.instance.build(
          token: token,
          baseOption: HttpSetup(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
          enableLog: false,
        );
        final response = await openAI.onChatCompletion(request: request);
        content =
            response == null || response.choices.isEmpty
                ? null
                : response.choices.first.message?.content;
      }
      final story = _parseResponse(content);
      if (story == null) return null;
      final choices = story.choices.map(_normalize).toList();
      final repeatedChoices =
          choices.toSet().length != 3 || choices.any(oldChoices.contains);
      final repeatedText =
          storySoFar.isNotEmpty &&
          _normalize(storySoFar).contains(_normalize(story.text));
      if (!repeatedChoices && !repeatedText) {
        final text = [story.text, ...story.choices].join('\n');
        final safe =
            await (checkSafety?.call(text) ??
                const ContentSafetyService().isSafe(text, token));
        if (!safe) throw const UnsafeStoryException();
        return story;
      }
      messages = [
        ...messages,
        {'role': 'assistant', 'content': content},
        {
          'role': 'user',
          'content': jsonEncode({
            'task': 'revise',
            'repeated_choices': repeatedChoices,
            'repeated_passage': repeatedText,
          }),
        },
      ];
    }
    throw const FormatException(
      'The story response repeated existing content.',
    );
  }

  Story? _parseResponse(String? content) {
    if (content == null || content.trim().isEmpty) return null;

    final trimmed = content.trim();
    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd < jsonStart) {
      throw const FormatException('The story response was not valid JSON.');
    }
    return storyFromJson(trimmed.substring(jsonStart, jsonEnd + 1));
  }
}
