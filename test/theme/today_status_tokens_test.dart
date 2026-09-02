// today_status_tokens_test.dart
//
// Phase 2 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// The point of these tests is that the screen does NOT introduce a second
// visual scheme: every color role must resolve to a color the app's existing
// theme already defines, so opening the summary page can't shift the palette.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

void main() {
  group('tokens derive from the existing app theme', () {
    test('light roles map onto the app light theme, not a new palette', () {
      final ThemeData theme = TileThemeData.lightTheme;
      final tokens = TodayStatusTokens.from(theme);
      final TileThemeExtension tile = theme.extension<TileThemeExtension>()!;

      expect(tokens.background, theme.colorScheme.surface);
      expect(tokens.surface, theme.colorScheme.surfaceContainerLowest);
      expect(tokens.surfaceSubtle, theme.colorScheme.surfaceContainerLow);
      expect(tokens.textPrimary, theme.colorScheme.onSurface);
      expect(tokens.textSecondary, tile.onSurfaceSecondary);
      expect(tokens.border, theme.colorScheme.outlineVariant);
      expect(tokens.brand, theme.colorScheme.primary);
      expect(tokens.success, tile.statusSuccess);
      expect(tokens.attention, tile.statusAttention);
      expect(tokens.danger, tile.statusDanger);
      expect(tokens.successTint, tile.notificationOverlaySuccess);
      expect(tokens.attentionTint, tile.notificationOverlayWarning);
      expect(tokens.dangerTint, tile.notificationOverlayError);
    });

    test('dark roles map onto the app dark theme', () {
      final ThemeData theme = TileThemeData.darkTheme;
      final tokens = TodayStatusTokens.from(theme);
      final TileThemeExtension tile = theme.extension<TileThemeExtension>()!;

      expect(tokens.background, theme.colorScheme.surface);
      expect(tokens.surface, theme.colorScheme.surfaceContainerLowest);
      expect(tokens.textPrimary, theme.colorScheme.onSurface);
      expect(tokens.successTint, tile.notificationOverlaySuccess);
      expect(tokens.success, tile.statusSuccess);
    });

    test('brand accents reuse the product pink rather than a spec hex', () {
      expect(TodayStatusTokens.from(TileThemeData.lightTheme).brand,
          TileThemeData.lightTheme.colorScheme.primary);
      expect(TodayStatusTokens.from(TileThemeData.darkTheme).brand,
          TileThemeData.darkTheme.colorScheme.primary);
    });

    test('light and dark still resolve to different surfaces', () {
      final light = TodayStatusTokens.from(TileThemeData.lightTheme);
      final dark = TodayStatusTokens.from(TileThemeData.darkTheme);

      expect(light.surface, isNot(dark.surface));
      expect(light.textPrimary, isNot(dark.textPrimary));
      expect(light.success, isNot(dark.success));
    });

    testWidgets('resolves from the ambient theme via of()', (tester) async {
      late TodayStatusTokens resolved;
      await tester.pumpWidget(MaterialApp(
        home: Theme(
          data: TileThemeData.darkTheme,
          child: Builder(builder: (context) {
            resolved = TodayStatusTokens.of(context);
            return const SizedBox.shrink();
          }),
        ),
      ));

      expect(resolved.surface,
          TileThemeData.darkTheme.colorScheme.surfaceContainerLowest);
    });

    test('falls back to the matching TileThemeExtension when absent', () {
      final tokens = TodayStatusTokens.from(ThemeData());

      expect(tokens.textSecondary, TileThemeExtension.light.onSurfaceSecondary);
    });
  });

  group('layout tokens', () {
    test('spacing follows the 4px grid (§3.1)', () {
      for (final double value in [
        TodayStatusTokens.space1,
        TodayStatusTokens.space2,
        TodayStatusTokens.space3,
        TodayStatusTokens.space4,
        TodayStatusTokens.space5,
        TodayStatusTokens.space6,
      ]) {
        expect(value % 4, 0, reason: '$value must resolve to a 4px increment');
      }
    });

    test('touch targets and CTA meet the §3.1 / §4.1 minimums', () {
      expect(TodayStatusTokens.minTouchTarget, greaterThanOrEqualTo(44));
      expect(TodayStatusTokens.ctaHeight, 56);
      expect(TodayStatusTokens.rowMinHeight, greaterThanOrEqualTo(56));
    });

    test('page padding widens with viewport width (§11)', () {
      expect(TodayStatusTokens.pagePaddingFor(320), TodayStatusTokens.space3);
      expect(TodayStatusTokens.pagePaddingFor(390), TodayStatusTokens.space4);
      expect(TodayStatusTokens.pagePaddingFor(440), TodayStatusTokens.space5);
    });
  });
}
