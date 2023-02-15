import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleApi scheduleApi = ScheduleApi();
  ScheduleBloc() : super(ScheduleInitialState()) {
    on<GetSchedule>(_onGetSchedule);
    on<DelayedGetSchedule>(_onDelayedGetSchedule);
    on<ReloadLocalScheduleEvent>(_onLocalScheduleEvent);
    on<DelayedReloadLocalScheduleEvent>(_onDelayedReloadLocalScheduleEvent);
    on<ReviseScheduleEvent>(_onReviseSchedule);
    on<EvaluateSchedule>(_onEvaluateSchedule);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubTiles(
      Timeline timeLine) async {
    return await scheduleApi.getSubEvents(timeLine);
  }

  void _onLocalScheduleEvent(
      ReloadLocalScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        lookupTimeline: event.lookupTimeline));
  }

  void _onDelayedReloadLocalScheduleEvent(DelayedReloadLocalScheduleEvent event,
      Emitter<ScheduleState> emit) async {
    var setTimeOutResult = Utility.setTimeOut(duration: event.duration);

    emit(DelayedScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        lookupTimeline: event.lookupTimeline,
        pendingDelayedScheduleRetrieval:
            setTimeOutResult.item1.asStream().listen((futureEvent) async {})));

    await setTimeOutResult.item1.then((futureEvent) async {
      emit(ScheduleLoadedState(
          subEvents: event.subEvents,
          timelines: event.timelines,
          lookupTimeline: event.lookupTimeline));
    });
  }

  Future<void> _onGetSchedule(
      GetSchedule event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    Timeline updateTimeline =
        event.scheduleTimeline ?? Utility.initialScheduleTimeline;

    if (state is ScheduleLoadedState) {
      Timeline timeline = state.lookupTimeline;
      updateTimeline = event.scheduleTimeline ?? state.lookupTimeline;
      List<SubCalendarEvent> subEvents = [];

      if (!timeline.isInterfering(updateTimeline)) {
        double startInMs = updateTimeline.start! < timeline.startInMs!
            ? updateTimeline.start!
            : timeline.startInMs!;
        double endInMs = updateTimeline.end! > timeline.endInMs!
            ? updateTimeline.end!
            : timeline.endInMs!;

        updateTimeline = Timeline.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(startInMs.toInt(), isUtc: true),
            DateTime.fromMillisecondsSinceEpoch(endInMs.toInt(), isUtc: true));
      }
      emit(ScheduleLoadingState(
          subEvents: List.from(state.subEvents),
          timelines: state.timelines,
          previousLookupTimeline: timeline,
          isAlreadyLoaded: true,
          connectionState: ConnectionState.waiting));
      await getSubTiles(updateTimeline).then((value) {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }

    if (state is ScheduleInitialState) {
      emit(ScheduleLoadingState(
          subEvents: [],
          timelines: [],
          isAlreadyLoaded: false,
          connectionState: ConnectionState.waiting));

      await getSubTiles(updateTimeline).then((value) {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }

    if (state is ScheduleEvaluationState) {
      emit(ScheduleLoadingState(
          subEvents: state.subEvents,
          timelines: state.timelines,
          previousLookupTimeline: state.lookupTimeline,
          isAlreadyLoaded: true,
          connectionState: ConnectionState.waiting));

      await getSubTiles(updateTimeline).then((value) async {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }
  }

  Future<void> _onReviseSchedule(
      ReviseScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    if (state is ScheduleLoadedState) {
      emit(ScheduleEvaluationState(
          subEvents: state.subEvents,
          timelines: state.timelines,
          lookupTimeline: state.lookupTimeline,
          message: event.message));
      await this.scheduleApi.reviseSchedule().then((value) async {
        await this._onGetSchedule(
            GetSchedule(
              isAlreadyLoaded: true,
              previousSubEvents: state.subEvents,
              previousTimeline: state.lookupTimeline,
              scheduleTimeline: state.lookupTimeline,
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
        message: event.message));
    if (event.callBack != null) {
      await event.callBack!.whenComplete(() async {
        await this._onGetSchedule(
            GetSchedule(
              isAlreadyLoaded: true,
              previousSubEvents: event.renderedSubEvents,
              previousTimeline: event.renderedScheduleTimeline,
              scheduleTimeline: event.renderedScheduleTimeline,
            ),
            emit);
      });
    }
  }

  void _onDelayedGetSchedule(
      DelayedGetSchedule event, Emitter<ScheduleState> emit) async {
    var setTimeOutResult = Utility.setTimeOut(duration: event.delayDuration!);

    emit(DelayedScheduleLoadedState(
        subEvents: event.previousSubEvents,
        timelines: event.renderedTimelines,
        lookupTimeline: event.scheduleTimeline,
        pendingDelayedScheduleRetrieval:
            setTimeOutResult.item1.asStream().listen((futureEvent) async {})));

    await setTimeOutResult.item1.then((futureEvent) async {
      await this._onGetSchedule(
          GetSchedule(
            isAlreadyLoaded: true,
            previousSubEvents: event.previousSubEvents,
            previousTimeline: event.previousTimeline,
            scheduleTimeline: event.scheduleTimeline,
          ),
          emit);
    });
  }
}
