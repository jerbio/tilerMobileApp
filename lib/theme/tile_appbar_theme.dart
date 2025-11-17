import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'tile_colors.dart';

class TileAppBarTheme {
  TileAppBarTheme._();

  static const AppBarTheme  theme = AppBarTheme(
    backgroundColor: TileColors.primary,
    iconTheme: IconThemeData(color: TileColors.lightContent),
    actionsIconTheme: IconThemeData(color: TileColors.lightContent),
    foregroundColor: TileColors.lightContent,
    titleTextStyle: TileTextStyles.appBar,
    elevation: 0,
    centerTitle: true,
  );
}