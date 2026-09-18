// Step 1.3 — the bloc-backed refresher dispatches what the legacy screen did.
//
// The blocs are subclassed only to RECORD `add` (their handlers would go to
// the network). What is pinned is the traffic: which events, with which
// flags, in which order — the port's whole job.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';

class RecordingScheduleBloc extends ScheduleBloc {
  RecordingScheduleBloc() : super(getContextCallBack: () => null);
  final List<ScheduleEvent> added = <ScheduleEvent>[];

  @override
  void add(ScheduleEvent event) => added.add(event);
}

class RecordingSummaryBloc extends ScheduleSummaryBloc {
  RecordingSummaryBloc() : super(getContextCallBack: () => null);
  final List<ScheduleSummaryEvent> added = <ScheduleSummaryEvent>[];

  @override
  void add(ScheduleSummaryEvent event) => added.add(event);
}

void main() {
  late RecordingScheduleBloc schedule;
  late RecordingSummaryBloc summary;
  late BlocEditTileScheduleRefresher refresher;

  setUp(() {
    schedule = RecordingScheduleBloc();
    summary = RecordingSummaryBloc();
    refresher = BlocEditTileScheduleRefresher(
        scheduleBloc: schedule, scheduleSummaryBloc: summary);
  });

  tearDown(() async {
    await schedule.close();
    await summary.close();
  });

  test('beginEvaluation dispatches nothing from an unloaded schedule', () {
    // `subEventUpdate()` guarded on `ScheduleLoadedState`; kept.
    refresher.beginEvaluation();
    expect(schedule.added, isEmpty);
  });

  test('refreshAfterChange forces a reload and refreshes the summary', () {
    refresher.refreshAfterChange();
    expect(schedule.added, hasLength(1));
    final GetScheduleEvent reload = schedule.added.single as GetScheduleEvent;
    expect(reload.forceRefresh, isTrue);
    expect(reload.isAlreadyLoaded, isTrue);
    expect(summary.added.single, isA<GetScheduleDaySummaryEvent>());
  });

  test('abandonEvaluation reloads WITHOUT forcing', () {
    refresher.abandonEvaluation();
    final GetScheduleEvent reload = schedule.added.single as GetScheduleEvent;
    expect(reload.forceRefresh, isFalse);
    expect(summary.added.single, isA<GetScheduleDaySummaryEvent>());
  });
}
