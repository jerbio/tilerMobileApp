import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

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
    // return ThemeData.from(
    //
    //   colorScheme: ColorScheme.fromSeed(seedColor: TileStyles.primaryColor),
    // );
    return ThemeData(
      useMaterial3:true,
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        // onSurface: Colors.yellow,
        // surface: Colors.brown
      ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 57.0,
            height: 1.1,
          ),

          displayMedium: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 45.0,
            height: 1.2,
          ),

          displaySmall: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 36.0,
            height: 1.2,
          ),

          headlineLarge: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 32.0,
            height: 1.3,
          ),

          headlineMedium: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 28.0,
            height: 1.3,
          ),

          headlineSmall: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 24.0,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            color: Colors.yellow,
            fontSize: 22.0,
            height: 1.3,
          ),

          titleMedium: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 16.0,
            height: 1.5,
          ),

          titleSmall: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 14.0,
            height: 1.4,
          ),

          bodyLarge: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 16.0,
            height: 1.5,
          ),

          bodyMedium: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 14.0,
            height: 1.4,
          ),

          bodySmall: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 12.0,
            height: 1.3,
          ),

          labelLarge: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 14.0,
            height: 1.4,
          ),

          labelMedium: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 12.0,
            height: 1.3,
          ),

          labelSmall: TextStyle(
            color: Color(0xff1d1b20),
            fontSize: 11.0,
            height: 1.4,
          ),

        ),
      // colorScheme: ColorScheme.light(
      //   primary: Color(0xFFFFEB3B),        // Primary color
      //   primaryContainer: Color(0xFF62001E),// A darker version of primary
      //   secondary: Color(0xFF03DAC6),      // Secondary (accent) color
      //   secondaryContainer: Color(0xFF018786),// A darker version of
      // )
      // primaryColor:Color(0xFFFFEB3B),
      // visualDensity: VisualDensity.adaptivePlatformDensity,
      // fontFamily: TileStyles.rubikFontName,
      // colorScheme: ColorScheme.light(
      //   primary: Color(0xFFFFEB3B),
      //   secondary: Colors.brown,  // This controls the FAB color
      // ),
      //primarySwatch: MaterialColor(0xFFFFEB3B, TileStyles.themeMaterialColor),

      // scaffoldBackgroundColor: Colors.white,
      // cardColor: Colors.white,
      // dividerColor: Colors.grey.shade300,
      // floatingActionButtonTheme: FloatingActionButtonThemeData(
      //   backgroundColor: TileStyles.primaryContrastColor,
      //   foregroundColor: TileStyles.primaryColor,
      // ),
      // appBarTheme: AppBarTheme(
      //   backgroundColor: Colors.white,
      // ),
      // bottomNavigationBarTheme: TileStyles.bottomNavTheme,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: TileTextStyles.rubikFontName,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primarySwatch: MaterialColor(0xEF3054, TileColors.themeMaterialColor),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF121212),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: TileColors.primaryColor,
      ),
      bottomNavigationBarTheme: TileStyles.bottomNavTheme,
    );
  }
}