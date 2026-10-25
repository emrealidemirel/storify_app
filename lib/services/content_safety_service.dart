import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsafeStoryException implements Exception {
  const UnsafeStoryException();
}

/// Move alongside story generation to the authenticated backend before release.
class ContentSafetyService {
  final http.Client? client;
  const ContentSafetyService({this.client});

  Future<bool> isSafe(String input, String token) async {
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            Uri.https('api.openai.com', '/v1/moderations'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'omni-moderation-latest',
              'input': input,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const FormatException('Safety check unavailable.');
      }
      final body = jsonDecode(response.body);
      final results = body is Map<String, dynamic> ? body['results'] : null;
      if (results is! List ||
          results.isEmpty ||
          results.any(
            (result) => result is! Map || result['flagged'] is! bool,
          )) {
        throw const FormatException('Invalid safety response.');
      }
      return results.every((result) => result['flagged'] == false);
    } finally {
      if (client == null) transport.close();
    }
  }
}
