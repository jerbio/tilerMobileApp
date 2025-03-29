import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/styles.dart';

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

  static ThemeData getLightTheme() {
    return ThemeData(
      fontFamily: TileStyles.rubikFontName,
      brightness: Brightness.light,
      primarySwatch: MaterialColor(0xEF3054, TileStyles.themeMaterialColor),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      fontFamily: TileStyles.rubikFontName,
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(0xEF3054, TileStyles.themeMaterialColor),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}