// ai_consent_gate_test.dart
//
// TDD stage 4 for the iOS AI data-sharing consent gate.
// The FAB tap delegates to [runAiChatConsentGate], whose decision logic is:
//   - non-iOS            -> proceed straight to chat, never prompt
//   - iOS + has consent  -> proceed straight to chat, never prompt
//   - iOS + no consent   -> prompt; on accept persist + proceed; on dismiss no-op
//
// See docs/ios-ai-consent-plan.md and docs/ios-ai-consent-tracker.md.

import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/services/aiChatConsentGate.dart';

void main() {
  group('runAiChatConsentGate', () {
    test('non-iOS proceeds without prompting or persisting', () async {
      var requested = false;
      var persisted = false;
      var proceeded = false;

      await runAiChatConsentGate(
        isIOS: () => false,
        hasConsent: () async => false,
        requestConsent: () async {
          requested = true;
          return false;
        },
        persistConsent: () async => persisted = true,
        onProceed: () => proceeded = true,
      );

      expect(proceeded, isTrue);
      expect(requested, isFalse);
      expect(persisted, isFalse);
    });

    test('iOS with existing consent proceeds without prompting', () async {
      var requested = false;
      var proceeded = false;

      await runAiChatConsentGate(
        isIOS: () => true,
        hasConsent: () async => true,
        requestConsent: () async {
          requested = true;
          return false;
        },
        persistConsent: () async {},
        onProceed: () => proceeded = true,
      );

      expect(proceeded, isTrue);
      expect(requested, isFalse);
    });

    test('iOS without consent, accepted, persists and proceeds', () async {
      var persisted = false;
      var proceeded = false;

      await runAiChatConsentGate(
        isIOS: () => true,
        hasConsent: () async => false,
        requestConsent: () async => true,
        persistConsent: () async => persisted = true,
        onProceed: () => proceeded = true,
      );

      expect(persisted, isTrue);
      expect(proceeded, isTrue);
    });

    test('iOS without consent, dismissed, does not persist or proceed',
        () async {
      var persisted = false;
      var proceeded = false;

      await runAiChatConsentGate(
        isIOS: () => true,
        hasConsent: () async => false,
        requestConsent: () async => false,
        persistConsent: () async => persisted = true,
        onProceed: () => proceeded = true,
      );

      expect(persisted, isFalse);
      expect(proceeded, isFalse);
    });
  });
}
