import 'package:flutter/material.dart';
import 'tile_colors.dart';

class TileDatePickerTheme {
  TileDatePickerTheme._();

  static DatePickerThemeData datePickerThemeData = DatePickerThemeData(
    inputDecorationTheme: const InputDecorationTheme().copyWith(
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: TileColors.tertiary),
      ),
    ),
  );
}