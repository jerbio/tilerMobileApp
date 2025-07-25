import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/util.dart';

class TileStyles {
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
  static final double tileWidth = 350;
  static final double tileHeight = 300;
  static final double tileWidthRatio = 0.85;
  static final double tileIconSize = 12;
  static final double borderRadius = 12;
  static final double inputWidthFactor = 0.85;
  static final double widthRatio = 0.85;
  static final double proceedAndCancelButtonWidth = 60;
  static final double proceedAndCancelTotalButtonWidth =
      proceedAndCancelButtonWidth * 2;
  static final Color greenApproval = const Color.fromRGBO(9, 203, 156, 1);
  static final Color greenCheck = greenApproval;
  static Color warningAmber = Color.fromRGBO(245, 166, 35, 1);

  static const Color primaryColor = Color.fromRGBO(239, 48, 84, 1);
  static const Color primaryContrastColor = Colors.white;
  static const Color accentContrastColor = Colors.black;
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
  static Color defaultWidgetBackgroundColor =
      const Color.fromRGBO(247, 247, 248, 1);
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledBackgroundColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static const Color deletedBackgroundColor = Colors.red;

  static const BottomNavigationBarThemeData bottomNavTheme =
      BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    selectedIconTheme: IconThemeData(color: primaryColor),
    unselectedIconTheme: IconThemeData(color: primaryColor),
  );
  static ButtonStyle disabledButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Color.fromRGBO(154, 158, 159, 1);
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.white;
    }),
  );
  static ButtonStyle selectedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return primaryColor;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.white;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
  );

  static ButtonStyle suggestedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return primaryColor;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: WidgetStateProperty.resolveWith((states) {
      return EdgeInsets.all(30);
    }),
  );
  static ButtonStyle enabledButtonStyle = ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: primaryColor)),
    shadowColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return primaryColor;
    }),
  );

  static ButtonStyle toggledButtonStyle = ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: primaryColor)),
    shadowColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return primaryColor;
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return appBarTextColor;
      }
      return primaryColorHSL.toColor();
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return primaryColorLightHSL.toColor();
    }),
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.any((element) => element == MaterialState.selected)) {
        return appBarTextColor;
      }
      return primaryColorHSL.toColor();
    }),
  );

  static ButtonStyle strippedButtonStyle = ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: WidgetStateProperty.resolveWith((states) {
      return EdgeInsets.all(0);
    }),
    shadowColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
  );

  static ButtonStyle onlyIcons = ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: WidgetStateProperty.resolveWith((states) {
      return EdgeInsets.all(0);
    }),
    shadowColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return primaryColor;
    }),
  );

  static ButtonStyle onlyIconsContrast = ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    elevation: WidgetStateProperty.resolveWith((states) {
      return 0;
    }),
    padding: WidgetStateProperty.resolveWith((states) {
      return EdgeInsets.all(0);
    }),
    shadowColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return primaryContrastColor;
    }),
  );

  static Color enabledTextColor = primaryColorDarkHSL.toColor();
  static const Color appBarTextColor = Colors.white;
  static Color nonViableBackgroundColor = Color.fromRGBO(150, 150, 150, 1);

  static Color textFieldTextColor = Color(0xff1F1F1F).withOpacity(0.4);
  static double textFontSize = 25;
  static const String rubikFontName = 'Rubik';
  static Color defaultTextColor = Color.fromRGBO(31, 31, 31, 1);
  static Color lateTextColor = Color.fromRGBO(209, 24, 25, 1);
  static TextStyle daySummaryStyle = const TextStyle(
      fontSize: 30, color: const Color.fromRGBO(153, 153, 153, 1));
  static TextStyle fullScreenTextFieldStyle = TextStyle(
      color: defaultTextColor,
      fontSize: textFontSize,
      fontFamily: rubikFontName,
      fontWeight: FontWeight.w500);

  static const TextStyle editTimeOrDateTimeStyle = TextStyle(
      fontSize: 18,
      fontFamily: rubikFontName,
      color: const Color.fromRGBO(40, 40, 40, 1));
  static const TextStyle defaultTextStyle = TextStyle(
      fontSize: 18,
      fontFamily: rubikFontName,
      color: const Color.fromRGBO(40, 40, 40, 1));
  static Color textBackgroundColor = Colors.white;
  static Color textBorderColor = Colors.white;
  static Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  static EdgeInsets topMargin = EdgeInsets.fromLTRB(0, 20, 0, 0);
  static final Color defaultBackgroundColor =
      TileStyles.defaultWidgetBackgroundColor;
  static final BoxDecoration defaultBackgroundDecoration =
      BoxDecoration(color: Colors.transparent);
  static final BoxDecoration defaultBackground =
      BoxDecoration(color: Colors.transparent);
  static final titleBarStyle = TextStyle(
    color: TileStyles.appBarTextColor,
  );
  static const datePickersMainStyle =
      TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold);
  static const datePickersSaveStyle =
      TextStyle(fontFamily: rubikFontName, color: primaryColor);
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
          colors: [TileStyles.primaryColor, TileStyles.primaryColor]));
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

  static BoxShadow inputFieldBoxShadow = BoxShadow(
    color: Color.fromRGBO(168, 168, 168, 0.54),
    spreadRadius: 2,
    blurRadius: 50,
    offset: Offset(0, 0),
  );

  static Radius inputFieldRadius = const Radius.circular(50.0);
  static BorderRadius inputFieldBorderRadius =
      BorderRadius.all(inputFieldRadius);
  static const double inputHeight = 60;
  static const double inputFontSize = 20;
  static EdgeInsets inputFieldPadding = EdgeInsets.fromLTRB(30, 15, 10, 15);
  static TextStyle inputTextStyle = TextStyle(
    fontSize: TileStyles.inputFontSize,
    fontFamily: TileStyles.rubikFontName,
    color: TileStyles.inputFieldTextColor,
  );

  static const EdgeInsets inpuPadding = const EdgeInsets.all(8.0);
  static const Color inputFieldTextColor = Colors.black;
  static const FontWeight inputFieldFontWeight = FontWeight.w400;
  static const FontWeight inputFieldHintFontWeight = FontWeight.w100;
  static const IconData multiShareIcon = Icons.bento_outlined;
  static const Widget multiShareWidget = Icon(
    multiShareIcon,
    color: TileStyles.primaryContrastColor,
  );

  static BoxDecoration configUpdate_notSelected = BoxDecoration(
      color: Colors.transparent,
      border: Border.all(
        color: TileStyles.primaryColor,
        width: 1,
      ),
      borderRadius: const BorderRadius.all(
        const Radius.circular(60.0),
      ));
  static const BoxDecoration configUpdate_Selected = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(60.0),
      ),
      color: TileStyles.primaryColor);
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
  static const Color gridLineColor = primaryColor;
  static const double thickness = 1.0;
  static const double timeOfDayCellWidth = 35;

  static IconData restrictionProfileIcon = Icons.switch_left;
  static IconData repetitionIcon = Icons.repeat_outlined;
  static IconData forecastIcon = FontAwesomeIcons.binoculars;
  static const double defaultCardElevation = 5.0;

  static Widget getShimmerPending(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.transparent,
        highlightColor: TileStyles.primaryColor.withLightness(0.9),
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: ColoredBox(
              color: Colors.yellow,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              )),
        ));
  }

  static AppBar CancelAndProceedAppBar(String title) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: TileStyles.appBarColor,
      iconTheme: IconThemeData(color: TileStyles.appBarTextColor),
      actionsIconTheme: IconThemeData(color: TileStyles.appBarTextColor),
      titleTextStyle: TextStyle(
        color: TileStyles.appBarTextColor,
        fontSize: 20,
        fontFamily: TileStyles.rubikFontName,
      ),
      leading: SizedBox.shrink(),
    );
  }
}
