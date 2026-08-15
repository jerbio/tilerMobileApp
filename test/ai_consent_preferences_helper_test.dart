// ai_consent_preferences_helper_test.dart
//
// TDD stage 1 for the iOS AI data-sharing consent gate.
// Locks in the local persistence contract used to decide whether the Tiler AI
// consent sheet must be shown before opening chat.
//
// See docs/ios-ai-consent-plan.md and docs/ios-ai-consent-tracker.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/services/aiConsentPreferencesHelper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConsentPreferencesHelper', () {
    test('defaults to not granted when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await AiConsentPreferencesHelper.hasGrantedAiConsent(), isFalse);
    });

    test('setAiConsentGranted persists so consent reads as granted', () async {
      SharedPreferences.setMockInitialValues({});

      await AiConsentPreferencesHelper.setAiConsentGranted();

      expect(await AiConsentPreferencesHelper.hasGrantedAiConsent(), isTrue);
    });

    test('a stored version below the current required version is not granted',
        () async {
      SharedPreferences.setMockInitialValues({
        AiConsentPreferencesHelper.consentVersionKey:
            AiConsentPreferencesHelper.currentConsentVersion - 1,
      });

      expect(await AiConsentPreferencesHelper.hasGrantedAiConsent(), isFalse);
    });

    test('a stored version at or above the current version is granted',
        () async {
      SharedPreferences.setMockInitialValues({
        AiConsentPreferencesHelper.consentVersionKey:
            AiConsentPreferencesHelper.currentConsentVersion,
      });

      expect(await AiConsentPreferencesHelper.hasGrantedAiConsent(), isTrue);
    });
  });
}
