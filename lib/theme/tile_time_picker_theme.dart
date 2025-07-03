import 'package:flutter/material.dart';
import 'tile_colors.dart';

class TileTimePickerTheme {
  TileTimePickerTheme._();

  static  TimePickerThemeData  lightTheme = TimePickerThemeData(
    dayPeriodColor: TileColors.primaryContainerLight.toColor(),
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TileColors.onPrimaryContainerLight;
      }
      return TileColors.darkContent;
    }),
  );

  static TimePickerThemeData  darkTheme = TimePickerThemeData(
    dayPeriodColor: TileColors.primaryContainerDark.toColor(),
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TileColors.onPrimaryContainerDark;
      }
      return TileColors.darkContent;
    }),
  );
}