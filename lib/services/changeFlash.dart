import 'package:flutter/material.dart';

/// A brief colour cue on something a schedule change touched. Shown only in
/// the Detailed "Schedule updates" mode, then fades back to normal.
enum ChangeFlash {
  /// A tile Tiler moved (the app's accent).
  moved,

  /// Free time the change opened up.
  freeGained,

  /// A travel time that changed, shown before the tiles it pushed move.
  travel,
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
        return scheme.primary;
      case ChangeFlash.freeGained:
        return dark ? const Color(0xFF3CC28C) : const Color(0xFF1C9466);
      case ChangeFlash.travel:
        return dark ? const Color(0xFFF0A92A) : const Color(0xFFC98200);
    }
  }
}
