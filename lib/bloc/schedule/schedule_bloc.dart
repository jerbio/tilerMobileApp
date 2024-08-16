import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../services/api/subCalendarEventApi.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final Duration _retryScheduleLoadingDuration = Duration(minutes: 5);
  ScheduleApi scheduleApi = ScheduleApi();
  SubCalendarEventApi subCalendarEventApi = SubCalendarEventApi();
  ScheduleBloc() : super(ScheduleInitialState()) {
    on<GetScheduleEvent>(_onGetSchedule);
    on<LogInScheduleEvent>(_onInitialLogInScheduleEvent);
    on<LogOutScheduleEvent>(_onLoggedOutScheduleEvent);
    on<ReloadLocalScheduleEvent>(_onLocalScheduleEvent);
    on<ReviseScheduleEvent>(_onReviseSchedule);
    on<EvaluateSchedule>(_onEvaluateSchedule);
    on<CompleteTaskEvent>(_onCompleteTask);
  }

  Future<Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>>
      getSubTiles(Timeline timeLine) async {
    return scheduleApi.getSubEvents(timeLine);
  }

  Future<bool> shouldGetRefreshedListOfTiles(ScheduleStatus currentStatus) {
    return scheduleApi.getScheduleStatus().then((value) {
      bool isAnalyisTheSame = false;
      bool isEvaluationTheSame = false;
      if (value.analysisId == currentStatus.analysisId) {
        isAnalyisTheSame = true;
        if (currentStatus.analysisId == null ||
            currentStatus.analysisId!.isEmpty) {
          isAnalyisTheSame = false;
        }
      }
      if (value.evaluationId == currentStatus.evaluationId) {
        isEvaluationTheSame = true;
        if (currentStatus.evaluationId == null ||
            currentStatus.evaluationId!.isEmpty) {
          isEvaluationTheSame = false;
        }
      }

      bool retValue = !isAnalyisTheSame || !isEvaluationTheSame;
      return retValue;
    });
  }

  void _onLocalScheduleEvent(
      ReloadLocalScheduleEvent event, Emitter<ScheduleState> emit) {
    LocalScheduleLoadedState put = LocalScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        scheduleStatus: event.scheduleStatus,
        lookupTimeline: event.lookupTimeline,
        eventId: null,
        previousLookupTimeline: event.previousLookupTimeline);

    emit(put);
    // emit(put);
  }

  void _onLoggedOutScheduleEvent(
      LogOutScheduleEvent event, Emitter<ScheduleState> emit) async {
    scheduleApi = ScheduleApi();
    emit(ScheduleLoggedOutState());
  }

  void _onInitialLogInScheduleEvent(
      LogInScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleInitialState());
  }

  Future _getSubEventCallBack(
      Timeline updateTimeline,
      List<SubCalendarEvent> subEvents,
      List<Timeline> timelines,
      ScheduleStatus scheduleStatus,
      Emitter<ScheduleState> emit,
      {String? eventId = null,
      Timeline? previousTimeLine}) async {
    await this.getSubTiles(updateTimeline).then((value) {
      List<SubCalendarEvent> updatedSubEvents = value.item2;
      if (state is ScheduleLoadedState &&
          !(state is LocalScheduleLoadedState)) {
        emit(LocalScheduleLoadedState(
            subEvents: updatedSubEvents,
            timelines: value.item1.toList(),
            scheduleStatus: value.item3,
            lookupTimeline: updateTimeline,
            previousLookupTimeline: previousTimeLine,
            eventId: eventId));
      } else {
        emit(ScheduleLoadedState(
            subEvents: updatedSubEvents,
            timelines: value.item1.toList(),
            scheduleStatus: value.item3,
            lookupTimeline: updateTimeline,
            previousLookupTimeline: previousTimeLine,
            eventId: eventId));
      }
    }).catchError((onError) {
      emit(FailedScheduleLoadedState(
          evaluationTime: Utility.currentTime(),
          subEvents: subEvents,
          timelines: timelines,
          scheduleStatus: scheduleStatus,
          lookupTimeline: updateTimeline,
          previousLookupTimeline: previousTimeLine,
          eventId: eventId));
    });
  }

  Future<void> _onCompleteTask(
      CompleteTaskEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoadingTaskState());
    try {
      print("started making api call to complete");
      SubCalendarEvent completedEvent =
          await subCalendarEventApi.complete(event.subEvent);
      print("SUCCESSFULLY COMPLETED TASK");
      emit(ScheduleCompleteTaskState(completedEvent: completedEvent));
    } catch (error) {
      emit(FailedScheduleLoadedState(
          evaluationTime: DateTime.now(),
          subEvents: [],
          timelines: [],
          lookupTimeline: Timeline.fromDateTime(
              DateTime.now(), DateTime.now().add(Duration(days: 1))), scheduleStatus: null));
    }
  }

