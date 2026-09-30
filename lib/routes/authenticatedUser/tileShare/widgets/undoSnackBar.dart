import 'package:flutter/material.dart';

/// The colour of an "Undo" action on a snack bar. The framework default is a
/// muted colour that makes a working button look disabled, so use the brand
/// colour where it is legible on the bar (the dark theme's light bar) and the
/// theme's own readable "on inverse" colour where it is not (the light theme's
/// translucent-black bar). Legible means a contrast of at least 3:1 — the bar's
/// colour is blended over the page it sits on.
Color tileShareUndoColor(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final Color bar = Color.alphaBlend(
      theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
      theme.scaffoldBackgroundColor);
  final Color brand = theme.colorScheme.primary;
  return _contrast(brand, bar) >= 3.0
      ? brand
      : theme.colorScheme.onInverseSurface;
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance(), lb = b.computeLuminance();
  final double hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Replaces any snack bar with [message] and an Undo action. `persist: false`
/// so a bar with an action still times out. Takes the messenger and colour
/// already resolved, so a caller can look them up before an `await`.
void showTileShareUndoSnackBar(
  ScaffoldMessengerState messenger,
  Color undoColor, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration? duration,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      persist: false,
      duration: duration ?? const Duration(seconds: 4),
      content: Text(message),
      action: SnackBarAction(
        textColor: undoColor,
        label: undoLabel,
        onPressed: onUndo,
      ),
    ));
}
