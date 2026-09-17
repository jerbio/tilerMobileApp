import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingSharedPreferencesHelper {
  static const String skipOnboardingKey = 'skipOnboarding';

  /// Local flag set when the essentials onboarding submit succeeds (or is
  /// skipped), for the local-only launch gate (design section 3.5).
  static const String essentialsOnboardingDoneKey =
      'essentialsOnboardingDone';

  static Future<void> setSkipOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skipOnboardingKey, value);
  }

  static Future<bool> getSkipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(skipOnboardingKey) ?? false;
  }

  static Future<void> setEssentialsOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(essentialsOnboardingDoneKey, value);
  }

  static Future<bool> getEssentialsOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(essentialsOnboardingDoneKey) ?? false;
  }
}
