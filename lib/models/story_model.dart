import 'dart:convert';

class StoryModel {
  final String text;
  final List<String> choices;

  StoryModel({required this.text, required this.choices});
}

Story storyFromJson(String str) => Story.fromJson(json.decode(str));

class Story {
  String text;
  List<String> choices;

  Story({required this.text, required this.choices});

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    text: json["text"],
    choices:
        json["choices"] == null
            ? []
            : List<String>.from(json["choices"]!.map((x) => x)),
  );
}