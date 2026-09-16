import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridAlerts.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Grid-mode alert rows, laid out IN-FLOW above the grid (below the shared
/// top bar + day strip): one banner row per alert kind (C21) — conflicts →
/// the stacked conflict-cards sheet, pending RSVP → the pending-RSVP sheet.
/// Rows animate their size so a count going to zero never pops the grid.
/// List mode has its own inline alert banners inside the list, so this is
/// mounted by `DayGridPage`'s grid branch only.
///
/// Extended (>=16h / all-day) tiles are NOT surfaced here — they stay in the
/// pinned card above the grid (`DayGridPinnedHeader`).
class DayGridAlertRows extends StatelessWidget {
  static const Key conflictRowKey = ValueKey('daygrid_header_conflicts');
  static const Key rsvpRowKey = ValueKey('daygrid_header_rsvp');

  /// The day's tiles (the unfiltered day-page input, as the chip strip
  /// received it) — the alert detectors apply their own parity rules.
  final List<TilerEvent> tiles;

  const DayGridAlertRows({
    super.key,
    this.tiles = const <TilerEvent>[],
  });

  /// Total tiles across all conflict groups — the same count the chip
  /// strip / list banner show.
  static int conflictCount(List<ConflictGroup> groups) =>
      groups.fold(0, (sum, group) => sum + group.tiles.length);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final List<ConflictGroup> conflictGroups =
        DayGridAlerts.detectConflicts(tiles);
    final int conflicts = conflictCount(conflictGroups);
    final List<SubCalendarEvent> pendingRsvpTiles =
        DayGridAlerts.detectPendingRsvpTiles(tiles);
    final List<SubCalendarEvent> declinedTiles =
        DayGridAlerts.detectDeclinedTiles(tiles);

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: conflicts == 0
                ? const SizedBox(width: double.infinity)
                : _AlertRow(
                    key: conflictRowKey,
                    icon: Icons.warning_rounded,
                    color: Colors.orange.shade700,
                    label: l10n.dayGridHeaderConflictCount(conflicts),
                    action: l10n.dayGridHeaderReview,
                    onTap: () {
                      AnalysticsSignal.send('daygrid_header_conflicts_tapped',
                          additionalInfo: {'count': conflicts});
                      DayGridAlerts.showConflictModal(
                          context, conflictGroups);
                    },
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: pendingRsvpTiles.isEmpty
                ? const SizedBox(width: double.infinity)
                : _AlertRow(
                    key: rsvpRowKey,
                    icon: Icons.help_outline_rounded,
                    color: colorScheme.tertiary,
                    label: l10n.alertChipRsvp(pendingRsvpTiles.length),
                    action: l10n.dayGridHeaderRespond,
                    onTap: () {
                      AnalysticsSignal.send('daygrid_header_rsvp_tapped',
                          additionalInfo: {'count': pendingRsvpTiles.length});
                      CombinedAlertsBannerHelpers.showPendingRsvpModal(
                        context,
                        pendingRsvpTiles,
                        preview: false,
                        declinedTiles: declinedTiles,
                      );
                    },
                  ),
          ),
        ],
    );
  }
}

/// One full-width, tinted banner row: leading icon, count label, trailing
/// action text + chevron.
class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String action;
  final VoidCallback onTap;

  const _AlertRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Color.alphaBlend(
            color.withValues(alpha: 0.14), colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
