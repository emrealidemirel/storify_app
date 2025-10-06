import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyLanguageCode = "languageCode";
  static const _keyLastStoryText = "lastStoryText";
  static const _keyLastChoices = "choices";
  static const _keyIsLoggedIn = "isLoggedIn";

  static Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguageCode, code);
  }

  static Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguageCode);
  }

  static Future<void> saveLastStoryText(String storyText) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastStoryText, storyText);
  }

  static Future<String?> getLastStoryText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastStoryText);
  }

  static Future<void> saveLastChoices(List<String> choices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLastChoices, choices);
  }

  static Future<List<String>?> getLastChoices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyLastChoices);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> clearStoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastStoryText);
    await prefs.remove(_keyLastChoices);
  }
}
