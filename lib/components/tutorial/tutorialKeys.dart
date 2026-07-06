import 'package:flutter/material.dart';

/// GlobalKeys used to locate target widgets for the tutorial spotlight.
/// These are shared between AuthorizedRoute and the TutorialOverlay.
class TutorialKeys {
  TutorialKeys._();

  static final GlobalKey scheduleViewKey =
      GlobalKey(debugLabel: 'tutorialScheduleView');

  /// The chat FAB (bottom-right floating action button).
  static final GlobalKey fabKey = GlobalKey(debugLabel: 'tutorialFab');

  /// The whole bottom navigation bar (Share · Add-tile logo · Calendar).
  static final GlobalKey bottomNavKey =
      GlobalKey(debugLabel: 'tutorialBottomNav');

  /// The centre "Tiler logo" slot in the bottom bar that opens the add-tile sheet.
  static final GlobalKey bottomNavAddTileKey =
      GlobalKey(debugLabel: 'tutorialBottomNavAddTile');

  /// The top-right action cluster (Go-to-today · Search · Settings).
  static final GlobalKey topRightActionsKey =
      GlobalKey(debugLabel: 'tutorialTopRightActions');

  static final GlobalKey currentTileKey =
      GlobalKey(debugLabel: 'tutorialCurrentTile');
}
