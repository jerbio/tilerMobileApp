import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The number of steps in the Tile Preferences tour.
///
/// This MUST stay in sync with the list returned by
/// [buildTilePreferencesTourSteps]. The tile preferences tour tests assert
/// `buildTilePreferencesTourSteps(context).length ==
/// kTilePreferencesTourStepCount`.
const int kTilePreferencesTourStepCount = 3;

/// GlobalKeys used to locate target widgets for the Tile Preferences tour
/// spotlight (product-tour-onboarding-redesign.md, section 3.4).
///
/// One key per section card on the Tile Preferences page. These are shared
/// between [TilePreferencesScreen] and the [TutorialOverlay] rendering the
/// tour steps. The template's Save button is deliberately not an anchor:
/// it only renders once the user has unsaved changes, so it does not exist
/// when the tour runs.
class TilePreferencesTourKeys {
  TilePreferencesTourKeys._();

  /// The transport card (biking / transit / driving).
  static final GlobalKey transportCardKey =
      GlobalKey(debugLabel: 'tilePreferencesTourTransportCard');

  /// The time-restrictions card ("Set work hours" / "Set personal hours").
  static final GlobalKey timeRestrictionsCardKey =
      GlobalKey(debugLabel: 'tilePreferencesTourTimeRestrictionsCard');

  /// The block-out hours card (bed time + sleep duration).
  static final GlobalKey blockOutCardKey =
      GlobalKey(debugLabel: 'tilePreferencesTourBlockOutCard');
}

/// Builds the ordered list of steps for the Tile Preferences tour.
///
/// Exposed at the top level (rather than being buried in a widget) so
/// tests can verify that every step still points at a live section card
/// and that the tour hasn't drifted from the actual page.
List<TutorialStep> buildTilePreferencesTourSteps(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    // Step 1: Transport card
    TutorialStep(
      id: 'transport',
      targetKey: TilePreferencesTourKeys.transportCardKey,
      title: l10n.tutorialStepTilePrefsTransportTitle,
      body: l10n.tutorialStepTilePrefsTransportBody,
      headerIcon: Icons.directions_outlined,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),

    // Step 2: Work / Personal hours card
    TutorialStep(
      id: 'work_personal_hours',
      targetKey: TilePreferencesTourKeys.timeRestrictionsCardKey,
      title: l10n.tutorialStepTilePrefsHoursTitle,
      body: l10n.tutorialStepTilePrefsHoursBody,
      headerIcon: Icons.schedule_outlined,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),

    // Step 3: Block-out hours card
    TutorialStep(
      id: 'block_out_hours',
      targetKey: TilePreferencesTourKeys.blockOutCardKey,
      title: l10n.tutorialStepTilePrefsBlockOutTitle,
      body: l10n.tutorialStepTilePrefsBlockOutBody,
      headerIcon: Icons.bedtime_outlined,
      tooltipPosition: TooltipPosition.above,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 4,
    ),
  ];
}
