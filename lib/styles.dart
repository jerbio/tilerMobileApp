import 'package:flutter/material.dart';

class TileStyles {
  static final double tileWidth = 350;
  static final double tileHeight = 350;
  static final double tileWidthRatio = 0.85;
  static final double tileIconSize = 12;
  static final double borderRadius = 12;
  static final double inputWidthFactor = 0.85;
  static final double widthRatio = 0.85;
  static final double proceedAndCancelButtonWidth = 60;
  static final double proceedAndCancelTotalButtonWidth =
      proceedAndCancelButtonWidth * 2;
  static Color greenCheck = Color.fromRGBO(9, 203, 156, 1);
  static Color warningAmber = Color.fromRGBO(245, 166, 35, 1);

  static const Color primaryColor = Color.fromRGBO(239, 48, 84, 1);
  static const Color primaryContrastColor = Colors.white;
  static const Color appBarColor = primaryColor;

  static Color accentColor = Color.fromRGBO(179, 194, 242, 1);
  static HSLColor primaryColorHSL = HSLColor.fromColor(primaryColor);
  static HSLColor primaryColorDarkHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness - 0.3);
  static HSLColor oPrimaryColorHSL = primaryColorDarkHSL;
  static HSLColor primaryColorLightHSL = HSLColor.fromColor(primaryColor)
      .withLightness(HSLColor.fromColor(primaryColor).lightness + 0.2);
  static HSLColor accentColorHSL = HSLColor.fromColor(accentColor);
  static Color borderColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color activeColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledBackgroundColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static ButtonStyle disabledButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return Color.fromRGBO(154, 158, 159, 1);
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.white;
    }),
  );
  static ButtonStyle selectedButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return primaryColorDarkHSL.toColor();
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.white;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
  );

  static ButtonStyle suggestedButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return primaryColorDarkHSL.toColor();
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: MaterialStateProperty.resolveWith((states) {
      return EdgeInsets.all(30);
    }),
  );
  static ButtonStyle enabledButtonStyle = ButtonStyle(
    side: MaterialStateProperty.all(
        BorderSide(color: primaryColorDarkHSL.toColor())),
    shadowColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return primaryColorDarkHSL.toColor();
    }),
  );

  static ButtonStyle toggledButtonStyle = ButtonStyle(
    side: MaterialStateProperty.all(
        BorderSide(color: primaryColorDarkHSL.toColor())),
    shadowColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return primaryColorDarkHSL.toColor();
      }
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return appBarTextColor;
      }
      return primaryColorDarkHSL.toColor();
    }),
    overlayColor: MaterialStateProperty.resolveWith((states) {
      return primaryColorLightHSL.toColor();
    }),
    iconColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return appBarTextColor;
      }
      return primaryColorDarkHSL.toColor();
    }),
  );

  static ButtonStyle strippedButtonStyle = ButtonStyle(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: MaterialStateProperty.resolveWith((states) {
      return EdgeInsets.all(0);
    }),
    shadowColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
  );

  static ButtonStyle onlyIcons = ButtonStyle(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: MaterialStateProperty.resolveWith((states) {
      return EdgeInsets.all(0);
    }),
    shadowColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      return primaryColor;
    }),
  );

  static Color enabledTextColor = primaryColorDarkHSL.toColor();
  static Color appBarTextColor = Colors.white;
  static Color nonViableBackgroundColor = Color.fromRGBO(150, 150, 150, 1);

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

  static const TextStyle editTimeOrDateTimeStyle =
      TextStyle(fontSize: 18, color: const Color.fromRGBO(40, 40, 40, 1));
  static Color textBackgroundColor = Color.fromRGBO(239, 48, 84, .05);
  static Color textBorderColor = Colors.white;
  static Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  static EdgeInsets topMargin = EdgeInsets.fromLTRB(0, 20, 0, 0);
  static final BoxDecoration defaultBackground =
      BoxDecoration(color: Colors.transparent
          // gradient: LinearGradient(
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //     colors: [
          //   Color.fromRGBO(179, 194, 242, 1).withOpacity(0.5),
          //   Colors.white.withOpacity(0.5),
          //   Color.fromRGBO(239, 48, 84, 1).withOpacity(0.5),
          // ])
          );
  static final titleBarStyle = TextStyle(
    color: TileStyles.appBarTextColor,
  );
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
  static final BoxDecoration tileIconContainerBoxDecoration = BoxDecoration(
      color: Color.fromRGBO(31, 31, 31, 0.1),
      borderRadius: BorderRadius.circular(8));
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
          fontFamily: TileStyles.rubikFontName,
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

  static const String evaluatingScheduleAsset =
      'assets/lottie/tiler-evaluating-card-swap.json';
  static SizedBox bottomPortraitPaddingForTileBatchListOfTiles =
      SizedBox(height: 200);
  static SizedBox bottomLandScapePaddingForTileBatchListOfTiles =
      SizedBox(height: 150);
}
