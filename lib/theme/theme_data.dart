import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_appbar_theme.dart';
import 'package:tiler_app/theme/tile_bottomnavbar_theme.dart';
import 'package:tiler_app/theme/tile_input_theme.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_time_picker_theme.dart';
import 'tile_colors.dart';
class TileThemeData {
      const TileThemeData._();
      static ThemeData getLightTheme() {
            return ThemeData(
              fontFamily: TileTextStyles.rubikFontName,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              colorScheme: ColorScheme.fromSeed(
                seedColor: TileColors.primary,
                brightness: Brightness.light,).copyWith(
                primary:TileColors.primary,
                onPrimary: TileColors.lightContent,
                primaryContainer:TileColors.primaryContainerLight.toColor(),
                onPrimaryContainer: TileColors.onPrimaryContainerLight,
                secondary: TileColors.secondaryLight,
                tertiary: TileColors.tertiary,
                tertiaryContainer:TileColors.tertiaryContainer,
                onTertiary: TileColors.lightContent,
                error:TileColors.error,
                onError: TileColors.onError,
                surface:  TileColors.surfaceLight,
                surfaceContainerLow: TileColors.lightContent,
                surfaceContainer: TileColors.surfaceContainerLight,
                surfaceContainerHigh: TileColors.surfaceContainerHighLight,
                surfaceContainerHighest: TileColors.surfaceContainerHighestLight,
                onSurface: TileColors.darkContent,
                onSurfaceVariant: TileColors.onSurfaceVariantLight,
                outline: TileColors.outlineLight,
                outlineVariant: TileColors.outlineVariantLight,
                inverseSurface: TileColors.inverseSurfaceLight,
                onInverseSurface:  TileColors.lightContent,
                scrim:TileColors.scrimColorLight,
                shadow: TileColors.shadowLight,
                inversePrimary: TileColors.inversePrimaryLight,
              ),
              extensions: <ThemeExtension<dynamic>>[
                TileThemeExtension.light,
              ],
              appBarTheme: TileAppBarTheme.theme,
              bottomNavigationBarTheme: TileBottomNavTheme.theme,
              inputDecorationTheme: TileInputTheme.inputDecorationTheme,
              textSelectionTheme: TileInputTheme.textSelectionTheme,
              timePickerTheme: TileTimePickerTheme.lightTheme

            );
      }

      static ThemeData getDarkTheme() {
            return ThemeData(
                brightness: Brightness.dark,
                fontFamily: TileTextStyles.rubikFontName,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: TileColors.primary,
                  brightness: Brightness.dark,).copyWith(
                  primary: TileColors.primary,
                  onPrimary:TileColors.lightContent,
                  primaryContainer: TileColors.primaryContainerDark.toColor(),
                  onPrimaryContainer: TileColors.onPrimaryContainerDark,
                  secondary: TileColors.secondaryDark,
                  tertiary: TileColors.tertiary,
                  tertiaryContainer:TileColors.tertiaryContainer,
                  onTertiary: TileColors.lightContent,
                  error:TileColors.error,
                  onError: TileColors.onError,
                  surface: TileColors.surfaceDark,
                  surfaceContainerLow: TileColors.surfaceContainerLowDark,
                  surfaceContainer: TileColors.surfaceContainerDark,
                  surfaceContainerHigh: TileColors.surfaceContainerHighDark,
                  surfaceContainerHighest: TileColors.surfaceContainerHighestDark,
                  onSurface: TileColors.lightContent,
                  onSurfaceVariant: TileColors.onSurfaceVariantDark ,
                  outline: TileColors.outlineDark,
                  outlineVariant: TileColors.outlineVariantDark,
                  inverseSurface: TileColors.inverseSurfaceDark,
                  onInverseSurface: TileColors.onInverseSurfaceDark,
                  shadow: TileColors.shadowDark,
                  scrim: TileColors.scrimColorDark,
                  inversePrimary: TileColors.inversePrimaryDark,
                ),
                extensions: <ThemeExtension<dynamic>>[
                  TileThemeExtension.dark,
                ],
                appBarTheme: TileAppBarTheme.theme,
                bottomNavigationBarTheme: TileBottomNavTheme.theme,
                inputDecorationTheme: TileInputTheme.inputDecorationTheme,
                textSelectionTheme: TileInputTheme.textSelectionTheme,
                timePickerTheme: TileTimePickerTheme.darkTheme

            );

      }
}
