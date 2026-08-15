/// Decision logic for the iOS AI data-sharing consent gate that runs when the
/// user taps the Tiler AI chat button.
///
/// The dependencies are injected so the flow can be unit-tested without a
/// platform, storage, or navigator. In production they are wired to
/// `Platform.isIOS`, [AiConsentPreferencesHelper], the consent sheet, and
/// navigation respectively.
///
/// Behaviour:
///   - non-iOS            -> [onProceed], never prompt
///   - iOS + has consent  -> [onProceed], never prompt
///   - iOS + no consent   -> [requestConsent]; if accepted, [persistConsent]
///                           then [onProceed]; if dismissed, do nothing
///
/// See docs/ios-ai-consent-plan.md.
Future<void> runAiChatConsentGate({
  required bool Function() isIOS,
  required Future<bool> Function() hasConsent,
  required Future<bool> Function() requestConsent,
  required Future<void> Function() persistConsent,
  required void Function() onProceed,
}) async {
  if (!isIOS()) {
    onProceed();
    return;
  }

  if (await hasConsent()) {
    onProceed();
    return;
  }

  final granted = await requestConsent();
  if (!granted) {
    return;
  }

  await persistConsent();
  onProceed();
}
