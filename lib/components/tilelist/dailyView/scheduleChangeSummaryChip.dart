import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/util.dart';

/// "Plan updated · 2 Tiles moved · +31 min free   See changes".
///
/// Shown after Tiler changes the day; tapping "See changes" opens
/// [ScheduleChangeSheet].
class ScheduleChangeSummaryChip extends StatelessWidget {
  static const Key chipKey = Key('schedule_change_summary_chip');
  static const Key seeChangesKey = Key('schedule_change_see_changes');

  final ScheduleChangeSummary summary;
  final VoidCallback onSeeChanges;

  const ScheduleChangeSummaryChip({
    super.key,
    required this.summary,
    required this.onSeeChanges,
  });

  /// The chip's second line, e.g. "2 Tiles moved · +31 min free".
  static String details(AppLocalizations l10n, ScheduleChangeSummary summary) {
    return [
      if (summary.movedCount > 0)
        l10n.scheduleChangeTilesMoved(summary.movedCount),
      if (summary.movedToOtherDaysCount > 0)
        l10n.scheduleChangeTilesMovedToOtherDays(summary.movedToOtherDaysCount),
      if (summary.addedCount > 0)
        l10n.scheduleChangeTilesAdded(summary.addedCount),
      if (summary.removedCount > 0)
        l10n.scheduleChangeTilesRemoved(summary.removedCount),
      if (summary.travelUpdatedCount > 0)
        l10n.scheduleChangeTravelUpdated(summary.travelUpdatedCount),
      if (summary.freeMinutesGained > 0)
        l10n.scheduleChangeFreeGained(summary.freeMinutesGained),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = summary.isDayCleared
        ? l10n.scheduleChangeDayCleared
        : l10n.scheduleChangePlanUpdated;
    final detail = details(l10n, summary);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        key: chipKey,
        color: colorScheme.inverseSurface,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onInverseSurface
                                .withValues(alpha: 0.8)),
                      ),
                  ],
                ),
              ),
              TextButton(
                key: seeChangesKey,
                onPressed: onSeeChanges,
                style: TextButton.styleFrom(
                    foregroundColor: colorScheme.inversePrimary),
                child: Text(l10n.scheduleChangeSeeChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "What changed": the day's changes as a list of `before → after` rows,
/// not the resulting schedule.
class ScheduleChangeSheet extends StatelessWidget {
  final ScheduleChangeSummary summary;

  const ScheduleChangeSheet({super.key, required this.summary});

  static Future<void> show(
      BuildContext context, ScheduleChangeSummary summary) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ScheduleChangeSheet(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = _rows(context, l10n);
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l10n.scheduleChangeWhatChanged,
                  style: theme.textTheme.titleMedium),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child:
                              Text(row.$1, style: theme.textTheme.bodyMedium),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          row.$2,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (label, value) per row: one per changed Tile in day order, one per
  /// travel change, then the free-time change.
  List<(String, String)> _rows(BuildContext context, AppLocalizations l10n) {
    final materialL10n = MaterialLocalizations.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    String time(int ms) => materialL10n.formatTimeOfDay(
        TimeOfDay.fromDateTime(Utility.localDateTimeFromMs(ms)),
        alwaysUse24HourFormat: use24h);
    String date(int ms) =>
        materialL10n.formatMediumDate(Utility.localDateTimeFromMs(ms));
    String minutes(int ms) =>
        l10n.scheduleChangeMinutes(ms ~/ Duration.millisecondsPerMinute);
    String name(SubCalendarEvent? tile) {
      final value = tile?.name;
      return value == null || value.trim().isEmpty ? l10n.untitledTile : value;
    }

    final rows = <(String, String)>[];
    for (final change in summary.orderedChanges) {
      final before = change.before, after = change.after;
      switch (change.kind) {
        case TileChangeKind.moved:
        case TileChangeKind.movedAndResized:
          rows.add((
            name(after),
            '${time(before!.start!)} → ${time(after!.start!)}'
          ));
        case TileChangeKind.resized:
          rows.add((
            name(after),
            '${minutes(before!.end! - before.start!)} → '
                '${minutes(after!.end! - after.start!)}'
          ));
        case TileChangeKind.movedToOtherDay:
          rows.add((
            name(after),
            '${time(before!.start!)} → ${date(after!.start!)}'
          ));
        case TileChangeKind.movedFromOtherDay:
          rows.add((
            name(after),
            '${date(before!.start!)} → ${time(after!.start!)}'
          ));
        case TileChangeKind.added:
          rows.add(
              (name(after), l10n.scheduleChangeAdded(time(after!.start!))));
        case TileChangeKind.removed:
          rows.add((name(before), l10n.scheduleChangeRemoved));
      }
    }

    for (final travel in summary.delta.travelChanges) {
      rows.add((
        l10n.scheduleChangeTravelTo(name(travel.tile)),
        '${minutes(travel.before.inMilliseconds)} → '
            '${minutes(travel.after.inMilliseconds)}'
      ));
    }

    final delta = summary.delta;
    if (delta.freeMinutesDelta != 0) {
      rows.add((
        l10n.scheduleChangeFreeTime,
        '${l10n.scheduleChangeMinutes(delta.freeMinutesBefore)} → '
            '${l10n.scheduleChangeMinutes(delta.freeMinutesAfter)}'
      ));
    }
    return rows;
  }
}

/// "3 Tiles moving · 1 travel time updated": names a change while it plays
/// step by step, before the "Plan updated" chip takes over.
class ScheduleChangeMovingBanner extends StatelessWidget {
  static const Key bannerKey = Key('schedule_change_moving_banner');

  final ScheduleChangeSummary summary;

  const ScheduleChangeMovingBanner({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final moving = summary.movedCount + summary.movedToOtherDaysCount;
    final text = [
      if (moving > 0) l10n.scheduleChangeTilesMoving(moving),
      if (summary.travelUpdatedCount > 0)
        l10n.scheduleChangeTravelUpdated(summary.travelUpdatedCount),
    ].join(' · ');
    return Semantics(
      liveRegion: true,
      child: Material(
        key: bannerKey,
        color: colorScheme.inverseSurface,
        elevation: 4,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colorScheme.onInverseSurface),
          ),
        ),
      ),
    );
  }
}
