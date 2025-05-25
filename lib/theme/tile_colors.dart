import 'package:flutter/material.dart';
class TileColors{
  const TileColors._();

  static const weirdprimaryColor=Color(0xFF880E4F);
  static Map<int, Color> themeMaterialColor = {
    50: Color.fromRGBO(239, 48, 84, .1),
    100: Color.fromRGBO(239, 48, 84, .2),
    200: Color.fromRGBO(239, 48, 84, .3),
    300: Color.fromRGBO(239, 48, 84, .4),
    400: Color.fromRGBO(239, 48, 84, .5),
    500: Color.fromRGBO(239, 48, 84, .6),
    600: Color.fromRGBO(239, 48, 84, .7),
    700: Color.fromRGBO(239, 48, 84, .8),
    800: Color.fromRGBO(239, 48, 84, .9),
    900: Color.fromRGBO(239, 48, 84, 1),
  };
  static const List<Color> randomDefaultHues = [
    Color.fromRGBO(239, 131, 84, 1),
    Color.fromRGBO(79, 93, 117, 1),
    Color.fromRGBO(239, 176, 167, 1),
    Color.fromRGBO(148, 168, 154, 1),
    Color.fromRGBO(23, 190, 187, 1),
    Color.fromRGBO(205, 83, 52, 1),
    Color.fromRGBO(237, 184, 139, 1),
    Color.fromRGBO(55, 114, 255, 1),
    Color.fromRGBO(85, 40, 111, 1),
    Color.fromRGBO(56, 174, 204, 1),
    Color.fromRGBO(102, 195, 84, 1)
  ];

  static const List<Color> chartHues = [
    Color.fromRGBO(239, 131, 84, 1),
    Color.fromRGBO(79, 93, 117, 1),
    Color.fromRGBO(239, 176, 167, 1),
    Color.fromRGBO(148, 168, 154, 1),
    Color.fromRGBO(23, 190, 187, 1),
    Color.fromRGBO(205, 83, 52, 1),
    Color.fromRGBO(237, 184, 139, 1),
    Color.fromRGBO(55, 114, 255, 1),
    Color.fromRGBO(85, 40, 111, 1),
    Color.fromRGBO(56, 174, 204, 1),
    Color.fromRGBO(102, 195, 84, 1)
  ];
  static const Color primaryColor = Color.fromRGBO(239, 48, 84, 1);

  static Color enabledTextColor = primaryColorDarkHSL.toColor();
  static const Color appBarTextColor = Colors.white;
  static Color nonViableBackgroundColor = Color.fromRGBO(150, 150, 150, 1);
  static Color textBackgroundColor = Colors.white;
  static Color textBorderColor = Colors.white;
  static Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  static Color textFieldTextColor = Color(0xff1F1F1F).withOpacity(0.4);

  static Color defaultTextColor = Color.fromRGBO(31, 31, 31, 1);
  static Color lateTextColor = Color.fromRGBO(209, 24, 25, 1);
  static Color greenCheck = Color.fromRGBO(9, 203, 156, 1);
  static Color warningAmber = Color.fromRGBO(245, 166, 35, 1);
  static const Color inputFieldTextColor = Colors.black;
  static const Color gridLineColor = primaryColor;


  static const Color primaryContrastColor = Colors.white;
  static const Color primaryContrastTextColor = Colors.white;
  static const Color inactiveTextColor = Color(0xFF4A4A4A);
  static const Color black = Colors.black;

  static const Color appBarColor = primaryColor;

  static const Color accentColor = Color.fromRGBO(179, 194, 242, 1);
  static const Color accentButtonColor = Color.fromRGBO(103, 80, 164, 1);
  static const Color errorBackgroundColor = Colors.black54;
  static const Color errorTxtColor = Colors.red;
  static const Color loadColor = accentColor;
  static HSLColor primaryColorHSL = HSLColor.fromColor(primaryColor);
  static HSLColor primaryColorDarkHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness - 0.3);
  static HSLColor oPrimaryColorHSL = primaryColorDarkHSL;
  static HSLColor primaryColorLightHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness + 0.2);
  static HSLColor accentColorHSL = HSLColor.fromColor(accentColor);
  static Color borderColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color activeColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color defaultWidgetBackgroundColor = Colors.white;
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledBackgroundColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static const Color deletedBackgroundColor = Colors.red;
}