//   Future<void> _onCompleteTask(
//     CompleteTaskEvent event, Emitter<ScheduleState> emit) async {
//   try {
//     emit(ScheduleLoadingState(
//         subEvents: [],
//         timelines: [],
//         previousLookupTimeline: Timeline.fromDateTime(DateTime.now(), DateTime.now().add(Duration(days: 1))),
//         isAlreadyLoaded: true,
//         loadingTime: DateTime.now(),
//         connectionState: ConnectionState.waiting));

//     SubCalendarEvent completedEvent = await subCalendarEventApi.complete(event.subEvent);
//     emit(ScheduleCompleteTaskState(completedEvent: completedEvent));
//   } catch (error) {
//     emit(FailedScheduleLoadedState(
//         evaluationTime: DateTime.now(),
//         subEvents: [],
//         timelines: [],
//         lookupTimeline: Timeline.fromDateTime(
//             DateTime.now(), DateTime.now().add(Duration(days: 1)))));
//   }
// }

  // Future<void> _onCompleteTask(
  //     CompleteTaskEvent event, Emitter<ScheduleState> emit) async {
  //   try {
  //     print("started making api call to complete");
  //     SubCalendarEvent completedEvent =
  //         await subCalendarEventApi.complete(event.subEvent);
  //     print("SUCCESSFULLY COMPLETED TASK");
  //     emit(ScheduleCompleteTaskState(completedEvent: completedEvent));
  //   } catch (error) {
  //     emit(FailedScheduleLoadedState(
  //         evaluationTime: DateTime.now(),
  //         subEvents: [],
  //         timelines: [],
  //         lookupTimeline: Timeline.fromDateTime(
  //             DateTime.now(), DateTime.now().add(Duration(days: 1)))));
  //   }
  // }

  Future<void> _onGetSchedule(
      GetScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    String? eventId = event.eventId;
    bool isAlreadyLoaded = false;
    Timeline updateTimeline =
        event.scheduleTimeline ?? Utility.initialScheduleTimeline;
    List<SubCalendarEvent> subEvents = event.previousSubEvents ?? [];
    List<Timeline> timelines = [];
    ScheduleStatus scheduleStatus = new ScheduleStatus();
    bool makeRemoteCall = false;

    if (state is ScheduleInitialState) {
      isAlreadyLoaded = false;
      updateTimeline =
          event.scheduleTimeline ?? Utility.initialScheduleTimeline;
      subEvents = [];
      timelines = [];
    }

    if (state is ScheduleLoadedState) {
      Timeline timeline = state.lookupTimeline;
      updateTimeline = event.scheduleTimeline ?? timeline;
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      isAlreadyLoaded = true;
      if (!timeline.isStartAndEndEqual(updateTimeline) ||
          event.scheduleTimeline == null) {
        makeRemoteCall = true;
      }
    }

    if (state is ScheduleEvaluationState) {
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      updateTimeline = state.lookupTimeline;
      isAlreadyLoaded = true;
    }
    if (!event.emitOnlyLoadedStated) {
      emit(ScheduleLoadingState(
          subEvents: subEvents,
          timelines: timelines,
          previousLookupTimeline: event.previousTimeline ?? updateTimeline,
          isAlreadyLoaded: isAlreadyLoaded,
          scheduleStatus: scheduleStatus,
          eventId: event.eventId,
          loadingTime: Utility.currentTime(),
          connectionState: ConnectionState.waiting));
    }

    if (event.forceRefresh || makeRemoteCall) {
      print("Force refresh on get tiles");
      await _getSubEventCallBack(
          updateTimeline, subEvents, timelines, scheduleStatus, emit,
          eventId: eventId, previousTimeLine: event.previousTimeline);
      return;
    }

    print("no force refresh on get tiles");
    await shouldGetRefreshedListOfTiles(scheduleStatus).then((value) async {
      if (value) {
        await _getSubEventCallBack(
            updateTimeline, subEvents, timelines, scheduleStatus, emit,
            eventId: eventId, previousTimeLine: event.previousTimeline);
        return;
      }
      return;
    });

    return;
  }

  static Tuple5<List<SubCalendarEvent>?, List<Timeline>?, Timeline?, String?,
      ScheduleStatus> preserveState(ScheduleState state) {
    List<SubCalendarEvent>? subEvents;
    List<Timeline>? timelines;
    Timeline? lookupTimeline;
    String? message;
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.lookupTimeline;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      lookupTimeline = state.lookupTimeline;
    }

    if (state is ScheduleInitialState) {
      subEvents = [];
      timelines = [];
      lookupTimeline = Utility.initialScheduleTimeline;
      scheduleStatus = ScheduleStatus();
    }

    return Tuple5<List<SubCalendarEvent>?, List<Timeline>?, Timeline?, String?,
            ScheduleStatus>(
        subEvents, timelines, lookupTimeline, message, scheduleStatus);
  }

  Future<void> _onReviseSchedule(
      ReviseScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;

    print("revising your schedule");
    print("current state is ");
    print(state);
    var priorSscheduleState = ScheduleState.generatePriorScheduleState(state);
    List<SubCalendarEvent> subEvents = priorSscheduleState.subEvents;
    List<Timeline> timelines = priorSscheduleState.timelines;
    Timeline lookupTimeline = priorSscheduleState.previousLookupTimeline;
    ScheduleStatus? scheduleStatus = priorSscheduleState.scheduleStatus;
    String? message;
    if (subEvents != null && timelines != null && lookupTimeline != null) {
      emit(ScheduleEvaluationState(
          subEvents: subEvents,
          timelines: timelines,
          lookupTimeline: lookupTimeline,
          evaluationTime: Utility.currentTime(),
          scheduleStatus: scheduleStatus,
          message: message));
      await this.scheduleApi.reviseSchedule().then((value) async {
        await this._onGetSchedule(
            GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: subEvents,
              previousTimeline: lookupTimeline,
              scheduleTimeline: lookupTimeline,
            ),
            emit);
      });
    }
  }

  void _onEvaluateSchedule(
      EvaluateSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleEvaluationState(
        subEvents: event.renderedSubEvents,
        timelines: event.renderedTimelines,
        lookupTimeline: event.renderedScheduleTimeline,
        evaluationTime: Utility.currentTime(),
        scheduleStatus: event.scheduleStatus,
        message: event.message));
    if (event.callBack != null) {
      await event.callBack!.whenComplete(() async {
        await this._onGetSchedule(
            GetScheduleEvent(
              isAlreadyLoaded: true,
              emitOnlyLoadedStated: true,
              previousSubEvents: event.renderedSubEvents,
              previousTimeline: event.renderedScheduleTimeline,
              scheduleTimeline: event.renderedScheduleTimeline,
            ),
            emit);
      });
    }
  }

  // void _onDelayedGetSchedule(
  //     DelayedGetSchedule event, Emitter<ScheduleState> emit) async {
  //   var setTimeOutResult = Utility.setTimeOut(duration: event.delayDuration!);

  //   emit(DelayedScheduleLoadedState(
  //       subEvents: event.previousSubEvents,
  //       timelines: event.renderedTimelines,
  //       lookupTimeline: event.scheduleTimeline,
  //       scheduleStatus: event.scheduleStatus,
  //       pendingDelayedScheduleRetrieval:
  //           setTimeOutResult.item1.asStream().listen((futureEvent) async {})));

  //   await setTimeOutResult.item1.then((futureEvent) async {
  //     await this._onGetSchedule(
  //         GetScheduleEvent(
  //           isAlreadyLoaded: true,
  //           previousSubEvents: event.previousSubEvents,
  //           previousTimeline: event.previousTimeline,
  //           scheduleTimeline: event.scheduleTimeline,
  //         ),
  //         emit);
  //   });
  // }
}
