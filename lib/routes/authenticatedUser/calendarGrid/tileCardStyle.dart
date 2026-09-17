import 'package:flutter/material.dart';

/// The day-grid tile card palette, derived from the tile's own color and
/// the active [ColorScheme]. Pure so the tint math is unit-testable.
///
/// The card is a pastel: the tile color tinted over `surface` (opaque, so
/// side-by-side overlap columns never see through each other), with the
/// full tile color kept for the leading accent bar and glyph. Text always
/// uses the theme's on-surface tokens for contrast regardless of the tile
/// color.
class TileCardStyle {
  /// Tint strength of the tile color over `surface` for the card body
  /// (light schemes).
  static const double tintAlpha = 0.18;

  /// Dark schemes need a stronger tint: 18% of a saturated color over a
  /// near-black surface reads as grey.
  static const double tintAlphaDark = 0.34;

  static double tintFor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? tintAlphaDark : tintAlpha;

  final Color background;
  final Color accent;
  final Color title;
  final Color subtitle;

  const TileCardStyle({
    required this.background,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  static TileCardStyle from(Color tileColor, ColorScheme scheme) {
    return TileCardStyle(
      background: Color.alphaBlend(
        tileColor.withValues(alpha: tintFor(scheme)),
        scheme.surface,
      ),
      accent: tileColor,
      title: scheme.onSurface,
      subtitle: scheme.onSurfaceVariant,
    );
  }

  /// "4:00 AM" + "5:00 AM" → "4:00 – 5:00 AM". When both formatted times
  /// end in the same non-numeric period token (AM/PM, a.m./p.m., …) the
  /// start's token is dropped; otherwise both strings are kept verbatim.
  static String compactTimeRange(String start, String end) {
    final startToken = _trailingToken(start);
    final endToken = _trailingToken(end);
    if (startToken != null && startToken == endToken) {
      final trimmedStart =
          start.substring(0, start.length - startToken.length).trimRight();
      return '$trimmedStart – $end';
    }
    return '$start – $end';
  }

  /// The last whitespace-separated token when it is not purely numeric
  /// (i.e. a period marker), else null.
  static String? _trailingToken(String formatted) {
    final idx = formatted.lastIndexOf(' ');
    if (idx < 0) return null;
    final token = formatted.substring(idx + 1);
    if (token.isEmpty || RegExp(r'^[0-9:]+$').hasMatch(token)) return null;
    return token;
  }
}
