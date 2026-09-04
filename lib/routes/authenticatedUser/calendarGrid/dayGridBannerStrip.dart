// DayGrid P1 step 1.7 (C3) — the compact alert banner strip for grid mode.
//
// Reuses the list-mode detectors (ConflictGroup.detectGroups,
// ExtendedTilesBanner.detectExtendedTiles,
// PendingRsvpBanner.detectPendingRsvpTiles) and surfaces them as a single
// condensed chip row via CombinedAlertsBanner(inline: true). Chip taps open
// the list-mode modals: stacked conflict cards, ExtendedTilesModal,
// PendingRsvpModal. Hidden (nothing renders) when the day is clean.
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Compact grid-mode alert strip (step 1.7, C3).
///
/// Renders nothing when [tiles] carry no conflicts, extended (>=16h /
/// all-day) tiles, or pending/declined RSVP tiles.
class DayGridBannerStrip extends StatelessWidget {
  final List<TilerEvent> tiles;

  const DayGridBannerStrip({
    super.key,
    this.tiles = const <TilerEvent>[],
  });

  /// Conflict detection — mirrors the list-mode input rules
  /// (EnhancedTileBatch's rendered-tile set: no >=16h, no declined, no
  /// pending-RSVP, viable tiles with an id) and delegates to
  /// [ConflictGroup.detectGroups].
  static List<ConflictGroup> detectConflicts(List<TilerEvent> tiles) {
    const int minDurationMs = 16 * 60 * 60 * 1000;
    final regularTiles = tiles.where((tile) {
      if (tile is SubCalendarEvent && tile.start != null && tile.end != null) {
        return (tile.end! - tile.start!) < minDurationMs;
      }
      return true;
    }).toList();
    final conflictInput = regularTiles.whereType<SubCalendarEvent>().where(
        (tile) =>
            tile.id != null &&
            (tile.isViable ?? true) &&
            tile.rsvp != RsvpStatus.declined &&
            tile.rsvp != RsvpStatus.needsAction &&
            tile.rsvp != RsvpStatus.tentative);
    return ConflictGroup.detectGroups(conflictInput.toList());
  }

  /// Extended (>=16h) tiles — the list-mode detector verbatim.
  static List<SubCalendarEvent> detectExtendedTiles(List<TilerEvent> tiles) {
    return ExtendedTilesBanner.detectExtendedTiles(tiles);
  }

  /// Pending-RSVP tiles — the list-mode detector verbatim.
  static List<SubCalendarEvent> detectPendingRsvpTiles(List<TilerEvent> tiles) {
    return PendingRsvpBanner.detectPendingRsvpTiles(tiles);
  }

  /// Third-party declined tiles (list-mode parity rule).
  static List<SubCalendarEvent> detectDeclinedTiles(List<TilerEvent> tiles) {
    return tiles.whereType<SubCalendarEvent>().where((tile) {
      return !tile.isFromTiler && tile.rsvp == RsvpStatus.declined;
    }).toList();
  }

  /// Stacked-conflict-cards modal for the conflict chip. List mode renders
  /// the cards inline in the timeline; grid mode surfaces them here.
  static Future<void> showConflictModal(
      BuildContext context, List<ConflictGroup> conflictGroups) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConflictModal(conflictGroups: conflictGroups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conflictGroups = detectConflicts(tiles);
    final extendedTiles = detectExtendedTiles(tiles);
    final pendingRsvpTiles = detectPendingRsvpTiles(tiles);
    final declinedTiles = detectDeclinedTiles(tiles);

    if (conflictGroups.isEmpty &&
        extendedTiles.isEmpty &&
        pendingRsvpTiles.isEmpty &&
        declinedTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CombinedAlertsBanner(
        inline: true,
        conflictGroups: conflictGroups,
        onConflictTap: () => showConflictModal(context, conflictGroups),
        extendedTiles: extendedTiles,
        onExtendedTap: () =>
            CombinedAlertsBannerHelpers.showExtendedTilesModal(
                context, extendedTiles, preview: false),
        pendingRsvpTiles: pendingRsvpTiles,
        declinedTiles: declinedTiles,
        onRsvpTap: () => CombinedAlertsBannerHelpers.showPendingRsvpModal(
          context,
          pendingRsvpTiles,
          preview: false,
          declinedTiles: declinedTiles,
        ),
      ),
    );
  }
}

/// Bottom sheet listing each conflict group as stacked conflict cards
/// (same pattern as [ExtendedTilesModal]).
class _ConflictModal extends StatelessWidget {
  final List<ConflictGroup> conflictGroups;

  const _ConflictModal({required this.conflictGroups});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final totalTiles =
        conflictGroups.fold(0, (sum, group) => sum + group.tiles.length);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.conflictingTiles(totalTiles),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // One stacked-cards block per conflict group
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final group in conflictGroups) ...[
                  // Card taps are no-ops here: the list-mode default would
                  // navigate to EditTile, which needs the tile blocs this
                  // bottom sheet does not provide.
                  StackedConflictCards(
                    conflictGroup: group,
                    onTileTap: (_) {},
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}