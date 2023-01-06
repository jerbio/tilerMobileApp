import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tuple/tuple.dart';

part 'sub_calendar_tiles_event.dart';
part 'sub_calendar_tiles_state.dart';

class SubCalendarTilesBloc
    extends Bloc<SubCalendarTilesEvent, SubCalendarTilesState> {
  ScheduleApi scheduleApi = ScheduleApi();
  SubCalendarEventApi subCalendarEventApi = SubCalendarEventApi();
  SubCalendarTilesBloc() : super(SubCalendarTilesInitialState()) {
    on<GetSubCalendarTiles>(_onLoadSubCalendarTile);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubTiles(
      Timeline timeLine) async {
    return await scheduleApi.getSubEvents(timeLine);
  }

  void _onLoadSubCalendarTile(
      GetSubCalendarTiles event, Emitter<SubCalendarTilesState> emit) async {
    final state = this.state;
    if (state is SubCalendarTilesLoadedState) {
      emit(SubCalendarTilesLoadingState(subEventId: state.subEvent.id!));
    }

    if (state is SubCalendarTilesInitialState) {
      emit(SubCalendarTilesLoadingState(
          subEventId: event.subEvent?.id ?? event.subEventId));
    }

    await subCalendarEventApi
        .getSubEvent(event.subEvent?.id ?? event.subEventId)
        .then((value) {
      emit(SubCalendarTilesLoadedState(subEvent: value));
    });
  }
}
