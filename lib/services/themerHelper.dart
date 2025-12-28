import 'package:shared_preferences/shared_preferences.dart';
class ThemeManager {
  static const String THEME_KEY = 'isDarkMode';

  static Future<bool> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_KEY) ?? false;
  }

  static Future<void> setThemeMode(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, isDarkMode);
  }



}