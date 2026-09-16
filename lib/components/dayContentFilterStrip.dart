import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// The active-filter strip (P7 §17.2): while the content filter is not
/// `all`, a slim line under the quick actions says what is being shown —
/// *"Showing blocks only · 4 of 11"* — or, when nothing matches, *"No
/// blocks on Fri, Jan 15"* — with a **Show all** action. Nothing while the
/// filter is `all`. `AnimatedSize`-wrapped so it never pops the content.
///
/// Mounted ONCE in the shared Daily chrome so both layouts get it; the
/// counts are the shown day's tiles from [ScheduleBloc].
class DayContentFilterStrip extends StatelessWidget {
  static const Key stripKey = ValueKey('dayContentFilterStrip');
  static const Key showAllKey = ValueKey('dayContentFilterStrip_showAll');

  final DateTime currentDate;

  const DayContentFilterStrip({super.key, required this.currentDate});

  /// The shown day's RENDERABLE tiles from [state]: the same parity rule
  /// the grid and the main list apply ([DayGridPage.gridTiles] — viable,
  /// id'd, not pending/declined third-party RSVP). Non-viable tiles (needs
  /// attention / unscheduled) live in the alert rows, never on the
  /// timeline, so they must not inflate the "x of y" count.
  static List<SubCalendarEvent> dayTiles(ScheduleState state, int dayIndex) {
    List<SubCalendarEvent>? subEvents;
    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
    }
    if (subEvents == null) return const <SubCalendarEvent>[];
    final onDay = subEvents.where((tile) {
      final int? start = tile.start;
      return start != null &&
          Utility.localDateTimeFromMs(start).universalDayIndex == dayIndex;
    }).toList();
    return DayGridPage.gridTiles(onDay);
  }

  /// The strip's text for [filter] given [shown] of [total] tiles on [day];
  /// `null` for `all` (no strip).
  static String? summary(AppLocalizations l10n, DayContentFilter filter,
      {required int shown, required int total, required String day}) {
    switch (filter) {
      case DayContentFilter.all:
        return null;
      case DayContentFilter.blocks:
        return shown == 0
            ? l10n.dayFilterEmptyBlocks(day)
            : l10n.dayFilterShowingBlocks(shown, total);
      case DayContentFilter.tiles:
        return shown == 0
            ? l10n.dayFilterEmptyTiles(day)
            : l10n.dayFilterShowingTiles(shown, total);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final DayContentFilter filter = context.watch<DayContentFilterCubit>().state;
    final ScheduleState schedule = context.watch<ScheduleBloc>().state;

    Widget child = const SizedBox(width: double.infinity);
    if (filter != DayContentFilter.all) {
      final List<TilerEvent> tiles =
          dayTiles(schedule, currentDate.universalDayIndex);
      final int shown = filter.apply(tiles).length;
      final String day = DateFormat.MMMEd(
              Localizations.localeOf(context).toString())
          .format(currentDate);
      final String text =
          summary(l10n, filter, shown: shown, total: tiles.length, day: day)!;
      child = Container(
        key: stripKey,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        color: colorScheme.surfaceContainerLow,
        child: Row(
          children: [
            Icon(Icons.filter_list_rounded,
                size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              key: showAllKey,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => context.read<DayContentFilterCubit>().clear(),
              child: Text(l10n.dayFilterShowAll,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Auto-clear (P7 §17.2): when a tile that has just been ADDED to the shown
/// day would be hidden by the active filter, reset the filter to `all` and
/// say so — the addition must never vanish on arrival. Detected by
/// comparing the shown day's tile ids across consecutive schedule states
/// (so it covers tap-to-add AND tiles landed by a re-optimize, in either
/// layout). Edge-loading of *other* days never triggers it.
class DayContentFilterAutoClear extends StatefulWidget {
  final DateTime currentDate;
  final Widget child;

  const DayContentFilterAutoClear({
    super.key,
    required this.currentDate,
    required this.child,
  });

  /// Pure: the tiles of [dayIndex] present in [current] but not [previous].
  /// Empty when [previous] did not cover the day yet (an initial/edge load
  /// is not an "addition").
  static List<SubCalendarEvent> addedTiles(
      ScheduleState previous, ScheduleState current, int dayIndex) {
    final prev = DayContentFilterStrip.dayTiles(previous, dayIndex);
    if (prev.isEmpty && !coversDay(previous, dayIndex)) {
      return const <SubCalendarEvent>[];
    }
    final prevIds = prev.map((t) => t.uniqueId).toSet();
    return DayContentFilterStrip.dayTiles(current, dayIndex)
        .where((t) => !prevIds.contains(t.uniqueId))
        .toList();
  }

  /// Whether [state]'s lookup window already includes [dayIndex].
  static bool coversDay(ScheduleState state, int dayIndex) {
    final lookup = state is ScheduleLoadedState
        ? state.lookupTimeline
        : state is ScheduleEvaluationState
            ? state.lookupTimeline
            : state is ScheduleLoadingState
                ? state.previousLookupTimeline
                : null;
    if (lookup == null) return false;
    final int ms = Utility.getTimeFromIndex(dayIndex).millisecondsSinceEpoch;
    return (lookup.start ?? 0) <= ms && ms < (lookup.end ?? 0);
  }

  @override
  State<DayContentFilterAutoClear> createState() =>
      _DayContentFilterAutoClearState();
}

class _DayContentFilterAutoClearState extends State<DayContentFilterAutoClear> {
  /// The last schedule state seen — the baseline additions are diffed from.
  ScheduleState? _previous;

  @override
  void initState() {
    super.initState();
    _previous = context.read<ScheduleBloc>().state;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        final ScheduleState? previous = _previous;
        _previous = state;
        final filterCubit = context.read<DayContentFilterCubit>();
        if (previous == null || filterCubit.state == DayContentFilter.all) {
          return;
        }
        final added = DayContentFilterAutoClear.addedTiles(
            previous, state, widget.currentDate.universalDayIndex);
        if (added.isEmpty) return;
        if (filterCubit.clearIfHides(added)) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            content: Text(l10n.dayFilterAutoCleared),
            duration: const Duration(seconds: 3),
          ));
        }
      },
      child: widget.child,
    );
  }
}
