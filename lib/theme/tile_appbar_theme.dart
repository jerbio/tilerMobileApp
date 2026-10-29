import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'tile_colors.dart';

class TileAppBarTheme {
  TileAppBarTheme._();

  /// Headers blend into their page, including after content scrolls under
  /// them. Navigation, titles and status-bar icons follow the active theme.
  static AppBarTheme forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? TileColors.lightContent : TileColors.darkContent;
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: foreground, size: 24),
      actionsIconTheme: IconThemeData(color: foreground, size: 24),
      titleTextStyle: TileTextStyles.appBar.copyWith(color: foreground),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle:
          (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
    );
  }
}
