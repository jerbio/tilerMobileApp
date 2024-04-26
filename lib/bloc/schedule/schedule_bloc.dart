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

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final Duration _retryScheduleLoadingDuration = Duration(minutes: 5);
  ScheduleApi scheduleApi = ScheduleApi();
  ScheduleBloc() : super(ScheduleInitialState()) {
    on<GetScheduleEvent>(_onGetSchedule);
    on<LogInScheduleEvent>(_onInitialLogInScheduleEvent);
    on<LogOutScheduleEvent>(_onLoggedOutScheduleEvent);
    on<ReloadLocalScheduleEvent>(_onLocalScheduleEvent);
    on<ReviseScheduleEvent>(_onReviseSchedule);
    on<EvaluateSchedule>(_onEvaluateSchedule);
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
      ReloadLocalScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        scheduleStatus: event.scheduleStatus,
        lookupTimeline: event.lookupTimeline));
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

  Future<void> _onGetSchedule(
      GetScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    print("Get Schedule State");
    print(state);
    bool isAlreadyLoaded = false;
    Timeline updateTimeline =
        event.scheduleTimeline ?? Utility.initialScheduleTimeline;
    List<SubCalendarEvent> subEvents = event.previousSubEvents ?? [];
    List<Timeline> timelines = [];
    ScheduleStatus scheduleStatus = new ScheduleStatus();

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
      if (!timeline.isInterfering(updateTimeline)) {
        int startInMs = updateTimeline.start! < timeline.start!
            ? updateTimeline.start!
            : timeline.start!;
        int endInMs = updateTimeline.end! > timeline.end!
            ? updateTimeline.end!
            : timeline.end!;

        updateTimeline = Timeline.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(startInMs.toInt(), isUtc: true),
            DateTime.fromMillisecondsSinceEpoch(endInMs.toInt(), isUtc: true));
      }
    }

    var getSubEventCallBack = (Timeline updateTimeline,
        List<SubCalendarEvent> subEvents,
        List<Timeline> timelines,
        ScheduleStatus scheduleStatus) async {
      await getSubTiles(updateTimeline).then((value) {
        Map<String, SubCalendarEvent> subEventMap = {};
        bool isNewEvaluation = true;
        for (SubCalendarEvent eachSubEvent in subEvents) {
          if (eachSubEvent.id != null && eachSubEvent.id!.isNotEmpty) {
            subEventMap[eachSubEvent.id!] = eachSubEvent;
          }
        }

        if (subEvents.isNotEmpty) {
          if (value.item3.analysisId != null) {
            if (subEvents.first.analysisId == value.item3.analysisId) {
              isNewEvaluation = false;
            }
          }
          if (value.item3.evaluationId != null) {
            if (subEvents.first.evaluationId == value.item3.evaluationId) {
              isNewEvaluation = false;
            }
          }
        }
        List<SubCalendarEvent> updatedSubEvents = value.item2;
        if (!isNewEvaluation) {
          print("------old evaluation-----");
          updatedSubEvents.forEach((eachSubEvent) {
            if (eachSubEvent.id != null) {
              subEventMap[eachSubEvent.id!] = eachSubEvent;
            }
          });
          updatedSubEvents = subEventMap.values.toList();
        }
        emit(ScheduleLoadedState(
            subEvents: updatedSubEvents,
            timelines: value.item1,
            scheduleStatus: value.item3,
            lookupTimeline: updateTimeline));
      }).catchError((onError) {
        emit(FailedScheduleLoadedState(
            evaluationTime: Utility.currentTime(),
            subEvents: subEvents,
            timelines: timelines,
            scheduleStatus: scheduleStatus,
            lookupTimeline: updateTimeline));
      });
    };

    if (state is ScheduleEvaluationState) {
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      updateTimeline = state.lookupTimeline;
      isAlreadyLoaded = true;
    }

    emit(ScheduleLoadingState(
        subEvents: subEvents,
        timelines: timelines,
        previousLookupTimeline: updateTimeline,
        isAlreadyLoaded: isAlreadyLoaded,
        scheduleStatus: scheduleStatus,
        loadingTime: Utility.currentTime(),
        connectionState: ConnectionState.waiting));

    if (event.forceRefresh) {
      print("Force refresh on get tiles");
      await getSubEventCallBack(
          updateTimeline, subEvents, timelines, scheduleStatus);
      return;
    }

    print("no force refresh on get tiles");
    await shouldGetRefreshedListOfTiles(scheduleStatus).then((value) async {
      if (value) {
        await getSubEventCallBack(
            updateTimeline, subEvents, timelines, scheduleStatus);
        return;
      }
      return;
    });

    return;
  }

  Future<void> _onReviseSchedule(
      ReviseScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    List<SubCalendarEvent>? subEvents;
    List<Timeline>? timelines;
    Timeline? lookupTimeline;
    String? message;
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.lookupTimeline;
      message = event.message;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleEvaluationState) {
      Duration durationSinceLastCall =
          Utility.currentTime().difference(state.evaluationTime);
      if (durationSinceLastCall.inSeconds < Utility.thirtySeconds.inSeconds) {
        return;
      }
      subEvents = state.subEvents;
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      lookupTimeline = state.lookupTimeline;
      message = event.message;
    }

    if (state is ScheduleInitialState) {
      subEvents = [];
      timelines = [];
      lookupTimeline = Utility.initialScheduleTimeline;
      scheduleStatus = ScheduleStatus();
      message = event.message;
    }

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
