import 'package:flutter/material.dart';

import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/whatIfSummaryModel.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

/// The edit-tile "what this change affects" sheet.
///
/// The title (and the affected-tile count) is **pinned**: only the list
/// scrolls under it. Affected tiles are tiered by day — at most
/// [WhatIfSummary.maxDays] dated days, the rest collapsed into a tappable
/// "+N more days" line that expands to the full list — with the
/// unplaceable overflow tiles in a trailing group. Every row carries its start–end time, and high-priority tiles get
/// their own treatment (accent bar, priority chip) so they read first.
class WhatIfSummarySheet extends StatefulWidget {
  static const Key sheetKey = ValueKey('editWhatIfSheet');
  static const Key titleKey = ValueKey('editWhatIfSheetTitle');
  static const Key moreDaysKey = ValueKey('editWhatIfSheetMoreDays');

  final WhatIfSummary summary;

  const WhatIfSummarySheet({super.key, required this.summary});

  static Key dayHeaderKey(int index) => ValueKey('editWhatIfDay_$index');
  static Key rowKey(String tileId) => ValueKey('editWhatIfRow_$tileId');

  @override
  State<WhatIfSummarySheet> createState() => _WhatIfSummarySheetState();
}

class _WhatIfSummarySheetState extends State<WhatIfSummarySheet> {
  /// Set by tapping the "+N more days" line: the list then shows every
  /// dated group instead of the first [WhatIfSummary.maxDays].
  bool _expanded = false;

  WhatIfSummary get summary => widget.summary;

  /// The count is of everything the change affects — never just the
  /// currently visible tiers.
  int get _affectedCount =>
      summary.allDays.fold<int>(0, (sum, g) => sum + g.entries.length) +
      (summary.undated?.entries.length ?? 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bool showMore = summary.hiddenDayCount > 0 && !_expanded;
    final List<WhatIfDayGroup> groups = <WhatIfDayGroup>[
      ...(_expanded ? summary.allDays : summary.days),
      if (summary.undated != null) summary.undated!,
    ];

    return SafeArea(
      key: WhatIfSummarySheet.sheetKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned: the header never scrolls away with the list.
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.editTileWhatIfSheetTitle,
                  key: WhatIfSummarySheet.titleKey,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.editTileWhatIfAffectedCount(_affectedCount),
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: groups.length + (showMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= groups.length) {
                  // Tap to extend the list to every remaining day.
                  return InkWell(
                    key: WhatIfSummarySheet.moreDaysKey,
                    onTap: () => setState(() => _expanded = true),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            l10n.editTileWhatIfMoreDays(
                                summary.hiddenDayCount),
                            style: textTheme.bodySmall?.copyWith(
                                color: tokens.brand,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more,
                              size: 16, color: tokens.brand),
                        ],
                      ),
                    ),
                  );
                }
                return _DayGroup(
                  group: groups[index],
                  headerKey: WhatIfSummarySheet.dayHeaderKey(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One day tier: a day header followed by its affected tiles.
class _DayGroup extends StatelessWidget {
  final WhatIfDayGroup group;
  final Key headerKey;

  const _DayGroup({required this.group, required this.headerKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final String label = group.isUndated
        ? l10n.editTileWhatIfUnplaced
        : group.day!.humanDate(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            label.toUpperCase(),
            key: headerKey,
            style: textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600),
          ),
        ),
        for (final WhatIfEntry entry in group.entries) _EntryRow(entry: entry),
      ],
    );
  }
}

/// One affected tile: name, start–end, impact, and a high-priority
/// treatment (red accent bar + chip) when it applies.
class _EntryRow extends StatelessWidget {
  final WhatIfEntry entry;

  const _EntryRow({required this.entry});

  String _timeRange(BuildContext context) {
    final DateTime? start = entry.start;
    final DateTime? end = entry.end;
    if (start == null) return '';
    final localizations = MaterialLocalizations.of(context);
    String fmt(DateTime t) =>
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(t));
    return end == null ? fmt(start) : '${fmt(start)} – ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool high = entry.isHighPriority;
    final Color accent =
        high ? TileColors.highPriority : (entry.tile.color ?? tokens.brand);
    final String impact = entry.impact == WhatIfImpact.late
        ? l10n.editTileWhatIfLate
        : l10n.editTileWhatIfOverflow;
    final String time = _timeRange(context);

    return Container(
      key: WhatIfSummarySheet.rowKey(entry.tile.id ?? entry.tile.name ?? ''),
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      decoration: BoxDecoration(
        // High priority reads as its own surface, not just a dot.
        color: high
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.10), colorScheme.surface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Accent: a bar for high priority, the tile's dot otherwise.
          high
              ? Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(Icons.circle, size: 12, color: accent),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.tile.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                high ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                    if (high) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.highPriorityTrunc,
                          style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  time.isEmpty ? impact : '$time · $impact',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
