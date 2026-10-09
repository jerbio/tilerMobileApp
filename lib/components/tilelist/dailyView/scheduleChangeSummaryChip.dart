import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeBeforeAfter.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/theme/tile_colors.dart';
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
  static String details(BuildContext context, ScheduleChangeSummary summary) {
    final l10n = AppLocalizations.of(context)!;
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
        l10n.scheduleChangeFreeGained(
            Duration(minutes: summary.freeMinutesGained)
                .toHumanLocalized(context)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chipColors = ScheduleChipColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = summary.isDayCleared
        ? l10n.scheduleChangeDayCleared
        : l10n.scheduleChangePlanUpdated;
    final detail = details(context, summary);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        key: chipKey,
        color: chipColors.background,
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
                        color: chipColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                            color: chipColors.text.withValues(alpha: 0.8)),
                      ),
                  ],
                ),
              ),
              TextButton(
                key: seeChangesKey,
                onPressed: onSeeChanges,
                style: TextButton.styleFrom(foregroundColor: chipColors.action),
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
/// or the whole day before and after side by side.
class ScheduleChangeSheet extends StatefulWidget {
  final ScheduleChangeSummary summary;

  const ScheduleChangeSheet({super.key, required this.summary});

  static const Key changesTabKey = Key('schedule_change_tab_changes');
  static const Key beforeAfterTabKey = Key('schedule_change_tab_before_after');

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
  State<ScheduleChangeSheet> createState() => _ScheduleChangeSheetState();
}

class _ScheduleChangeSheetState extends State<ScheduleChangeSheet> {
  bool _beforeAfter = false;

  ScheduleChangeSummary get summary => widget.summary;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.scheduleChangeTabChanges,
                          key: ScheduleChangeSheet.changesTabKey)),
                  ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.scheduleChangeTabBeforeAfter,
                          key: ScheduleChangeSheet.beforeAfterTabKey)),
                ],
                selected: {_beforeAfter},
                onSelectionChanged: (selection) =>
                    setState(() => _beforeAfter = selection.first),
              ),
            ),
            if (_beforeAfter)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: ScheduleChangeBeforeAfter(summary: summary),
                ),
              )
            else
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
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
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
    String minutes(int ms) => _duration(context, l10n, ms);
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
        '${minutes(delta.freeMinutesBefore * Duration.millisecondsPerMinute)} → '
            '${minutes(delta.freeMinutesAfter * Duration.millisecondsPerMinute)}'
      ));
    }
    return rows;
  }

  /// A duration in the app's short, localized form ("45m", "5h 39m"; "45
  /// min", "5 Std 39 min" in German), the same everywhere it appears.
  static String _duration(
          BuildContext context, AppLocalizations l10n, int ms) =>
      Duration(milliseconds: ms).toHumanLocalized(context);
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
    final chipColors = ScheduleChipColors.of(context);
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
        color: chipColors.background,
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
                ?.copyWith(color: chipColors.text),
          ),
        ),
      ),
    );
  }
}

/// Solid colours for the "Plan updated" chip and the "N Tiles moving"
/// banner: a dark chip in the light theme and a light one in the dark
/// theme, like a snackbar. Set here rather than taken from the theme's
/// inverse colours, which are translucent in the light theme (content
/// behind the chip showed through and its action was unreadable).
class ScheduleChipColors {
  final Color background;
  final Color text;
  final Color action;

  const ScheduleChipColors._(this.background, this.text, this.action);

  static const ScheduleChipColors _light = ScheduleChipColors._(
      Color(0xFF2B2E36), Color(0xFFFFFFFF), TileColors.onPrimaryContainerDark);
  static const ScheduleChipColors _dark = ScheduleChipColors._(
      TileColors.inverseSurfaceDark,
      TileColors.onInverseSurfaceDark,
      // The accent, darkened to read on the light chip (the plain accent
      // is only about 3:1 against it).
      Color(0xFFB3002D));

  static ScheduleChipColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
