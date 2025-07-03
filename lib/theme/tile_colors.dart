import 'package:flutter/material.dart';
class TileColors{
  const TileColors._();
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
  static const Color primary = Color(0xFFEF3054);
  static  final Color darkPrimary=HSLColor.fromColor(primary).withLightness(HSLColor.fromColor(primary).lightness - 0.3).toColor();
  static const Color secondaryLight = Color(0xFF625B71);
  static const Color secondaryDark = Colors.white;
  static const Color lightContent = Colors.white;
  static const Color darkContent = Color(0xFF1F1F1F);
  static const Color onError = Colors.red;
  static const Color error = Colors.redAccent;
  static HSLColor primaryContainerLight = HSLColor.fromColor(primary)
      .withLightness(HSLColor.fromColor(primary).lightness + 0.2);
  static HSLColor primaryContainerDark = HSLColor.fromColor(primary)
      .withLightness(0.22)
      .withSaturation(0.30);
  static  Color primaryContainerLowLight=primaryContainerLight.withLightness(0.95).toColor();
  static Color primaryContainerLowDark = primaryContainerDark.withLightness(0.35).toColor();
  static const Color onPrimaryContainerLight = Color(0xFFFFDDE3);
  static const Color onPrimaryContainerDark = Color(0xFFFFB3C1);
  static const Color surfaceLight = Color.fromRGBO(247, 247, 248, 1);
  static const Color surfaceContainerLight = Color(0xFFF0F0F0);
  static const Color surfaceContainerHighLight = Color(0xFFF0E6E8);
  static const Color surfaceContainerHighestLight = Color(0xFFF7F2F3);
  static const Color surfaceDark = Color.fromRGBO(22, 22, 24, 1);
  static const Color surfaceContainerLowDark = Color(0xFF111113);
  static const Color surfaceContainerDark = Color(0xFF0E0E10);
  static const Color surfaceContainerHighDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerHighestDark = Color(0x33424242);
  static  Color onSurfaceVariantLowLight = Colors.grey[200]!;
  static const Color onSurfaceVariantLight = Colors.grey;
  static  Color onSurfaceVariantHighLight = Color(0xFF999999);
  static  Color onSurfaceVariantHighestLight = Colors.grey[600]!;
  static const Color tertiary=Color(0xFF6750A4);
  static const Color tertiaryContainer=Color(0xFFB3C2F2);
  static  Color onSurfaceVariantLowDark = Colors.grey[800]!;
  static const Color onSurfaceVariantDark = Color(0xFF9E9E9E);
  static  Color onSurfaceVariantHighDark =  Color(0xFF666666);
  static  Color onSurfaceVariantHighestDark = Colors.grey[400]!;
  static const Color outlineLight = Color(0xFF79747E);
  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantLight = Color(0xFFCAC4D0);
  static const Color outlineVariantDark = Color(0xFF49454F);
  static const Color inverseSurfaceLight = Colors.black54;
  static const Color inverseSurfaceDark = Color(0xFFE6E1E5);
  static const Color onInverseSurfaceDark = Color(0xFF313033);
  static const Color inversePrimaryLight=Color(0xFF4A4A4A);
  static const Color inversePrimaryDark = Color(0xFFB0B0B0);
  static const Color scrimColorLight=Color(0x80EEEEEE);
  static const Color scrimColorDark=Color(0x80000000);
  static const Color shadowLight=Colors.black;
  static const Color shadowDark=Color(0xFF9E9E9E);
  static const Color shadowLowestLight= Color(0xFFF5F5F5);
  static const Color shadowLowestDark= Color(0xFF1A1A1C);
  static const Color shadowLowLight= Color(0xFFDCDCDC);
  static const Color shadowLowDark= Color(0xFF2A2A2C);
  static const Color shadowBaseLight= Colors.grey;
  static const Color shadowBaseDark= Color(0xFF3A3A3C);
  static const Color shadowHighLight= Color(0xFFA8A8A8);
  static const Color shadowHighDark= Color(0xFF1A1A1C);
  static const Color shadowHigherLight= Color(0xFF969696);
  static const Color shadowHigherDark= Color(0xFF505052);
  static const Color shadowHighestLight= Colors.black87;
  static const Color shadowHighestDark= Colors.white70;
  static const Color shadowInverseLight= Colors.white;
  static const Color shadowInverseVariantLight= Colors.white70;
  static const Color shadowInverseDark= Colors.black;
  static const Color shadowInverseVariantDark= Colors.black54;
  static const Color onSurfaceTertiaryLight=Color(0xFFB4B4B4);
  static const Color onSurfaceTertiaryDark=Color(0xFF4B4B4B);
  static const Color onSurfaceQuaternaryLight=  Color(0xFF9A9E9F);
  static const Color onSurfaceQuaternaryDark=  Color(0xFF66696A);
  static const Color surfaceContainerGreaterLight= Color(0xFFDCDCDC);
  static const Color surfaceContainerGreaterDark= Color(0xFF2A2A2C);
  static const Color surfaceContainerPlusLight= Color(0xFF696969);
  static const Color surfaceContainerPlusDark= Color(0xFF505050);
  static const Color surfaceContainerMaximumLight= Color(0xFF969696);
  static const Color surfaceContainerMaximumDark= Color(0xFF6A6A6A);
  static const Color surfaceContainerUltimateLight=Color(0xFF353535);
  static const Color surfaceContainerUltimateDark=Color(0xFFB5B5B5);
  static const Color onSurfaceHintLight= Color(0xFF4A4A4A);
  static const Color surfaceContainerDisabledLight= Color(0xFFE1E1E1);
  static const Color onSurfaceHintDark= Color(0xFFB5B5B5);
  static const Color surfaceContainerDisabledDark= Color(0xFF2E2E2E);
  static const Color completedGreen=Colors.green;
  static  Color activeNotification=Colors.green[300]!;
  static const Color acceptedTileShare=Colors.green;
  static const Color checkUnscheduled=Colors.green;
  static const Color predictiveContainerBg=Colors.green;
  static const Color activeForesCastTime=Colors.green;
  static const Color activeLocation=Color(0xFF00A9A9);
  static const Color highPriority=Colors.red;
  static const Color warning=Colors.amberAccent;
  static const Color accentWarning=Colors.amberAccent;
  static const Color completedTeal=Color(0xFF03CEA4);
  static const Color late=Color(0xFFD11819);
  static const Color deleted=Color(0xFFE63946);
  static const Color scheduled=Color(0xFF345995);
  static const Color success = Colors.greenAccent;
  static const Color whatIfHighlight = Colors.greenAccent;
  static const Color deletion = Colors.redAccent;
  static const Color left = Colors.blueAccent;
  static const Color travel=Colors.orange;
  static const Color progressMedium=Colors.orange;
  static const Color tardy=Colors.pink;
  static const Color tardyForecast=Colors.blue;
  static const Color responseTileShare=Colors.blue;
  static const Color copied=Colors.cyanAccent;
  static const Color sleepBackground= Color(0xFF333333);
  static const Color forgetPassword=Color(0xFF880E4F);
  static const Color highCompletionTileShare = Colors.green;
  static const Color lowCompletionTileShare = Colors.orange;
  static const Color acceptedRsvpTileShare = Colors.lightGreen;
  static const Color declinedRsvpTileShare = Colors.redAccent;
  static const Color greenPolyline=Colors.green;
  static const Color redPolyline=Colors.red;
  static const Color bluePolyline=Colors.blue;

  static const String darkMapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]''';
}

