import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// A brief colour cue on something a schedule change touched. Shown only in
/// the Detailed "Schedule updates" mode, then fades back to normal.
enum ChangeFlash {
  /// A tile Tiler moved (the theme's accent, kept apart from the brand red
  /// so it never reads as a problem).
  moved,

  /// Free time the change opened up.
  freeGained,

  /// A travel time that changed, shown before the tiles it pushed move.
  travel,

  /// A tile that now clashes: it overlaps a tile it did not before, or it
  /// became late.
  conflict,
}

extension ChangeFlashStyle on ChangeFlash {
  /// How long the colour holds before fading. Cues only play in the
  /// Detailed "Schedule updates" mode (Minimal and Off have none), so this
  /// only ever affects Detailed.
  static const Duration hold = Duration(milliseconds: 1000);

  /// How long it takes to fade in or out.
  static const Duration fade = Duration(milliseconds: 300);

  Color color(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    switch (this) {
      case ChangeFlash.moved:
        // The accent is too dark to show on the dark theme; its lighter
        // container shade is used there.
        return dark ? scheme.tertiaryContainer : scheme.tertiary;
      case ChangeFlash.freeGained:
        return dark ? const Color(0xFF3CC28C) : const Color(0xFF1C9466);
      case ChangeFlash.travel:
        return dark ? const Color(0xFFF0A92A) : const Color(0xFFC98200);
      case ChangeFlash.conflict:
        return dark ? const Color(0xFFFF6B6B) : TileColors.late;
    }
  }
}
