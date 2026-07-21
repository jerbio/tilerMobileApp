import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../data/subCalendarEvent.dart';
import '../../data/tilerEvent.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc
    extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  late ScheduleApi scheduleApi;
  late SubCalendarEventApi subCalendarEventApi;

  /// Last retrieved day summary per universal day index. The daySummarys web
  /// request is the only source of the completed/tardy lists (they never
  /// appear in the schedule tiles), and a given fetch may not re-report every
  /// day in view. Retaining the most recent summary per day lets us backfill
  /// those lists so a day never loses its previously fetched completion data.
  final Map<int, TimelineSummary> _retainedDaySummaries = {};

  ScheduleSummaryBloc({required Function getContextCallBack})
      : super(ScheduleSummaryInitial()) {
    on<GetScheduleDaySummaryEvent>(_onGetDayData, transformer: restartable());
    on<LogOutScheduleDaySummaryEvent>(_onLogOutScheduleDaySummaryEvent);
    on<GetElapsedTasksEvent>(_onGetElapsedTasks);
    on<CompleteTaskEvent>(_onCompleteTask);
    subCalendarEventApi =
        SubCalendarEventApi(getContextCallBack: getContextCallBack);
    scheduleApi = new ScheduleApi(getContextCallBack: getContextCallBack);
  }

  /// Merges freshly fetched day summaries into the retained cache and returns
  /// the union of all known days. Freshly fetched data wins, but any list the
  /// new fetch didn't report (most importantly [complete] and [tardy]) is
  /// backfilled from the last retrieval so the completion metrics persist.
  List<TimelineSummary> _mergeAndRetainDaySummaries(
      List<TimelineSummary> freshSummaries) {
    for (final fresh in freshSummaries) {
      final int? dayIndex = fresh.dayIndex;
      if (dayIndex == null) {
        continue;
      }
      final TimelineSummary? prior = _retainedDaySummaries[dayIndex];
      if (prior != null) {
        fresh.complete ??= prior.complete;
        fresh.tardy ??= prior.tardy;
        fresh.wake ??= prior.wake;
        fresh.sleep ??= prior.sleep;
        fresh.deleted ??= prior.deleted;
        fresh.nonViable ??= prior.nonViable;
        fresh.sleepDuration ??= prior.sleepDuration;
      }
      _retainedDaySummaries[dayIndex] = fresh;
    }
    return _retainedDaySummaries.values.toList();
  }

  List<TilerEvent> _getElapsedTasks(List<TimelineSummary> daySummaries) {
    DateTime now = Utility.currentTime(minuteLimitAccuracy: false);
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
      List<TimelineSummary> mergedDayData =
          _mergeAndRetainDaySummaries(daySummaries);
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline,
          dayData: mergedDayData,
          requestId: event.requestId,
          elapsedTiles: elapsedTasks));
    }).catchError((error) {
      print('Error fetching day summary: $error');
      emit(ScheduleSummaryErrorState(
          error: error.toString(), message: 'Failed to load schedule summary'));
    });
  }

  Future<void> _onGetElapsedTasks(
      GetElapsedTasksEvent event, Emitter<ScheduleSummaryState> emit) async {
    DateTime now = Utility.currentTime();
    DateTime startOfWeek = now.subtract(Duration(days: 7));
    Timeline timeline = Timeline.fromDateTime(startOfWeek, now);

    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: []));

    await scheduleApi.getDaySummary(timeline).then((value) async {
      List<TimelineSummary> daySummaries = value.values.toList();
      List<TilerEvent> elapsedTasks = _getElapsedTasks(daySummaries);
      List<TimelineSummary> mergedDayData =
          _mergeAndRetainDaySummaries(daySummaries);
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline,
          dayData: mergedDayData,
          requestId: null,
          elapsedTiles: elapsedTasks));
    }).catchError((error) {
      emit(ScheduleSummaryErrorState(error: error.toString(), message: ''));
    });
  }

  Future<bool> _onCompleteTask(
      CompleteTaskEvent event, Emitter<ScheduleSummaryState> emit) async {
    emit(ScheduleSummaryLoadingTaskState());
    return true;
  }

  Future<bool> completeTasks(String id, String type, String userId) async {
    try {
      await subCalendarEventApi.completeTiles(id, type, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  FutureOr<void> _onLogOutScheduleDaySummaryEvent(
      LogOutScheduleDaySummaryEvent event, Emitter<ScheduleSummaryState> emit) {
    _retainedDaySummaries.clear();
    scheduleApi = new ScheduleApi(getContextCallBack: () => null);
    emit(LoggedOutScheduleSummaryState());
  }
}
