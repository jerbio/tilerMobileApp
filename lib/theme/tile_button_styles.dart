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

  static ButtonStyle suggested() => ButtonStyle(
    backgroundColor: WidgetStateProperty.all( Colors.transparent),
    elevation: WidgetStateProperty.all(0),
    padding: WidgetStateProperty.all( EdgeInsets.all(30),
    ),
  );


  static ButtonStyle enabled({
    required Color borderColor,
  }) => ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: borderColor)),
    shadowColor: WidgetStateProperty.all(Colors.transparent),
    elevation: WidgetStateProperty.all( 0),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
  );

  static ButtonStyle stripped ()=> ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent,),
    elevation: WidgetStateProperty.all( 0),
    padding: WidgetStateProperty.all(EdgeInsets.zero),
    shadowColor: WidgetStateProperty.all(Colors.transparent,),
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
    foregroundColor: WidgetStateProperty.all(Colors.transparent),
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
