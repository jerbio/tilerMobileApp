import 'package:flutter/material.dart';
import 'tile_colors.dart';

class TileInputTheme {
  TileInputTheme._();

  static  InputDecorationTheme  inputDecorationTheme =
      const InputDecorationTheme().copyWith(
        focusedBorder: const InputDecorationTheme().focusedBorder?.copyWith(
          borderSide: BorderSide(color: TileColors.tertiary),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: TileColors.tertiary);
          }
          return const TextStyle();
        }),
      );

  static  TextSelectionThemeData  textSelectionTheme =
      TextSelectionThemeData(
        selectionColor: TileColors.tertiary.withValues(alpha: 0.3),
        selectionHandleColor: TileColors.tertiary,
        cursorColor: TileColors.tertiary,
      );
}