// Edit Tile redesign — Step 1.3: the bloc-backed schedule refresher.
//
// A PORT, not a redesign, of the dispatches the legacy screen made inline in
// `subEventUpdate()`, `handleRsvpUpdate()`, `refreshScheduleSummary()` and
// the playback callback. It exists so the submission can be tested with a
// recording fake while the app still gets exactly the bloc traffic it had.
//
// One deliberate difference: [abandonEvaluation]. The legacy save put the
// schedule into `EvaluateSchedule` and, on failure, dispatched nothing else —
// the schedule stayed "evaluating". Here a failure reloads what was there.
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/util.dart';

class BlocEditTileScheduleRefresher implements EditTileScheduleRefresher {
  BlocEditTileScheduleRefresher({
    required this.scheduleBloc,
    required this.scheduleSummaryBloc,
  });

  final ScheduleBloc scheduleBloc;
  final ScheduleSummaryBloc scheduleSummaryBloc;

  @override
  void beginEvaluation() {
    // `subEventUpdate()`: only from a loaded schedule, as before.
    final ScheduleState current = scheduleBloc.state;
    if (current is ScheduleLoadedState) {
      scheduleBloc.add(EvaluateSchedule(
        isAlreadyLoaded: true,
        scheduleStatus: current.scheduleStatus,
        renderedScheduleTimeline: current.lookupTimeline,
        renderedSubEvents: current.subEvents,
        renderedTimelines: current.timelines,
      ));
    }
  }

  @override
  void refreshAfterChange() => _reload(forceRefresh: true);

  @override
  void abandonEvaluation() => _reload(forceRefresh: false);

  void _reload({required bool forceRefresh}) {
    // `subEventUpdate()`'s `.then`: preserve whatever the bloc holds and ask
    // for the schedule again, then the day summary.
    final preserved = ScheduleBloc.preserveState(scheduleBloc.state);
    final Timeline? lookupTimeline = preserved.item3;
    scheduleBloc.add(GetScheduleEvent(
      isAlreadyLoaded: true,
      previousSubEvents: preserved.item1,
      scheduleTimeline: lookupTimeline,
      previousTimeline: lookupTimeline,
      forceRefresh: forceRefresh,
    ));
    _refreshSummary(lookupTimeline);
  }

  /// `refreshScheduleSummary()`, verbatim.
  void _refreshSummary(Timeline? lookupTimeline) {
    final ScheduleSummaryState current = scheduleSummaryBloc.state;
    if (current is ScheduleSummaryInitial ||
        current is ScheduleDaySummaryLoaded ||
        current is ScheduleDaySummaryLoading) {
      scheduleSummaryBloc.add(GetScheduleDaySummaryEvent(
        timeline: lookupTimeline ?? Utility.todayTimeline(),
      ));
    }
  }
}
