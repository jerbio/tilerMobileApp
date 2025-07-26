import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class TileThemeExtension extends ThemeExtension<TileThemeExtension>{
  final Color shadowSignInContainer;
  final Color shadowPreviewChartIconographyOuter;
  final Color shadowPreviewChartIconographyInner;
  final Color shadowSecondary;
  final Color shadowMainInputContainer;
  final Color shadowTimeScrubMovingBall;
  final Color shadowEmptyTile;
  final Color shadowSearch;
  final Color onSurfaceDaySummary;
  final Color onSurfaceMonthlyIcons;
  final Color onSurfaceHint;
  final Color onSurfaceSecondary;
  final Color onSurfaceVariantSecondary;
  final Color primaryContainerLow;
  final Color surfaceContainerGreater;
  final Color surfaceContainerSuperior;
  final Color surfaceContainerPlus;
  final Color surfaceContainerMaximum;
  final Color surfaceContainerUltimate;
  final Color surfaceContainerDisabled;
  final Color onSurfaceDeadlineUnset;
  final Color onSurfaceTimeBlockLbl;
  final Color darkPrimary;
  final Color notificationOverlaySuccess;
  final Color notificationOverlayWarning;
  final Color notificationOverlayError;
  final Color notificationOverlayInfo;
  final String? mapStyle;
  const TileThemeExtension._(
      {
        required this.shadowPreviewChartIconographyOuter,
        required this.shadowSecondary,
        required this.shadowMainInputContainer,
        required this.shadowTimeScrubMovingBall,
        required this.shadowEmptyTile,
        required this.shadowSignInContainer,
        required this.shadowPreviewChartIconographyInner,
        required this.shadowSearch,
        required this.primaryContainerLow,
        required this.onSurfaceDaySummary,
        required this.onSurfaceMonthlyIcons,
        required this.surfaceContainerGreater,
        required this.surfaceContainerSuperior,
        required this.surfaceContainerPlus,
        required this.surfaceContainerMaximum,
        required this.surfaceContainerUltimate,
        required this.onSurfaceDeadlineUnset,
        required this.surfaceContainerDisabled,
        required this.onSurfaceHint,
        required this.onSurfaceSecondary,
        required this.onSurfaceVariantSecondary,
        required this.onSurfaceTimeBlockLbl,
        required this.darkPrimary,
        required this.mapStyle,
        required this.notificationOverlaySuccess,
        required this.notificationOverlayWarning,
        required this.notificationOverlayError,
        required this.notificationOverlayInfo,
      });

  static TileThemeExtension get light =>TileThemeExtension._(
    shadowSignInContainer:TileColors.shadowSignInContainerLight,
      shadowPreviewChartIconographyOuter: TileColors.shadowPreviewChartIconographyOuterLight,
      shadowSecondary: TileColors.shadowSecondaryLight,
      shadowMainInputContainer: TileColors.shadowMainInputContainerLight,
      shadowTimeScrubMovingBall: TileColors.shadowTimeScrubMovingBallLight,
      shadowEmptyTile: TileColors.shadowEmptyTileLight,
      shadowPreviewChartIconographyInner: TileColors.shadowPreviewChartIconographyInnerLight,
      shadowSearch: TileColors.shadowSearchLight,
      primaryContainerLow: TileColors.primaryContainerLowLight,
      onSurfaceDaySummary: TileColors.onSurfaceDaySummaryLight,
      onSurfaceMonthlyIcons: TileColors.onSurfaceMonthlyIconsLight,
      onSurfaceHint: TileColors.onSurfaceHintLight,
      onSurfaceSecondary:  TileColors.onSurfaceSecondaryLight,
      onSurfaceVariantSecondary:TileColors.onSurfaceVariantSecondaryLight,
      surfaceContainerGreater:TileColors.surfaceContainerGreaterLight,
      surfaceContainerSuperior:TileColors.surfaceContainerGreaterLight,
      surfaceContainerPlus: TileColors.surfaceContainerPlusLight,
      surfaceContainerMaximum:TileColors.surfaceContainerMaximumLight,
      surfaceContainerUltimate:TileColors.surfaceContainerUltimateLight,
      onSurfaceDeadlineUnset:TileColors.onSurfaceDeadlineUnsetLight,
      onSurfaceTimeBlockLbl:TileColors.onSurfaceTimeBlockLblLight,
      surfaceContainerDisabled: TileColors.surfaceContainerDisabledLight,
      darkPrimary:TileColors.darkPrimary,
      notificationOverlaySuccess: TileColors.notificationOverlaySuccessLight,
      notificationOverlayWarning: TileColors.notificationOverlayWarningLight,
      notificationOverlayError: TileColors.notificationOverlayErrorLight,
      notificationOverlayInfo: TileColors.notificationOverlayInfoLight,
      mapStyle: null,
  );

  static TileThemeExtension get dark => TileThemeExtension._(
    shadowSignInContainer: TileColors.shadowSignInContainerDark,
      shadowPreviewChartIconographyOuter: TileColors.shadowPreviewChartIconographyOuterDark,
      shadowSecondary: TileColors.shadowSecondaryDark,
      shadowMainInputContainer: TileColors.shadowMainInputContainerDark,
      shadowTimeScrubMovingBall: TileColors.shadowTimeScrubMovingBallDark,
      shadowEmptyTile: TileColors.shadowEmptyTileDark,
      shadowPreviewChartIconographyInner: TileColors.shadowPreviewChartIconographyInnerDark,
      shadowSearch: TileColors.shadowSearchDark,
      primaryContainerLow: TileColors.primaryContainerLowDark,
      onSurfaceDaySummary: TileColors.onSurfaceDaySummaryDark,
      onSurfaceMonthlyIcons: TileColors.onSurfaceMonthlyIconsDark,
      onSurfaceHint: TileColors.onSurfaceHintDark,
      onSurfaceSecondary: TileColors.onSurfaceSecondaryDark,
      onSurfaceVariantSecondary:TileColors.onSurfaceVariantSecondaryDark,
      surfaceContainerGreater:TileColors.surfaceContainerGreaterDark,
      surfaceContainerSuperior:TileColors.surfaceContainerGreaterLight,
      surfaceContainerPlus: TileColors.surfaceContainerPlusDark,
      surfaceContainerMaximum:TileColors.surfaceContainerMaximumDark,
      surfaceContainerUltimate:TileColors.surfaceContainerUltimateDark,
      onSurfaceDeadlineUnset: TileColors.onSurfaceDeadlineUnsetDark,
      onSurfaceTimeBlockLbl:TileColors.onSurfaceTimeBlockLblDark,
      surfaceContainerDisabled: TileColors.surfaceContainerDisabledDark,
      darkPrimary:TileColors.darkPrimary,
      mapStyle:TileColors.darkMapStyle,
      notificationOverlaySuccess: TileColors.notificationOverlaySuccessDark,
      notificationOverlayWarning: TileColors.notificationOverlayWarningDark,
      notificationOverlayError: TileColors.notificationOverlayErrorDark,
      notificationOverlayInfo: TileColors.notificationOverlayInfoDark,
  );

  @override
  ThemeExtension<TileThemeExtension> copyWith({
    Color? shadowSignInContainer,
    Color? shadowPreviewChartIconographyOuter,
    Color? shadowSecondary,
    Color? shadowMainInputContainer,
    Color? shadowTimeScrubMovingBall,
    Color? emptyTileShadow,
    Color? shadowPreviewChartIconographyInner,
    Color? shadowSearch,
    Color? primaryContainerLow,
    Color? onSurfaceDaySummary,
    Color? onSurfaceMonthlyIcons,
    Color?  onSurfaceHint,
    Color? onSurfaceSecondary,
    Color? onSurfaceVariantSecondary,
    Color? surfaceContainerGreater,
    Color? surfaceContainerSuperior,
    Color? surfaceContainerPlus,
    Color? surfaceContainerMaximum,
    Color? surfaceContainerUltimate,
    Color? onSurfaceDeadlineUnset,
    Color? onSurfaceTimeBlockLbl,
    Color? surfaceContainerDisabled,
    Color? darkPrimary,
    Color? notificationOverlaySuccess,
    Color? notificationOverlayWarning,
    Color? notificationOverlayError,
    Color? notificationOverlayInfo,
    String? mapStyle
  }) {
    return TileThemeExtension._(
        shadowPreviewChartIconographyOuter: shadowPreviewChartIconographyOuter ?? this.shadowPreviewChartIconographyOuter,
        shadowSecondary: shadowSecondary ?? this.shadowSecondary,
        shadowMainInputContainer: shadowMainInputContainer ?? this.shadowMainInputContainer,
        shadowTimeScrubMovingBall: shadowTimeScrubMovingBall ?? this.shadowTimeScrubMovingBall,
        shadowEmptyTile: emptyTileShadow ??this.shadowEmptyTile,
        shadowSignInContainer: shadowSignInContainer ?? this.shadowSignInContainer,
        shadowPreviewChartIconographyInner: shadowPreviewChartIconographyInner ?? this.shadowPreviewChartIconographyInner,
        shadowSearch: shadowSearch ?? this.shadowSearch,
        primaryContainerLow: primaryContainerLow  ?? this.primaryContainerLow,
        onSurfaceDaySummary: onSurfaceDaySummary ?? this.onSurfaceDaySummary,
        onSurfaceMonthlyIcons: onSurfaceMonthlyIcons ?? this.onSurfaceMonthlyIcons,
        onSurfaceHint: onSurfaceHint ?? this.onSurfaceHint,
        onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
        onSurfaceVariantSecondary: onSurfaceVariantSecondary ?? this.onSurfaceVariantSecondary,
        surfaceContainerGreater: surfaceContainerGreater ?? this.surfaceContainerGreater,
        surfaceContainerSuperior: surfaceContainerSuperior ?? this.surfaceContainerSuperior,
        surfaceContainerPlus: surfaceContainerPlus ?? this.surfaceContainerPlus,
        surfaceContainerMaximum: surfaceContainerMaximum ?? this.surfaceContainerMaximum,
        surfaceContainerUltimate: surfaceContainerUltimate ?? this.surfaceContainerUltimate,
        onSurfaceDeadlineUnset: onSurfaceDeadlineUnset ?? this.onSurfaceDeadlineUnset,
        onSurfaceTimeBlockLbl:onSurfaceTimeBlockLbl ?? this.onSurfaceTimeBlockLbl,
        surfaceContainerDisabled: surfaceContainerDisabled??this.surfaceContainerDisabled,
        darkPrimary: darkPrimary ?? this.darkPrimary,
        notificationOverlaySuccess: notificationOverlaySuccess ?? this.notificationOverlaySuccess,
        notificationOverlayWarning: notificationOverlayWarning ?? this.notificationOverlayWarning,
        notificationOverlayError: notificationOverlayError ?? this.notificationOverlayError,
        notificationOverlayInfo: notificationOverlayInfo ?? this.notificationOverlayInfo,
        mapStyle: mapStyle ?? this.mapStyle
    );
  }

  @override
  ThemeExtension<TileThemeExtension> lerp(covariant ThemeExtension<TileThemeExtension>? other, double t) {
      if (other is! TileThemeExtension) {
        return this;
      }
      return TileThemeExtension._(
        shadowPreviewChartIconographyOuter: Color.lerp(shadowPreviewChartIconographyOuter, other.shadowPreviewChartIconographyOuter, t)!,
        shadowSecondary: Color.lerp(shadowSecondary, other.shadowSecondary, t)!,
        shadowMainInputContainer: Color.lerp(shadowMainInputContainer, other.shadowMainInputContainer, t)!,
        shadowTimeScrubMovingBall: Color.lerp(shadowTimeScrubMovingBall, other.shadowTimeScrubMovingBall, t)!,
        shadowEmptyTile: Color.lerp(shadowEmptyTile, other.shadowEmptyTile, t)!,
        shadowSignInContainer: Color.lerp(shadowSignInContainer, other.shadowSignInContainer, t)!,
        shadowPreviewChartIconographyInner: Color.lerp(shadowPreviewChartIconographyInner, other.shadowPreviewChartIconographyInner, t)!,
        shadowSearch: Color.lerp(shadowSearch, other.shadowSearch, t)!,
        onSurfaceDaySummary:  Color.lerp(onSurfaceDaySummary, other.onSurfaceDaySummary, t)!,
        onSurfaceMonthlyIcons:  Color.lerp(onSurfaceMonthlyIcons, other.onSurfaceMonthlyIcons, t)!,
        primaryContainerLow: Color.lerp(primaryContainerLow, other.primaryContainerLow, t)!,
        onSurfaceHint:Color.lerp(onSurfaceHint, other.onSurfaceHint, t)!,
        onSurfaceSecondary:Color.lerp(onSurfaceSecondary, other.onSurfaceSecondary, t)!,
        onSurfaceVariantSecondary:Color.lerp(onSurfaceVariantSecondary, other.onSurfaceVariantSecondary, t)!,
        surfaceContainerGreater:Color.lerp(surfaceContainerGreater, other.surfaceContainerGreater, t)!,
        surfaceContainerSuperior:Color.lerp(surfaceContainerSuperior, other.surfaceContainerSuperior, t)!,
        surfaceContainerPlus: Color.lerp(surfaceContainerPlus,other.surfaceContainerPlus,t)!,
        surfaceContainerMaximum: Color.lerp(surfaceContainerMaximum, other.surfaceContainerMaximum, t)!,
        surfaceContainerUltimate: Color.lerp(surfaceContainerUltimate, other.surfaceContainerUltimate, t)!,
        onSurfaceDeadlineUnset: Color.lerp(onSurfaceDeadlineUnset, other.onSurfaceDeadlineUnset, t)!,
        onSurfaceTimeBlockLbl: Color.lerp(onSurfaceTimeBlockLbl, other.onSurfaceTimeBlockLbl, t)!,
        surfaceContainerDisabled:Color.lerp(surfaceContainerDisabled, other.surfaceContainerDisabled,t)!,
        darkPrimary: Color.lerp(darkPrimary, other.darkPrimary, t)!,
        notificationOverlaySuccess: Color.lerp(notificationOverlaySuccess, other.notificationOverlaySuccess, t)!,
        notificationOverlayWarning: Color.lerp(notificationOverlayWarning, other.notificationOverlayWarning, t)!,
        notificationOverlayError: Color.lerp(notificationOverlayError, other.notificationOverlayError, t)!,
        notificationOverlayInfo: Color.lerp(notificationOverlayInfo, other.notificationOverlayInfo, t)!,
        mapStyle: other.mapStyle,
      );
    }
}
