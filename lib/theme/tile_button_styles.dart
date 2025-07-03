import 'package:flutter/material.dart';


class TileButtonStyles {
  TileButtonStyles._();

  static ButtonStyle disabled({
    required Color backgroundColor,
    required Color foregroundColor,
  }) => ButtonStyle(
    backgroundColor: WidgetStateProperty.all(backgroundColor),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
  );

  static ButtonStyle selected({
    required Color backgroundColor,
    required Color foregroundColor,
  }) => ButtonStyle(
    backgroundColor: WidgetStateProperty.all(backgroundColor),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
    elevation: WidgetStateProperty.all(0),
  );

  static ButtonStyle suggested({
    required Color foregroundColor,
  }) => ButtonStyle(
    backgroundColor: WidgetStateProperty.all( Colors.transparent),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all( EdgeInsets.all(30),
    ),
  );

  static ButtonStyle enabled({
    required Color borderColor,
    required Color foregroundColor,
  }) => ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: borderColor)),
    shadowColor: WidgetStateProperty.all(Colors.transparent),
    elevation: WidgetStateProperty.all( 0),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
  );

  //eyad check if used or not
  static ButtonStyle toggled({
    required Color borderColor,
    required Color selectedBackgroundColor,
    required Color selectedForegroundColor,
    required Color unselectedForegroundColor,
    required Color selectedIconColor,
    required Color unselectedIconColor,
    required Color overlayColor,
  }) => ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: borderColor)),
    shadowColor: WidgetStateProperty.all(Colors.transparent,),
    elevation: WidgetStateProperty.all( 0),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == WidgetState.selected)) {
        return selectedBackgroundColor;
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == WidgetState.selected)) {
        return selectedForegroundColor;
      }
      return unselectedForegroundColor;
    }),
    overlayColor: WidgetStateProperty.all(overlayColor),
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == WidgetState.selected)) {
        return selectedIconColor;
      }
      return unselectedIconColor;
    }),
  );

  static ButtonStyle stripped ()=> ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent,),
    elevation: WidgetStateProperty.all( 0),
    padding: WidgetStateProperty.all(EdgeInsets.zero),
    shadowColor: WidgetStateProperty.all(Colors.transparent,),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
    foregroundColor: WidgetStateProperty.all(Colors.transparent),
  );

  //eyad check if used or not
  static ButtonStyle onlyIcons({
    required Color foregroundColor, // Default: TileColors.primaryColor
  }) => ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent,),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all(EdgeInsets.zero),
    shadowColor: WidgetStateProperty.all(Colors.transparent,),
    backgroundColor: WidgetStateProperty.all(Colors.transparent,),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
  );

  static ButtonStyle onlyIconsContrast({
    required Color foregroundColor,
  }) => ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent,),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all(EdgeInsets.zero),
    shadowColor: WidgetStateProperty.all(Colors.transparent,),
    backgroundColor: WidgetStateProperty.all(Colors.transparent,),
    foregroundColor: WidgetStateProperty.all(foregroundColor),
  );
}
