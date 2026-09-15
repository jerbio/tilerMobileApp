import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The number of steps in the settings tour.
///
/// This MUST stay in sync with the list returned by
/// [buildSettingsTourSteps]. The settings tour tests assert
/// `buildSettingsTourSteps(context).length == kSettingsTourStepCount`.
const int kSettingsTourStepCount = 1;

/// GlobalKeys used to locate target widgets for the settings tour
/// spotlight (product-tour-onboarding-redesign.md, section 3.4).
///
/// The settings tour is a single-step pointer: it exists only so users
/// discover the Tile Preferences page, where the tour that actually
/// teaches AI preferences lives (`tours/tilePreferencesTour.dart`).
class SettingsTourKeys {
  SettingsTourKeys._();

  /// The "Tile Preferences" row in the settings list.
  static final GlobalKey tilePreferencesTileKey =
      GlobalKey(debugLabel: 'settingsTourTilePreferencesTile');
}

/// Builds the ordered list of steps for the settings tour.
///
/// Exposed at the top level (rather than being buried in a widget) so
/// tests can verify that the step still points at a live settings row.
List<TutorialStep> buildSettingsTourSteps(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    // Step 1 (only): point at the Tile Preferences row
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
  ];
}
