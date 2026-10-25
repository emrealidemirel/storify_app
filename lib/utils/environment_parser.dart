import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supports the existing JSON configuration and standard dotenv files.
class EnvironmentParser extends Parser {
  const EnvironmentParser();

  @override
  Map<String, String> parse(Iterable<String> lines) {
    final source = lines.join('\n').trim();
    final Map<String, String> values;

    if (source.startsWith('{')) {
      dynamic decoded;
      try {
        decoded = jsonDecode(source);
      } on FormatException {
        // Never include configuration contents in exception messages.
        throw const FormatException('Invalid JSON environment configuration.');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Environment configuration must be an object.',
        );
      }
      values = {
        for (final entry in decoded.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } else {
      values = super.parse(source.split('\n'));
    }

    final token = values['GPT_TOKEN']?.trim() ?? '';
    final apiKey = values['OPENAI_API_KEY']?.trim() ?? '';
    values['GPT_TOKEN'] = token.isNotEmpty ? token : apiKey;
    return values;
  }
}
