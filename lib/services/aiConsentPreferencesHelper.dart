import 'package:shared_preferences/shared_preferences.dart';

/// Manages the iOS AI data-sharing consent flag via [SharedPreferences].
///
/// Consent is stored as a version number rather than a bare boolean so that,
/// if the disclosure wording changes, [currentConsentVersion] can be bumped to
/// force users to re-consent. Consent is considered granted only when the
/// stored version is at least [currentConsentVersion].
///
/// See docs/ios-ai-consent-plan.md.
class AiConsentPreferencesHelper {
  /// Storage key holding the consent version the user last agreed to.
  static const String consentVersionKey = 'aiConsentVersion';

  /// The consent version currently required to use Tiler AI. Bump this when the
  /// disclosure text changes to re-prompt previously consenting users.
  static const int currentConsentVersion = 1;

  /// Returns true when the user has granted consent for the current version.
  static Future<bool> hasGrantedAiConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(consentVersionKey) ?? 0;
    return storedVersion >= currentConsentVersion;
  }

  /// Persists that the user granted consent for [currentConsentVersion].
  static Future<void> setAiConsentGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(consentVersionKey, currentConsentVersion);
  }
}
