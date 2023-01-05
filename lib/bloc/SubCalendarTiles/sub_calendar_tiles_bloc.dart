import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

part 'sub_calendar_tiles_event.dart';
part 'sub_calendar_tiles_state.dart';

class SubCalendarTilesBloc
    extends Bloc<SubCalendarTilesEvent, SubCalendarTilesState> {
  ScheduleApi scheduleApi = ScheduleApi();
  SubCalendarTilesBloc() : super(SubCalendarTilesInitialState()) {
    on<LoadSubCalendarTiles>(_onLoadSubCalendarTile);
    on<AddSubCalendarTile>(_onAdddSubCalendarTile);
    on<UpdateSchedule>(_onUpdateSchedule);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubTiles(
      Timeline timeLine) async {
    return await scheduleApi.getSubEvents(timeLine);
  }

  void _onLoadSubCalendarTile(
      LoadSubCalendarTiles event, Emitter<SubCalendarTilesState> emit) async {
    final state = this.state;
    if (state is SubCalendarTilesLoadedState) {
      emit(SubCalendarTilesLoadingState(
          subEvents: state.subEvents,
          timelines: state.timelines,
          isAlreadyLoaded: true,
          previousLookupTimeline: state.lookupTimeline,
          connectionState: ConnectionState.waiting));
    }

    if (state is SubCalendarTilesInitialState) {
      emit(SubCalendarTilesLoadingState(
          subEvents: [],
          timelines: [],
          isAlreadyLoaded: false,
          connectionState: ConnectionState.waiting));
    }

    await getSubTiles(event.scheduleTimeline).then((value) {
      emit(SubCalendarTilesLoadedState(
          subEvents: value.item2,
          timelines: value.item1,
          lookupTimeline: event.scheduleTimeline));
    });
  }

  void _onAdddSubCalendarTile(
      AddSubCalendarTile event, Emitter<SubCalendarTilesState> emit) async {
    final state = this.state;

    if (state is SubCalendarTilesLoadedState) {
      Timeline timeline = state.lookupTimeline;
      Timeline updateTimeline = timeline;

      if (!timeline.isInterfering(event.subEvent)) {
        double startInMs = event.subEvent.start! < updateTimeline.startInMs!
            ? event.subEvent.start!
            : updateTimeline.startInMs!;
        double endInMs = event.subEvent.end! > updateTimeline.endInMs!
            ? event.subEvent.end!
            : updateTimeline.endInMs!;

        updateTimeline = Timeline.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(startInMs.toInt(), isUtc: true),
            DateTime.fromMillisecondsSinceEpoch(endInMs.toInt(), isUtc: true));
      }
      emit(SubCalendarTilesLoadingState(
          subEvents: List.from(state.subEvents),
          timelines: state.timelines,
          previousLookupTimeline: timeline,
          isAlreadyLoaded: true,
          connectionState: ConnectionState.waiting));
      await getSubTiles(timeline).then((value) {
        emit(SubCalendarTilesLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: timeline));
      });
      return;
    }

    if (state is SubCalendarTilesInitialState) {
      emit(SubCalendarTilesLoadingState(
          subEvents: [],
          timelines: [],
          isAlreadyLoaded: false,
          connectionState: ConnectionState.waiting));
      return;
    }
  }

  void _onUpdateSchedule(
      UpdateSchedule event, Emitter<SubCalendarTilesState> emit) async {
    final state = this.state;

    if (state is SubCalendarTilesLoadedState) {
      Timeline timeline = state.lookupTimeline;
      Timeline updateTimeline = timeline;

      if (event.scheduleTimeline != null &&
          !timeline.isInterfering(event.scheduleTimeline!)) {
        double startInMs =
            event.scheduleTimeline!.start! < updateTimeline.startInMs!
                ? event.scheduleTimeline!.start!
                : updateTimeline.startInMs!;
        double endInMs = event.scheduleTimeline!.end! > updateTimeline.endInMs!
            ? event.scheduleTimeline!.end!
            : updateTimeline.endInMs!;

        updateTimeline = Timeline.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(startInMs.toInt(), isUtc: true),
            DateTime.fromMillisecondsSinceEpoch(endInMs.toInt(), isUtc: true));
      }
      emit(SubCalendarTilesLoadingState(
          subEvents: List.from(state.subEvents),
          timelines: state.timelines,
          previousLookupTimeline: timeline,
          isAlreadyLoaded: true,
          message: event.message,
          connectionState: ConnectionState.waiting));
      await getSubTiles(timeline).then((value) {
        emit(SubCalendarTilesLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: timeline));
      });
      return;
    }

    if (state is SubCalendarTilesInitialState) {
      emit(SubCalendarTilesLoadingState(
          subEvents: [],
          timelines: [],
          isAlreadyLoaded: false,
          connectionState: ConnectionState.waiting));
      return;
    }
  }
}
