import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';

import '../../data/subCalendarEvent.dart';
import '../../data/tilerEvent.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc
    extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  ScheduleApi scheduleApi = ScheduleApi();
  SubCalendarEventApi subCalendarEventApi = SubCalendarEventApi();
  ScheduleSummaryBloc() : super(ScheduleSummaryInitial()) {
    on<GetScheduleDaySummaryEvent>(_onGetDayData);
    on<LogOutScheduleDaySummaryEvent>(_onLogOutScheduleDaySummaryEvent);
    on<GetElapsedTasksEvent>(_onGetElapsedTasks);
    on<CompleteTaskEvent>(_onCompleteTask);
  }

  List<TilerEvent> _getElapsedTasks(List<TimelineSummary> daySummaries) {
    DateTime now = DateTime.now();
    List<TilerEvent> elapsedTasks = [];

    for (var summary in daySummaries) {
      // if (summary.complete != null) {
      //   elapsedTasks.addAll(
      //       summary.complete!.where((task) => task.endTime.isBefore(now)));
      // }
      if (summary.tardy != null) {
        elapsedTasks
            .addAll(summary.tardy!.where((task) => task.endTime.isBefore(now)));
      }
      if (summary.wake != null) {
        elapsedTasks
            .addAll(summary.wake!.where((task) => task.endTime.isBefore(now)));
      }
      // Add other task types if needed
      if (summary.nonViable != null) {
        elapsedTasks.addAll(
            summary.nonViable!.where((task) => task.endTime.isBefore(now)));
      }
      // if (summary.sleep != null) {
      //   elapsedTasks
      //       .addAll(summary.sleep!.where((task) => task.endTime.isBefore(now)));
      // }
      // if (summary.deleted != null) {
      //   elapsedTasks.addAll(
      //       summary.deleted!.where((task) => task.endTime.isBefore(now)));
      // }
    }
    return elapsedTasks;
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
      List<TimelineSummary> daySummaries = value.values.toList();
      List<TilerEvent> elapsedTasks = _getElapsedTasks(daySummaries);
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline,
          dayData: value.values.toList(),
          requestId: event.requestId,
          elapsedTasks: elapsedTasks));
    });
  }

  Future<void> _onGetElapsedTasks(
      GetElapsedTasksEvent event, Emitter<ScheduleSummaryState> emit) async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: 7));
    Timeline timeline = Timeline.fromDateTime(startOfWeek, now);

    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: []));

    await scheduleApi.getDaySummary(timeline).then((value) async {
      List<TimelineSummary> daySummaries = value.values.toList();
      List<TilerEvent> elapsedTasks = _getElapsedTasks(daySummaries);
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline,
          dayData: daySummaries,
          requestId: null,
          elapsedTasks: elapsedTasks));
    }).catchError((error) {
      emit(ScheduleSummaryErrorState(error: error.toString(), message: ''));
    });
  }

  Future<bool> _onCompleteTask(
      CompleteTaskEvent event, Emitter<ScheduleSummaryState> emit) async {
    emit(ScheduleSummaryLoadingTaskState());

    await Future.delayed(
      Duration(seconds: 2),
      () {
        print("Test 1");
      },
    );
    await Future.delayed(
      Duration(seconds: 2),
      () {
        print("Test 2");
      },
    );
    return true;
  }

  Future<bool> completeTask(SubCalendarEvent subEvent) async {
    try {
      await subCalendarEventApi.complete(subEvent);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deferTask(String tileId, Duration duration) async {
    try {
      await subCalendarEventApi.procrastinate(duration, tileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  FutureOr<void> _onLogOutScheduleDaySummaryEvent(
      LogOutScheduleDaySummaryEvent event, Emitter<ScheduleSummaryState> emit) {
    scheduleApi = new ScheduleApi();
    emit(LoggedOutScheduleSummaryState());
  }
}
