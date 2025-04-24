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
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: TileStyles.rubikFontName,
      primarySwatch: MaterialColor(0xEF3054, TileStyles.themeMaterialColor),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: TileStyles.primaryContrastColor,
        foregroundColor: TileStyles.primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: TileStyles.bottomNavTheme,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: TileStyles.rubikFontName,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primarySwatch: MaterialColor(0xEF3054, TileStyles.themeMaterialColor),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF121212),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: TileStyles.primaryColor,
      ),
      bottomNavigationBarTheme: TileStyles.bottomNavTheme,
    );
  }
}