import 'dart:async';

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
  /// day in view. Retaining the most recent summary per day lets a day keep
  /// its previously fetched completion data when a later fetch doesn't include
  /// that day.
  final Map<int, TimelineSummary> _retainedDaySummaries = {};
  int _sessionGeneration = 0;
  bool _closing = false;
  final Set<_SummaryRead> _pendingReads = {};
  _SummaryRead? _dayRead;
  _SummaryRead? _elapsedRead;

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

  /// Own the deadline separately from HTTP so supersession, logout and close
  /// can cancel it immediately. Future.timeout alone keeps its timer alive
  /// when Bloc cancels the emitter but the underlying request never completes.
  Future<Map<int, TimelineSummary>> _readSummary(Timeline timeline,
      {bool elapsed = false}) async {
    if (_closing) throw _SummaryReadCancelled();
    (elapsed ? _elapsedRead : _dayRead)?.cancel();
    final request = _SummaryRead(scheduleApi.getDaySummary(timeline));
    if (elapsed) {
      _elapsedRead = request;
    } else {
      _dayRead = request;
    }
    _pendingReads.add(request);
    try {
      return await request.result.future;
    } finally {
      _pendingReads.remove(request);
      if (identical(_dayRead, request)) _dayRead = null;
      if (identical(_elapsedRead, request)) _elapsedRead = null;
    }
  }

  void _cancelReads() {
    for (final request in List.of(_pendingReads)) {
      request.cancel();
    }
  }

  @override
  Future<void> close() {
    _closing = true;
    ++_sessionGeneration;
    _cancelReads();
    return super.close();
  }

  /// Merges freshly fetched day summaries into the retained cache and returns
  /// the union of all known days.
  ///
  /// A day present in [freshSummaries] is authoritative and replaces any prior
  /// entry wholesale (so completing/uncompleting a tile and pulling to refresh
  /// reflects the new counts, including going back to zero). Days the fetch did
  /// not include simply stay in the cache from their last retrieval, so they
  /// don't lose their completion data when a later, narrower fetch omits them.
  List<TimelineSummary> _mergeAndRetainDaySummaries(
      List<TimelineSummary> freshSummaries) {
    for (final fresh in freshSummaries) {
      final int? dayIndex = fresh.dayIndex;
      if (dayIndex == null) {
        continue;
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
    // Logout is a different event type, so restartable() alone cannot prevent
    // this request from restoring the previous account's counts afterward.
    final generation = _sessionGeneration;
    List<TimelineSummary>? dayData = _retainedDaySummaries.values.toList();
    Timeline timeline = event.timeline ?? Utility.todayTimeline();

    // Carry the previously loaded/retained summaries into the loading state so
    // the UI keeps showing the last-known metrics while the fetch is in flight.
    //
    // Note: we intentionally fetch exactly the requested [timeline] window and
    // do NOT union it with the previously loaded timeline. The backend only
    // answers for a bounded window, so unioning an out-of-window jump (e.g. 20
    // days back) with the current window produced a huge span that never
    // returned the selected day. Retention of earlier days is handled by
    // [_mergeAndRetainDaySummaries], not by an ever-growing query range.
    if (state is ScheduleDaySummaryLoaded) {
      dayData = (state as ScheduleDaySummaryLoaded).dayData;
    }
    if (state is ScheduleDaySummaryLoading) {
      dayData = (state as ScheduleDaySummaryLoading).dayData;
    }
    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: dayData));

    await _readSummary(timeline).then((value) async {
      if (emit.isDone || generation != _sessionGeneration) return;
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
      if (error is _SummaryReadCancelled) return;
      if (emit.isDone || generation != _sessionGeneration) return;
      // Summary retrieval fails independently of the event list. Keep known
      // counts available to newly mounted headers instead of implying zeros.
      emit(ScheduleSummaryErrorState(
          error: error.toString(),
          message: 'Failed to load schedule summary',
          timeline: timeline,
          dayData: List.unmodifiable(_retainedDaySummaries.values)));
    });
  }

  Future<void> _onGetElapsedTasks(
      GetElapsedTasksEvent event, Emitter<ScheduleSummaryState> emit) async {
    final generation = _sessionGeneration;
    DateTime now = Utility.currentTime();
    DateTime startOfWeek = now.subtract(Duration(days: 7));
    Timeline timeline = Timeline.fromDateTime(startOfWeek, now);

    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: []));

    await _readSummary(timeline, elapsed: true).then((value) async {
      if (emit.isDone || generation != _sessionGeneration) return;
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
      if (error is _SummaryReadCancelled) return;
      if (emit.isDone || generation != _sessionGeneration) return;
      emit(ScheduleSummaryErrorState(
          error: error.toString(),
          message: '',
          timeline: timeline,
          dayData: List.unmodifiable(_retainedDaySummaries.values)));
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
    ++_sessionGeneration;
    _cancelReads();
    _retainedDaySummaries.clear();
    scheduleApi = new ScheduleApi(getContextCallBack: () => null);
    emit(LoggedOutScheduleSummaryState());
  }
}

/// Cancellation releases waiters without presenting a network failure.
class _SummaryReadCancelled implements Exception {}

class _SummaryRead {
  _SummaryRead(Future<Map<int, TimelineSummary>> source) {
    _timer = Timer(const Duration(seconds: 25), () {
      if (!result.isCompleted) {
        result.completeError(TimeoutException('Schedule summary timed out'));
      }
    });
    // Consume late errors even after cancellation; the HTTP request can finish
    // after its owning screen or account has gone away.
    source.then((value) {
      _timer.cancel();
      if (!result.isCompleted) result.complete(value);
    }, onError: (Object error, StackTrace stack) {
      _timer.cancel();
      if (!result.isCompleted) result.completeError(error, stack);
    });
  }

  final result = Completer<Map<int, TimelineSummary>>();
  late final Timer _timer;

  void cancel() {
    _timer.cancel();
    if (!result.isCompleted) result.completeError(_SummaryReadCancelled());
  }
}
