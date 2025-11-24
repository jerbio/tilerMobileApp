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
  static const Color surfaceContainerHighLight = Color(0xFFEDE8E9);
  static const Color surfaceContainerHighestLight = Color(0xFFE6E0E2);
  static const Color surfaceDark = Color.fromRGBO(35, 39, 44, 1);
  static const Color surfaceContainerLowestLight = lightContent;
  static const Color surfaceContainerLowestDark = Color(0xFF1E2227);
  static const Color surfaceContainerLowLight = Color(0xFFF9F9FA);
  static const Color surfaceContainerLowDark = Color(0xFF1D1B20);
  static const Color surfaceContainerDark = Color(0xFF252930);
  static const Color surfaceContainerHighDark = Color(0xFF2D3136);
  static const Color surfaceContainerHighestDark = Color(0xFF343A40);
  static const Color tertiary=Color(0xFF6750A4);
  static const Color tertiaryContainer=Color(0xFFB3C2F2);
  static const Color onSurfaceVariantLight = Color(0xFF49454F);
  static const Color onSurfaceVariantDark =Color(0xFFCAC4D0);
  static  Color onSurfaceDaySummaryLight = Color(0xFF999999);
  static  Color onSurfaceDaySummaryDark =  Color(0xFF666666);
  static  Color onSurfaceMonthlyIntegrationLight = Colors.grey[600]!;
  static  Color onSurfaceMonthlyIntegrationDark = Colors.grey[400]!;
  static const Color outlineLight = Color(0xFF79747E);
  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantLight = Color(0xFFCAC4D0);
  static const Color outlineVariantDark = Color(0xFF49454F);
  static const Color inverseSurfaceLight = Colors.black54;
  static const Color inverseSurfaceDark = Color(0xFFE6E1E5);
  static const Color onInverseSurfaceDark = Color(0xFF23272C);
  static const Color inversePrimaryLight=Color(0xFF4A4A4A);
  static const Color inversePrimaryDark = Color(0xFFB0B0B0);
  static const Color scrimColorLight=Color(0x80EEEEEE);
  static const Color scrimColorDark=Color(0x80000000);
  static const Color shadowLight=Colors.black;
  static const Color shadowDark=Color(0xFF9E9E9E);
  static const Color shadowSignInContainerLight= Color(0xFFF5F5F5);
  static const Color shadowSignInContainerDark= Color(0xFF25292F);
  static const Color shadowPreviewChartIconographyOuterLight= Color(0xFFDCDCDC);
  static const Color shadowPreviewChartIconographyOuterDark= Color(0xFF595959);
  static const Color shadowPreviewChartIconographyInnerLight= Colors.white;
  static const Color shadowPreviewChartIconographyInnerDark= Colors.black;
  static const Color shadowSecondaryLight= Colors.grey;
  static const Color shadowSecondaryDark= Color(0xFF8A8A8A) ;
  static const Color shadowMainInputContainerLight= Color(0xFFA8A8A8);
  static const Color shadowMainInputContainerDark=Color(0x996E6E6E);
  static const Color shadowTimeScrubMovingBallLight= Color(0xFF969696);
  static const Color shadowTimeScrubMovingBallDark= Color(0xFF808080);
  static const Color shadowEmptyTileLight= Colors.black87;
  static const Color shadowEmptyTileDark= Color(0xFF6E6E6E);
  static const Color shadowSearchLight= Colors.white70;
  static const Color shadowSearchDark= Color(0xFF2A2E33);
  static const Color onSurfaceHintLight=Color(0xFFB4B4B4);
  static const Color onSurfaceHintDark=Color(0xFF4B4B4B);
  static const Color onSurfaceSecondaryLight=  Color(0xFF9A9E9F);
  static const Color onSurfaceSecondaryDark=  Color(0xFFB0B4B5);
  static const Color onSurfaceVariantSecondaryLight=  Colors.grey;
  static const Color onSurfaceVariantSecondaryDark=  Color(0x99FFFFFF);
  static const Color surfaceContainerGreaterLight= Color(0xFFDCDCDC);
  static const Color surfaceContainerGreaterDark= Color(0xFF424650);
  static const Color surfaceContainerSuperiorLight= Colors.grey;
  static const Color surfaceContainerSuperiorDark= Color(0xFF484C52);
  static const Color surfaceContainerPlusLight= Color(0xFF969696);
  static const Color surfaceContainerPlusDark= Color(0xFF505050);
  static const Color surfaceContainerMaximumLight= Color(0xFF696969);
  static const Color surfaceContainerMaximumDark= Color(0xFF6A6A6A);
  static const Color surfaceContainerUltimateLight=Color(0xFF353535);
  static const Color surfaceContainerUltimateDark=Color(0xFF474B51);
  static const Color onSurfaceDeadlineUnsetLight= Color(0xFF4A4A4A);
  static const Color onSurfaceDeadlineUnsetDark= Color(0xFFB5B5B5);
  static const Color onSurfaceTimeBlockLblLight= Color(0xFF969696);
  static const Color onSurfaceTimeBlockLblDark= Color(0xFF8A8A8A);
  static const Color surfaceContainerDisabledLight= Color(0xFFE1E1E1);
  static const Color surfaceContainerDisabledDark= Color(0xFF2A2E33);
  static const Color notificationOverlaySuccessLight=Color(0xFFE6F9F0);
  static const Color notificationOverlaySuccessDark=Color(0xFF0F2A1A);
  static const Color notificationOverlayWarningLight=Color(0xFFFFF8E1);
  static const Color notificationOverlayWarningDark=Color(0xFF2A2416);
  static const Color notificationOverlayErrorLight=Color(0xFFFCE4EC);
  static const Color notificationOverlayErrorDark=Color(0xFF2A1419);
  static const Color notificationOverlayInfoLight=Color(0xFFE1F5FE);
  static const Color notificationOverlayInfoDark=Color(0xFF0F1F2A);
  static final Color integrationBorderLight =  Colors.grey[300]!;
  static final Color integrationBorderDark = Color(0xFF424650);
  static final Color disabledOnboardingPillLight =  Colors.grey.shade300;
  static final Color disabledOnboardingPillDark = Color(0xFF4A5159);
  static final Color onDisabledOnboardingPillLight = Colors.grey.shade600;
  static final Color onDisabledOnboardingPillDark = Color(0xFFB0B8C0);
  static final Color suggestionLoadingOnboardingSurfaceLight =Color(0xFFECD4A9);
  static final Color suggestionLoadingOnboardingSurfaceDark = Color(0xFFE295A8);
  static final Color integrationApprovalLight =  Color.fromRGBO(9, 203, 156, 1);
  static final Color integrationApprovalDark =
  HSLColor.fromColor(integrationApprovalLight)
      .withLightness(0.35)
      .toColor();

  static const Color completedGreen=Colors.green;
  static  Color activeNotification=Colors.green[300]!;
  static const Color acceptedTileShare=Colors.green;
  static const Color checkUnscheduled=Colors.green;
  static const Color predictiveContainerBg=Colors.green;
  static const Color activeForesCastTime=Colors.green;
  static const Color activeLocation=Color(0xFF0076A8);
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
  static const Color shimmerBackground= Colors.yellow;
  static const Color forecastAnalysisCheck=Color(0xFF1AE1A6);
  static const Color forecastAnalysisWarning=Color(0xFFFF891C);
  static const Color forecastAnalysisConflict=Color(0xFFD61C3C);
  static const Color notificationSuccessBorder=Color(0xFF00C853);
  static const Color notificationWarningBorder=Color(0xFFFFA000);
  static const Color notificationErrorBorder=Color(0xFFD32F2F);
  static const Color notificationInfoBorder=Color(0xFF0288D1);

  static const String darkMapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]''';
}