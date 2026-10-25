import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyLanguageCode = "languageCode";
  static const _keyLastStoryText = "lastStoryText";
  static const _keyLastStories = "lastStories";
  static const _keyLastChoices = "choices";
  static const _keyOfferedChoices = 'offeredChoices';
  static const _keyLastStoryTheme = "lastStoryTheme";
  static const _keyLastStoryGender = "lastStoryGender";

  static Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguageCode, code);
  }

  static Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguageCode);
  }

  static Future<void> saveLastStories(List<String> stories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLastStories, stories);
    if (stories.isNotEmpty) {
      await prefs.setString(_keyLastStoryText, stories.last);
    }
  }

  static Future<List<String>?> getLastStories() async {
    final prefs = await SharedPreferences.getInstance();
    final stories = prefs.getStringList(_keyLastStories);
    if (stories != null && stories.isNotEmpty) return stories;

    // Keep existing installs compatible with the previous single-part save.
    final lastStory = prefs.getString(_keyLastStoryText);
    return lastStory == null ? null : [lastStory];
  }

  static Future<void> saveLastStorySelection({
    required String theme,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastStoryTheme, theme);
    await prefs.setString(_keyLastStoryGender, gender);
  }

  static Future<String?> getLastStoryTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastStoryTheme);
  }

  static Future<String?> getLastStoryGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastStoryGender);
  }

  static Future<void> saveLastChoices(List<String> choices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLastChoices, choices);
  }

  static Future<List<String>?> getLastChoices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyLastChoices);
  }

  static Future<void> saveOfferedChoices(List<String> choices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyOfferedChoices, choices);
  }

  static Future<List<String>?> getOfferedChoices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyOfferedChoices);
  }

  static Future<void> saveStoryOwner(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storyOwner', uid);
  }

  static Future<String?> getStoryOwner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('storyOwner');
  }

  static Future<void> clearStoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('storyOwner');
    await prefs.remove(_keyLastStoryText);
    await prefs.remove(_keyLastStories);
    await prefs.remove(_keyLastChoices);
    await prefs.remove(_keyOfferedChoices);
    await prefs.remove(_keyLastStoryTheme);
    await prefs.remove(_keyLastStoryGender);
  }

  static Future<void> clearUserData() async {
    await clearStoryData();
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs
            .getKeys()
            .where((key) => key.startsWith('aiConsent:'))
            .toList()) {
      await prefs.remove(key);
    }
  }

  static Future<bool> hasAIConsent(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('aiConsent:v1:$uid') ?? false;
  }

  static Future<void> setAIConsent(String uid, bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiConsent:v1:$uid', accepted);
  }
}
