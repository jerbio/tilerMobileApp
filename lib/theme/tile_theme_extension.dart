import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class TileThemeExtension extends ThemeExtension<TileThemeExtension>{
  final Color shadowLowest;
  final Color shadowLow;
  final Color shadowBase;
  final Color shadowHigh;
  final Color shadowHigher;
  final Color shadowHighest;
  final Color shadowInverse;
  final Color shadowInverseVariant;
  final Color onSurfaceVariantLow;
  final Color onSurfaceVariantHigh;
  final Color onSurfaceVariantHighest;
  final Color onSurfaceTertiary;
  final Color onSurfaceQuaternary;
  final Color primaryContainerLow;
  final Color surfaceContainerGreater;
  final Color surfaceContainerPlus;
  final Color surfaceContainerMaximum;
  final Color surfaceContainerUltimate;
  final Color surfaceContainerDisabled;
  final Color onSurfaceHint;
  final Color darkPrimary;
  final Color onFixedColors;
  final String? mapStyle;
  const TileThemeExtension._(
      {
        required this.shadowLow,
        required this.shadowBase,
        required this.shadowHigh,
        required this.shadowHigher,
        required this.shadowHighest,
        required this.shadowLowest,
        required this.shadowInverse,
        required this.shadowInverseVariant,
        required this.primaryContainerLow,
        required this.onSurfaceVariantLow,
        required this.onSurfaceVariantHigh,
        required this.onSurfaceVariantHighest,
        required this.surfaceContainerGreater,
        required this.surfaceContainerPlus,
        required this.surfaceContainerMaximum,
        required this.surfaceContainerUltimate,
        required this.onSurfaceHint,
        required this.surfaceContainerDisabled,
        required this.onSurfaceTertiary,
        required this.onSurfaceQuaternary,
        required this.darkPrimary,
        required this.onFixedColors,
        required this.mapStyle,

      });
  static final TileThemeExtension light = TileThemeExtension._(
      shadowLowest:TileColors.shadowLowestLight,
      shadowLow: TileColors.shadowLowLight,
      shadowBase: TileColors.shadowBaseLight,
      shadowHigh: TileColors.shadowHighLight,
      shadowHigher: TileColors.shadowHigherLight,
      shadowHighest: TileColors.shadowHighestLight,
      shadowInverse: TileColors.shadowInverseLight,
      shadowInverseVariant: TileColors.shadowInverseVariantLight,
      primaryContainerLow: TileColors.primaryContainerLowLight,
      onSurfaceVariantLow: TileColors.onSurfaceVariantLowLight,
      onSurfaceVariantHigh: TileColors.onSurfaceVariantHighLight,
      onSurfaceVariantHighest: TileColors.onSurfaceVariantHighestLight,
      onSurfaceTertiary: TileColors.onSurfaceTertiaryLight,
      onSurfaceQuaternary:  TileColors.onSurfaceQuaternaryLight,
      surfaceContainerGreater:TileColors.surfaceContainerGreaterLight,
      surfaceContainerPlus: TileColors.surfaceContainerPlusLight,
      surfaceContainerMaximum:TileColors.surfaceContainerMaximumLight,
      surfaceContainerUltimate:TileColors.surfaceContainerUltimateLight,
      onSurfaceHint:TileColors.onSurfaceHintLight,
      surfaceContainerDisabled: TileColors.surfaceContainerDisabledLight,
      darkPrimary:TileColors.darkPrimary,
      onFixedColors: TileColors.lightContent,
      mapStyle: null,
  );

  static final TileThemeExtension dark = TileThemeExtension._(
      shadowLowest: TileColors.shadowLowestDark,
      shadowLow: TileColors.shadowLowDark,
      shadowBase: TileColors.shadowBaseDark,
      shadowHigh: TileColors.shadowHighDark,
      shadowHigher: TileColors.shadowHigherDark,
      shadowHighest: TileColors.shadowHighestDark,
      shadowInverse: TileColors.shadowInverseDark,
      shadowInverseVariant: TileColors.shadowInverseVariantDark,
      primaryContainerLow: TileColors.primaryContainerLowDark,
      onSurfaceVariantLow: TileColors.onSurfaceVariantLowDark,
      onSurfaceVariantHigh: TileColors.onSurfaceVariantHighDark,
      onSurfaceVariantHighest: TileColors.onSurfaceVariantHighestDark,
    onSurfaceTertiary: TileColors.onSurfaceTertiaryDark,
      onSurfaceQuaternary: TileColors.onSurfaceQuaternaryDark,
      surfaceContainerGreater:TileColors.surfaceContainerGreaterDark,
      surfaceContainerPlus: TileColors.surfaceContainerPlusDark,
      surfaceContainerMaximum:TileColors.surfaceContainerMaximumDark,
      surfaceContainerUltimate:TileColors.surfaceContainerUltimateDark,
      onSurfaceHint: TileColors.onSurfaceHintDark,
      surfaceContainerDisabled: TileColors.surfaceContainerDisabledDark,
      darkPrimary:TileColors.darkPrimary,
      onFixedColors: TileColors.lightContent,
      mapStyle:TileColors.darkMapStyle,

  );

  @override
  ThemeExtension<TileThemeExtension> copyWith({
    Color? shadowLowest,
    Color? shadowLow,
    Color? shadowBase,
    Color? shadowHigh,
    Color? shadowHigher,
    Color? shadowHighest,
    Color? shadowInverse,
    Color? shadowInverseVariant,
    Color? primaryContainerLow,
    Color? onSurfaceVariantLow,
    Color? onSurfaceVariantHigh,
    Color? onSurfaceVariantHighest,
    Color?  onSurfaceTertiary,
    Color? onSurfaceQuaternary,
    Color? surfaceContainerGreater,
    Color? surfaceContainerMaximum,
    Color? surfaceContainerPlus,
    Color? surfaceContainerUltimate,
    Color? onSurfaceHint,
    Color? surfaceContainerDisabled,
    Color? darkPrimary,
    Color?onFixedColors,
    String? mapStyle
  }) {
    return TileThemeExtension._(
        shadowLow: shadowLow ?? this.shadowLow,
        shadowBase: shadowBase ?? this.shadowBase,
        shadowHigh: shadowHigh ?? this.shadowHigh,
        shadowHigher: shadowHigher ?? this.shadowHigher,
        shadowHighest: shadowHighest ??this.shadowHighest,
        shadowLowest: shadowLowest ?? this.shadowLowest,
        shadowInverse: shadowInverse ?? this.shadowInverse,
        shadowInverseVariant: shadowInverseVariant ?? this.shadowInverseVariant,
        primaryContainerLow: primaryContainerLow  ?? this.primaryContainerLow,
        onSurfaceVariantLow: onSurfaceVariantLow ?? this.onSurfaceVariantLow,
        onSurfaceVariantHigh: onSurfaceVariantHigh ?? this.onSurfaceVariantHigh,
        onSurfaceVariantHighest: onSurfaceVariantHighest ?? this.onSurfaceVariantHighest,
        onSurfaceTertiary: onSurfaceTertiary ?? this.onSurfaceTertiary,
        onSurfaceQuaternary: onSurfaceQuaternary ?? this.onSurfaceQuaternary,
        surfaceContainerGreater: surfaceContainerGreater ?? this.surfaceContainerGreater,
        surfaceContainerMaximum: surfaceContainerMaximum ?? this.surfaceContainerMaximum,
        surfaceContainerPlus: surfaceContainerPlus ?? this.surfaceContainerPlus,
        surfaceContainerUltimate: surfaceContainerUltimate ?? this.surfaceContainerUltimate,
        onSurfaceHint: onSurfaceHint ?? this.onSurfaceHint,
        surfaceContainerDisabled: surfaceContainerDisabled??this.surfaceContainerDisabled,
        darkPrimary: darkPrimary ?? this.darkPrimary,
        onFixedColors: onFixedColors ??  this.onFixedColors,
        mapStyle: mapStyle ?? this.mapStyle
    );
  }

  @override
  ThemeExtension<TileThemeExtension> lerp(covariant ThemeExtension<TileThemeExtension>? other, double t) {
      if (other is! TileThemeExtension) {
        return this;
      }
      return TileThemeExtension._(
        shadowLow: Color.lerp(shadowLow, other.shadowLow, t)!,
        shadowBase: Color.lerp(shadowBase, other.shadowBase, t)!,
        shadowHigh: Color.lerp(shadowHigh, other.shadowHigh, t)!,
        shadowHigher: Color.lerp(shadowHigher, other.shadowHigher, t)!,
        shadowHighest: Color.lerp(shadowHighest, other.shadowHighest, t)!,
        shadowLowest: Color.lerp(shadowLowest, other.shadowLowest, t)!,
        shadowInverse: Color.lerp(shadowInverse, other.shadowInverse, t)!,
        shadowInverseVariant: Color.lerp(shadowInverseVariant, other.shadowInverseVariant, t)!,
        onSurfaceVariantLow:  Color.lerp(onSurfaceVariantLow, other.onSurfaceVariantLow, t)!,
        onSurfaceVariantHigh:  Color.lerp(onSurfaceVariantHigh, other.onSurfaceVariantHigh, t)!,
        onSurfaceVariantHighest:  Color.lerp(onSurfaceVariantHighest, other.onSurfaceVariantHighest, t)!,
        primaryContainerLow: Color.lerp(primaryContainerLow, other.primaryContainerLow, t)!,
        onSurfaceTertiary:Color.lerp(onSurfaceTertiary, other.onSurfaceTertiary, t)!,
        onSurfaceQuaternary:Color.lerp(onSurfaceQuaternary, other.onSurfaceQuaternary, t)!,
        surfaceContainerGreater:Color.lerp(surfaceContainerGreater, other.surfaceContainerGreater, t)!,
        surfaceContainerMaximum: Color.lerp(surfaceContainerMaximum, other.surfaceContainerMaximum, t)!,
        surfaceContainerPlus: Color.lerp(surfaceContainerPlus,other.surfaceContainerPlus,t)!,
        surfaceContainerUltimate: Color.lerp(surfaceContainerUltimate, other.surfaceContainerUltimate, t)!,
        onSurfaceHint: Color.lerp(onSurfaceHint, other.onSurfaceHint, t)!,
        surfaceContainerDisabled:Color.lerp(surfaceContainerDisabled, other.surfaceContainerDisabled,t)!,
        darkPrimary: Color.lerp(darkPrimary, other.darkPrimary, t)!,
        onFixedColors: Color.lerp(onFixedColors, other.onFixedColors, t)!,
        mapStyle: other.mapStyle,
      );
    }
}
