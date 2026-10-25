import 'dart:convert';

Story storyFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Story response must be a JSON object.');
  }
  return Story.fromJson(decoded);
}

class Story {
  final String text;
  final List<String> choices;

  Story({required this.text, required this.choices});

  factory Story.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    final choices = json['choices'];
    if (text is! String || text.trim().isEmpty || text.length > 3000) {
      throw const FormatException('Story text is missing.');
    }
    if (choices is! List ||
        choices.length != 3 ||
        choices.any(
          (choice) =>
              choice is! String || choice.trim().isEmpty || choice.length > 120,
        )) {
      throw const FormatException('Story must include three valid choices.');
    }
    return Story(
      text: text.trim(),
      choices: choices.cast<String>().map((choice) => choice.trim()).toList(),
    );
  }
}
