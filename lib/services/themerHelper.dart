import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/data/appThemeMode.dart';
class ThemeManager {
  static const String THEME_KEY = 'themeMode';

  static Future<AppThemeMode> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return fromString(prefs.getString(THEME_KEY) ?? 'system');
  }

  static Future<void> setThemeMode(AppThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME_KEY, mode.name);
  }

  static AppThemeMode fromString(String val) {
    switch (val) {
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
        return AppThemeMode.light;
      default:
        return AppThemeMode.system;
    }
  }

  static ThemeMode toFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}