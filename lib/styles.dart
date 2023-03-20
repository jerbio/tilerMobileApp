import 'package:flutter/material.dart';

class TileStyles {
  static final double tileWidth = 350;
  static final double tileHeight = 350;
  static final double tileWidthRatio = 0.85;
  static final double borderRadius = 12;
  static final double inputWidthFactor = 0.85;
  static final double proceedAndCancelButtonWidth = 60;
  static final double proceedAndCancelTotalButtonWidth =
      proceedAndCancelButtonWidth * 2;
  static Color borderColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color activeColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static Color enabledTextColor = Colors.white;
  static Color primaryColor = Color.fromRGBO(239, 48, 84, 1);
  static HSLColor primaryColorHSL = HSLColor.fromColor(primaryColor);
  static HSLColor primaryColorDarkHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness - 0.3);
  static HSLColor primaryColorLightHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness + 0.2);
  static Color accentColor = Color.fromRGBO(179, 194, 242, 1);
  static HSLColor accentColorHSL = HSLColor.fromColor(accentColor);
  static Color textFieldTextColor = Color(0xff1F1F1F).withOpacity(0.4);
  static double textFontSize = 25;
  static const String rubikFontName = 'Rubik';
  static Color defaultTextColor = Color.fromRGBO(31, 31, 31, 1);
  static Color lateTextColor = Color.fromRGBO(209, 24, 25, 1);
  static TextStyle fullScreenTextFieldStyle = TextStyle(
      color: defaultTextColor,
      fontSize: textFontSize,
      fontFamily: rubikFontName,
      fontWeight: FontWeight.w500);
  static Color textBackgroundColor = Color.fromRGBO(239, 48, 84, .05);
  static Color textBorderColor = Colors.white;
  static Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  static EdgeInsets topMargin = EdgeInsets.fromLTRB(0, 20, 0, 0);
  static final BoxDecoration defaultBackground = BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
        Color.fromRGBO(179, 194, 242, 1).withOpacity(0.1),
        Colors.white.withOpacity(0.1),
        Color.fromRGBO(239, 48, 84, 1).withOpacity(0.1),
      ]));
  static final BoxDecoration invalidBoxDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          HSLColor.fromAHSL(1, 360, 0.9, 0.46).toColor(),
          HSLColor.fromAHSL(1, 350, 1, 0.7).toColor()
        ],
      ));
  static InputDecoration generateTextInputDecoration(String? inputHint,
      {Icon? prefixIcon}) {
    return InputDecoration(
      hintText: inputHint,
      filled: true,
      isDense: true,
      icon: prefixIcon,
      hintStyle: TextStyle(
          color: Color.fromRGBO(180, 180, 180, 1),
          fontSize: textFontSize,
          fontFamily: 'Rubik',
          fontWeight: FontWeight.w500),
      contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      fillColor: textBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
        borderSide: BorderSide(color: textBorderColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
        borderSide: BorderSide(
          color: textBorderColor,
          width: 1.5,
        ),
      ),
    );
  }
}
