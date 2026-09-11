import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridBannerStrip.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// The grid-mode header that scrolls away with the day (C18): mounted as
/// `DayGridWidget.header`, so it lives in the scroll view's negative extent
/// and is revealed by pulling down. Top to bottom:
///
///  1. the full date (`Fri, Jan 15, 2027`);
///  2. an alert subtitle (`2 conflicts · 1 RSVP need attention` / `All clear`);
///  3. the compact, swipeable day strip (C23 — `DayRibbonCarousel` in
///     `compact` mode, same `DateChangeEvent` dispatch as the ribbon);
///  4. one banner row per alert kind (C21): conflicts → the stacked
///     conflict-cards sheet, pending RSVP → the pending-RSVP sheet — the
///     same modals the retired chip strip opened. Rows animate their size
///     so a count going to zero does not pop while the header is on screen.
///
/// Extended (>=16h / all-day) tiles are NOT surfaced here — they stay in the
/// pinned card above the grid (`DayGridPinnedHeader`).
class DayGridScrollHeader extends StatelessWidget {
  static const Key conflictRowKey = ValueKey('daygrid_header_conflicts');
  static const Key rsvpRowKey = ValueKey('daygrid_header_rsvp');

  /// The day the grid is showing.
  final DateTime currentDate;

  /// The day's tiles (the unfiltered day-page input, as the chip strip
  /// received it) — the alert detectors apply their own parity rules.
  final List<TilerEvent> tiles;

  const DayGridScrollHeader({
    super.key,
    required this.currentDate,
    this.tiles = const <TilerEvent>[],
  });

  /// Total tiles across all conflict groups — the same count the chip
  /// strip / list banner show.
  static int conflictCount(List<ConflictGroup> groups) =>
      groups.fold(0, (sum, group) => sum + group.tiles.length);

  /// The subtitle line: `All clear`, or the joined non-zero alert counts
  /// with a pluralized "need(s) attention".
  static String subtitle(
      AppLocalizations l10n, int conflicts, int pendingRsvps) {
    final parts = <String>[];
    if (conflicts > 0) parts.add(l10n.dayGridHeaderConflictCount(conflicts));
    if (pendingRsvps > 0) parts.add(l10n.alertChipRsvp(pendingRsvps));
    if (parts.isEmpty) return l10n.dayGridHeaderAllClear;
    return l10n.dayGridHeaderNeedAttention(
        conflicts + pendingRsvps, parts.join(' · '));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final List<ConflictGroup> conflictGroups =
        DayGridBannerStrip.detectConflicts(tiles);
    final int conflicts = conflictCount(conflictGroups);
    final List<SubCalendarEvent> pendingRsvpTiles =
        DayGridBannerStrip.detectPendingRsvpTiles(tiles);
    final List<SubCalendarEvent> declinedTiles =
        DayGridBannerStrip.detectDeclinedTiles(tiles);

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              DateFormat('EEE, MMM d, y', locale).format(currentDate),
              style: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
            child: Text(
              subtitle(l10n, conflicts, pendingRsvpTiles.length),
              style: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DayRibbonCarousel(
            currentDate,
            autoUpdateAnchorDate: false,
            topMargin: 0,
            compact: true,
          ),
          const SizedBox(height: 4),
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
                      DayGridBannerStrip.showConflictModal(
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
          const SizedBox(height: 4),
        ],
      ),
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
