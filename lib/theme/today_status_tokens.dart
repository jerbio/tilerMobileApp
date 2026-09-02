import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

/// Today Status screen tokens (spec §4), resolved from the app's shared theme.
///
/// This adds no colors of its own: every role maps onto an existing
/// `ColorScheme` or [TileThemeExtension] value, so the screen inherits the
/// product palette and picks up any central theme tuning automatically.
class TodayStatusTokens {
  const TodayStatusTokens._({
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.brand,
    required this.brandTint,
    required this.success,
    required this.successTint,
    required this.attention,
    required this.attentionTint,
    required this.danger,
    required this.dangerTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color brand;
  final Color brandTint;
  final Color success;
  final Color successTint;
  final Color attention;
  final Color attentionTint;
  final Color danger;
  final Color dangerTint;

  /// §4.4: card edges should read as a surface change, not a wireframe outline,
  /// so the semantic border is used at low opacity and paired with a soft
  /// shadow.
  Color get cardBorder => border.withValues(alpha: 0.45);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // §4.1 spacing (4px base / 8px rhythm)
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;

  // §4.1 radius
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // §4.1 sizes
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconWell = 36;

  /// Task rows use a smaller well so the title, not the status icon, carries
  /// the visual weight.
  static const double iconWellRow = 30;
  static const double iconRow = 17;
  static const double ctaHeight = 56;
  static const double rowMinHeight = 56;
  static const double minTouchTarget = 44;

  /// §3.1 page padding, widened on larger phones.
  static double pagePaddingFor(double width) {
    if (width < 360) return space3;
    if (width >= 430) return space5;
    return space4;
  }

  static TodayStatusTokens of(BuildContext context) => from(Theme.of(context));

  static TodayStatusTokens from(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    final TileThemeExtension tile = theme.extension<TileThemeExtension>() ??
        (theme.brightness == Brightness.dark
            ? TileThemeExtension.dark
            : TileThemeExtension.light);

    return TodayStatusTokens._(
      background: colors.surface,
      surface: colors.surfaceContainerLowest,
      surfaceSubtle: colors.surfaceContainerLow,
      textPrimary: colors.onSurface,
      textSecondary: tile.onSurfaceSecondary,
      border: colors.outlineVariant,
      brand: colors.primary,
      brandTint: tile.primaryContainerLow,
      success: tile.statusSuccess,
      successTint: tile.notificationOverlaySuccess,
      attention: tile.statusAttention,
      attentionTint: tile.notificationOverlayWarning,
      danger: tile.statusDanger,
      dangerTint: tile.notificationOverlayError,
    );
  }
}
