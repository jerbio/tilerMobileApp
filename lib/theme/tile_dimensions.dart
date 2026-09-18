import 'package:flutter/material.dart';

class TileDimensions {
  TileDimensions._();

  static const double tileHeight = 300;

  /// Fixed, compact height for a list-view tile. Each list tile is capped to
  /// this height (name + time range only) so noticeably more tiles fit on
  /// screen; tapping one opens the detail bottom sheet (playback + time scrub).
  /// A single named constant so the density is easy to nudge.
  static const double compactListTileHeight = 72;

  /// Height of a compact tile that is **currently active** (the current time
  /// falls within it): the two-line header plus the ~30px time-scrub strip, so
  /// the "now" tile is easy to spot in the list.
  static const double compactListTileHeightActive = 112;

  static const double tileWidthRatio = 0.85;
  static const double tileIconSize = 12;
  static const double borderRadius = 12;
  static const double inputWidthFactor = 0.85;
  static const double widthRatio = 0.85;
  static const double proceedAndCancelButtonWidth = 60;
  static const double textFontSize = 25;
  static const double inputFontSize = 20;
  static const double daySummarySize = 30;
  static const double inputHeight = 60;
  static const double timeOfDayCellWidth = 35;
  static const double thickness = 1.0;
  static const double defaultCardElevation = 5.0;
  static const double bottomPortraitPadding = 200;
  static const double bottomLandscapePadding = 150;
  static SizedBox bottomPortraitPaddingForTileBatchListOfTiles =
      SizedBox(height: bottomPortraitPadding);
  static SizedBox bottomLandScapePaddingForTileBatchListOfTiles =
      SizedBox(height: bottomLandscapePadding);
  static Radius inputFieldRadius = const Radius.circular(50.0);
  static BorderRadius inputFieldBorderRadius =
      BorderRadius.all(inputFieldRadius);
}
