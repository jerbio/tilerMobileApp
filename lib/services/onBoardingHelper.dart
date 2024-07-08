import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingSharedPreferencesHelper {
  static const String skipOnboardingKey = 'skipOnboarding';

  static Future<void> setSkipOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skipOnboardingKey, value);
  }

  static Future<bool> getSkipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(skipOnboardingKey) ?? false;
  }
}
