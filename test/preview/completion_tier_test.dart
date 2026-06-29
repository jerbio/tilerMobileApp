import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/completion_tier.dart';

void main() {
  group('completionTier', () {
    test('pct 0 returns tier 0', () {
      expect(completionTier(0.0), CompletionTier.tier0);
    });

    test('pct 0.049 returns tier 0', () {
      expect(completionTier(0.049), CompletionTier.tier0);
    });

    test('pct 0.05 returns tier 1', () {
      expect(completionTier(0.05), CompletionTier.tier1);
    });

    test('pct 0.149 returns tier 1', () {
      expect(completionTier(0.149), CompletionTier.tier1);
    });

    test('pct 0.15 returns tier 2', () {
      expect(completionTier(0.15), CompletionTier.tier2);
    });

    test('pct 0.249 returns tier 2', () {
      expect(completionTier(0.249), CompletionTier.tier2);
    });

    test('pct 0.25 returns tier 3', () {
      expect(completionTier(0.25), CompletionTier.tier3);
    });

    test('pct 0.449 returns tier 3', () {
      expect(completionTier(0.449), CompletionTier.tier3);
    });

    test('pct 0.45 returns tier 4', () {
      expect(completionTier(0.45), CompletionTier.tier4);
    });

    test('pct 1.0 returns tier 4', () {
      expect(completionTier(1.0), CompletionTier.tier4);
    });

    test('negative pct clamps to tier 0', () {
      expect(completionTier(-0.5), CompletionTier.tier0);
    });

    test('pct above 1 clamps to tier 4', () {
      expect(completionTier(1.5), CompletionTier.tier4);
    });
  });
}
