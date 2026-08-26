import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The number of steps in the settings tour.
///
/// This MUST stay in sync with the list returned by
/// [buildSettingsTourSteps]. The settings tour tests assert
/// `buildSettingsTourSteps(context).length == kSettingsTourStepCount`.
const int kSettingsTourStepCount = 4;

/// GlobalKeys used to locate target widgets for the settings tour
/// spotlight (product-tour-onboarding-redesign.md, section 3.4).
///
/// One key per settings list row the tour anchors to. These are shared
/// between [Settings] and the [TutorialOverlay] rendering the settings
/// tour steps.
class SettingsTourKeys {
  SettingsTourKeys._();

  /// The "Account info" row in the settings list.
  static final GlobalKey accountInfoTileKey =
      GlobalKey(debugLabel: 'settingsTourAccountInfoTile');

  /// The "Tile Preferences" row in the settings list.
  static final GlobalKey tilePreferencesTileKey =
      GlobalKey(debugLabel: 'settingsTourTilePreferencesTile');

  /// The "Notifications Preferences" row in the settings list.
  static final GlobalKey notificationsTileKey =
      GlobalKey(debugLabel: 'settingsTourNotificationsTile');

  /// The "Connections" row in the settings list.
  static final GlobalKey connectionsTileKey =
      GlobalKey(debugLabel: 'settingsTourConnectionsTile');
}

/// Builds the ordered list of steps for the settings tour.
///
/// Exposed at the top level (rather than being buried in a widget) so
/// tests can verify that every step still points at a live settings row
/// and that the tour hasn't drifted from the actual settings list.
List<TutorialStep> buildSettingsTourSteps(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    // Step 1: Account Info row
    TutorialStep(
      id: 'account_info',
      targetKey: SettingsTourKeys.accountInfoTileKey,
      title: l10n.tutorialStepSettingsAccountTitle,
      body: l10n.tutorialStepSettingsAccountBody,
      headerIcon: Icons.account_circle_outlined,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),

    // Step 2: Tile Preferences row
    TutorialStep(
      id: 'tile_preferences',
      targetKey: SettingsTourKeys.tilePreferencesTileKey,
      title: l10n.tutorialStepSettingsTilesTitle,
      body: l10n.tutorialStepSettingsTilesBody,
      headerIcon: Icons.style,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),

    // Step 3: Notifications row
    TutorialStep(
      id: 'notifications',
      targetKey: SettingsTourKeys.notificationsTileKey,
      title: l10n.tutorialStepSettingsNotificationsTitle,
      body: l10n.tutorialStepSettingsNotificationsBody,
      headerIcon: Icons.notifications_outlined,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),

    // Step 4: Connections row
    TutorialStep(
      id: 'connections',
      targetKey: SettingsTourKeys.connectionsTileKey,
      title: l10n.tutorialStepSettingsConnectionsTitle,
      body: l10n.tutorialStepSettingsConnectionsBody,
      headerIcon: Icons.link,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),
  ];
}