import 'package:shared_preferences/shared_preferences.dart';

/// Manages tutorial completion state via SharedPreferences.
class TutorialPreferencesHelper {
  static const String _hasCompletedTutorialKey = 'hasCompletedAppTutorial';

  /// Marks the tutorial as completed.
  static Future<void> setTutorialCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedTutorialKey, value);
  }

  /// Returns true if the user has already completed the tutorial.
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedTutorialKey) ?? false;
  }

  /// Resets tutorial state so it can be shown again.
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedTutorialKey, false);
  }
}
