import 'dart:convert';
import 'package:flutter/services.dart';

class GuestChoice {
  final String label;
  final String next;
  const GuestChoice(this.label, this.next);
}

class GuestChapter {
  final String text;
  final List<GuestChoice> choices;
  const GuestChapter(this.text, this.choices);
}

/// Authored, deterministic stories. No credentials, network or AI dependency.
class GuestStory {
  final String title;
  final Map<String, GuestChapter> chapters;
  const GuestStory(this.title, this.chapters);
}

class GuestStoryRepository {
  Future<GuestStory> load(String theme, String language, String gender) async {
    final locale = language == 'tr' ? 'tr' : 'en';
    final catalog =
        jsonDecode(await rootBundle.loadString('assets/stories/$locale.json'))
            as Map<String, dynamic>;
    final data = catalog[theme] as Map<String, dynamic>?;
    if (data == null) throw const FormatException('Unknown guest story theme.');
    final name = gender == 'gender_female' ? 'Ada' : 'Arda';
    return GuestStory(data['title'] as String, {
      for (final entry in (data['nodes'] as Map<String, dynamic>).entries)
        entry.key: GuestChapter(
          (entry.value['text'] as String).replaceAll('{name}', name),
          [
            for (final choice in entry.value['choices'] as List)
              GuestChoice(choice['label'] as String, choice['next'] as String),
          ],
        ),
    });
  }
}
