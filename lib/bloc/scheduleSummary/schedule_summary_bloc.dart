import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc
    extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  ScheduleApi scheduleApi = ScheduleApi();
  ScheduleSummaryBloc() : super(ScheduleSummaryInitial()) {
    on<GetScheduleDaySummaryEvent>(_onGetDayData);
    on<LogOutScheduleDaySummaryEvent>(_onLogOutScheduleDaySummaryEvent);
  }

  Future<void> _onGetDayData(GetScheduleDaySummaryEvent event,
      Emitter<ScheduleSummaryState> emit) async {
    List<TimelineSummary>? dayData;
    Timeline? timeline = event.timeline ?? Utility.todayTimeline();
    if (state is ScheduleDaySummaryLoaded) {
      if (event.requestId == null) {
        Timeline loadedTimeline = (state as ScheduleDaySummaryLoaded).timeline!;
        DateTime startTimeline = DateTime.fromMillisecondsSinceEpoch(min(
            loadedTimeline.startTime.millisecondsSinceEpoch,
            timeline.startTime.millisecondsSinceEpoch));
        DateTime endTimeline = DateTime.fromMillisecondsSinceEpoch(max(
            loadedTimeline.endTime.millisecondsSinceEpoch,
            timeline.endTime.millisecondsSinceEpoch));
        timeline = Timeline.fromDateTime(startTimeline, endTimeline);
      }
      dayData = (state as ScheduleDaySummaryLoaded).dayData;
    }
    if (state is ScheduleDaySummaryLoading) {
      if (event.requestId == null) {
        Timeline pendingTimeline =
            (state as ScheduleDaySummaryLoading).timeline!;
        DateTime startTimeline = DateTime.fromMillisecondsSinceEpoch(min(
            pendingTimeline.startTime.millisecondsSinceEpoch,
            timeline.startTime.millisecondsSinceEpoch));
        DateTime endTimeline = DateTime.fromMillisecondsSinceEpoch(max(
            pendingTimeline.endTime.millisecondsSinceEpoch,
            timeline.endTime.millisecondsSinceEpoch));
        timeline = Timeline.fromDateTime(startTimeline, endTimeline);
      }
      dayData = (state as ScheduleDaySummaryLoading).dayData;
    }
    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: dayData));

    await scheduleApi.getDaySummary(timeline).then((value) async {
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline,
          dayData: value.values.toList(),
          requestId: event.requestId));
    });
  }

  FutureOr<void> _onLogOutScheduleDaySummaryEvent(
      LogOutScheduleDaySummaryEvent event, Emitter<ScheduleSummaryState> emit) {
    scheduleApi = new ScheduleApi();
    emit(LoggedOutScheduleSummaryState());
  }
}
