import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/quickActionChipsRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/todayStats.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/util.dart';

/// The Daily quick actions — **Show route** and **Re-optimize** — plus the
/// schedule loading bar, laid out in the shared Daily chrome (under the day
/// strip) so BOTH layouts (list and grid) get them from ONE place.
///
/// Always present (constant height), so swiping between days never changes
/// the height of the chrome above the content. Show route opens
/// [TodaysRoutePage] for the SHOWN day's viable tiles (read from
/// [ScheduleBloc]); Re-optimize dispatches [ReviseScheduleEvent] — the same
/// actions the list's sticky header used to carry.
class DayQuickActionsRow extends StatelessWidget {
  static const Key showRouteKey = ValueKey('dayQuickActions_showRoute');
  static const Key reOptimizeKey = ValueKey('dayQuickActions_reOptimize');

  /// The day the route is built for.
  final DateTime currentDate;

  /// Read-only hosts (TileCast preview) render the chips disabled.
  final bool preview;

  const DayQuickActionsRow({
    super.key,
    required this.currentDate,
    this.preview = false,
  });

  /// The chips row (~48) + the 3px loading bar.
  static const double height = QuickActionChipsRow.height + 3;

  /// The shown day's viable tiles from the schedule state (pure so it can
  /// be unit-tested): any state that carries sub-events, filtered to
  /// [dayIndex].
  static List<SubCalendarEvent> tilesForDay(ScheduleState state, int dayIndex) {
    List<SubCalendarEvent>? subEvents;
    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
    }
    if (subEvents == null) return const <SubCalendarEvent>[];
    return subEvents.where((tile) {
      final int? start = tile.start;
      if (start == null) return false;
      if (!(tile.isViable ?? true)) return false;
      return Utility.localDateTimeFromMs(start).universalDayIndex == dayIndex;
    }).toList();
  }

  void _showRoute(BuildContext context) {
    final tiles = tilesForDay(
        context.read<ScheduleBloc>().state, currentDate.universalDayIndex);
    final stats = TodayStats.fromTiles(tiles);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodaysRoutePage(
          tiles: tiles,
          timeSaved: stats.travelTime > Duration.zero ? stats.travelTime : null,
        ),
      ),
    );
  }

  void _reOptimize(BuildContext context) {
    context.read<ScheduleBloc>().add(ReviseScheduleEvent());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Stretch so the chips row spans the width and its chips sit LEFT
        // (a shrink-wrapped row would centre them).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuickActionChipsRow(
            preview: preview,
            showRouteKey: showRouteKey,
            reOptimizeKey: reOptimizeKey,
            onShowRoute: () => _showRoute(context),
            onReOptimize: () => _reOptimize(context),
          ),
          BlocBuilder<ScheduleBloc, ScheduleState>(
            buildWhen: (previous, current) =>
                _isLoading(previous) != _isLoading(current),
            builder: (context, state) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading(state)
                  ? LinearProgressIndicator(
                      key: const ValueKey('schedule-loading-indicator'),
                      minHeight: 3,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.tertiary,
                    )
                  : const SizedBox(
                      key: ValueKey('schedule-loading-hidden'),
                      height: 3,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isLoading(ScheduleState state) =>
      state is ScheduleLoadingState || state is ScheduleEvaluationState;
}
