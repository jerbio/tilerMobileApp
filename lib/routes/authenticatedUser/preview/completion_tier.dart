/// Discrete progress tier that drives the message under the sundial arc.
///
/// Thresholds (lower-bound inclusive):
///   tier0: < 5%
///   tier1: [5%, 15%)
///   tier2: [15%, 25%)
///   tier3: [25%, 45%)
///   tier4: >= 45%
enum CompletionTier { tier0, tier1, tier2, tier3, tier4 }

/// Buckets a 0..1 completion percentage into a [CompletionTier].
/// Values outside the [0, 1] range are clamped.
CompletionTier completionTier(double pct) {
  final clamped = pct.clamp(0.0, 1.0);
  if (clamped < 0.05) return CompletionTier.tier0;
  if (clamped < 0.15) return CompletionTier.tier1;
  if (clamped < 0.25) return CompletionTier.tier2;
  if (clamped < 0.45) return CompletionTier.tier3;
  return CompletionTier.tier4;
}
