import 'package:flutter/material.dart';

/// GlobalKeys used to locate target widgets for the tutorial spotlight.
/// These are shared between AuthorizedRoute and the TutorialOverlay.
class TutorialKeys {
  TutorialKeys._();

  static final GlobalKey scheduleViewKey =
      GlobalKey(debugLabel: 'tutorialScheduleView');
  static final GlobalKey fabKey = GlobalKey(debugLabel: 'tutorialFab');
  static final GlobalKey bottomNavKey =
      GlobalKey(debugLabel: 'tutorialBottomNav');
  static final GlobalKey bottomNavShareKey =
      GlobalKey(debugLabel: 'tutorialBottomNavShare');
  static final GlobalKey bottomNavSearchKey =
      GlobalKey(debugLabel: 'tutorialBottomNavSearch');
  static final GlobalKey bottomNavSettingsKey =
      GlobalKey(debugLabel: 'tutorialBottomNavSettings');
  static final GlobalKey bottomNavCalendarKey =
      GlobalKey(debugLabel: 'tutorialBottomNavCalendar');
  static final GlobalKey currentTileKey =
      GlobalKey(debugLabel: 'tutorialCurrentTile');
}
