import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class TileStyles {
  TileStyles._();

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

  static const BottomNavigationBarThemeData bottomNavTheme = BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    selectedIconTheme: IconThemeData(color: TileColors.primaryColor),
    unselectedIconTheme: IconThemeData(color: TileColors.primaryColor),
  );
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
      return TileColors.primaryColor;
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
      return TileColors.primaryColor;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: MaterialStateProperty.resolveWith((states) {
      return EdgeInsets.all(30);
    }),
  );
  static ButtonStyle enabledButtonStyle = ButtonStyle(
    side: MaterialStateProperty.all(BorderSide(color: TileColors.primaryColor)),
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
      return TileColors.primaryColor;
    }),
  );

  static ButtonStyle toggledButtonStyle = ButtonStyle(
    side: MaterialStateProperty.all(BorderSide(color: TileColors.primaryColor)),
    shadowColor: MaterialStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      return 0;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return TileColors.primaryColor;
      }
      return Colors.transparent;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return TileColors.appBarTextColor;
      }
      return TileColors.primaryColorHSL.toColor();
    }),
    overlayColor: MaterialStateProperty.resolveWith((states) {
      return TileColors.primaryColorLightHSL.toColor();
    }),
    iconColor: MaterialStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return TileColors.appBarTextColor;
      }
      return TileColors.primaryColorHSL.toColor();
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
      return TileColors.primaryColor;
    }),
  );

  static ButtonStyle onlyIconsContrast = ButtonStyle(
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
      return TileColors.primaryContrastColor;
    }),
  );

  static double textFontSize = 25;
  static const double thickness = 1.0;
  static const double timeOfDayCellWidth = 35;
  static TextStyle daySummaryStyle = const TextStyle(
      fontSize: 30, color: const Color.fromRGBO(153, 153, 153, 1));
  static TextStyle fullScreenTextFieldStyle = TextStyle(
      color: TileColors.defaultTextColor,
      fontSize: textFontSize,
      fontFamily: TileTextStyles.rubikFontName,
      fontWeight: FontWeight.w500);

  static const TextStyle editTimeOrDateTimeStyle = TextStyle(
      fontSize: 18,
      fontFamily: TileTextStyles.rubikFontName,
      color: const Color.fromRGBO(40, 40, 40, 1));
  static const TextStyle defaultTextStyle = TextStyle(
      fontSize: 18,
      fontFamily: TileTextStyles.rubikFontName,
      color: const Color.fromRGBO(40, 40, 40, 1));

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
    color: TileColors.appBarTextColor,
  );
  static const datePickersMainStyle =
  TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold);
  static const datePickersSaveStyle =
  TextStyle(fontFamily: TileTextStyles.rubikFontName, color: TileColors.primaryColor);
  static final BoxDecoration ribbonsButtonDefaultDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(240, 240, 240, 1),
            Color.fromRGBO(240, 240, 240, 1),
          ]));
  static final ribbonsButtonSelectedDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(20.0),
      ),
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TileColors.primaryColor, TileColors.primaryColor]));
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
  static final BoxDecoration tileIconContainerBoxDecorationMonthly =
  BoxDecoration(
      color: Color.fromRGBO(31, 31, 31, 0.1), shape: BoxShape.circle);
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
          fontFamily: TileTextStyles.rubikFontName,
          fontWeight: FontWeight.w500),
      contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      fillColor: TileColors.textBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
        borderSide: BorderSide(color: TileColors.textBorderColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          const Radius.circular(15.0),
        ),
        borderSide: BorderSide(
          color: TileColors.textBorderColor,
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

  static BoxShadow inputFieldBoxShadow = BoxShadow(
    color: Color.fromRGBO(168, 168, 168, 0.54),
    spreadRadius: 2,
    blurRadius: 50,
    offset: Offset(0, 0),
  );

  static BorderRadius inputFieldBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(10));
  static const double inputHeight = 60;
  static const double inputFontSize = 20;
  static EdgeInsets inputFieldPadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
  static TextStyle inputTextStyle = TextStyle(
    fontSize: TileStyles.inputFontSize,
    fontFamily: TileTextStyles.rubikFontName,
    color: TileColors.inputFieldTextColor,
  );

  static const EdgeInsets inpuPadding = const EdgeInsets.all(8.0);

  static const FontWeight inputFieldFontWeight = FontWeight.w400;
  static const FontWeight inputFieldHintFontWeight = FontWeight.w100;
  static const IconData multiShareIcon = Icons.bento_outlined;
  static const Widget multiShareWidget = Icon(
    multiShareIcon,
    color: TileColors.primaryContrastColor,
  );

  static BoxDecoration configUpdate_notSelected = BoxDecoration(
      color: Colors.transparent,
      border: Border.all(
        color: TileColors.primaryColor,
        width: 1,
      ),
      borderRadius: const BorderRadius.all(
        const Radius.circular(10.0),
      ));
  static const BoxDecoration configUpdate_Selected = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      color: TileColors.primaryColor);


  static IconData restrictionProfileIcon = Icons.switch_left;
  static IconData repetitionIcon = Icons.repeat_outlined;
  static IconData forecastIcon = FontAwesomeIcons.binoculars;
  static const double defaultCardElevation = 5.0;
}
