import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tuple/tuple.dart';
import '../../constants.dart' as Constants;

part 'sub_calendar_tiles_event.dart';
part 'sub_calendar_tiles_state.dart';

class SubCalendarTileBloc
    extends Bloc<SubCalendarTileEvent, SubCalendarTileState> {
  SubCalendarEventApi subCalendarEventApi = SubCalendarEventApi();
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  SubCalendarTileBloc() : super(SubCalendarTilesInitialState()) {
    on<GetSubCalendarTileBlocEvent>(_onLoadSubCalendarTile);
    on<ResetSubCalendarTileBlocEvent>(_onResetSubCalendarTile);
    on<GetListOfSubCalendarTilesBlocEvent>(_onLoadListOfSubCalendarTiles);
    on<NewSubCalendarTileBlocEvent>(_onNewSubTileCreatedState);
    on<GetListOfCalendarTilesSubTilesBlocEvent>(
        _onLoadListOfSubCalendarByCalendarEventId);
    on<ListOfSubCalendarTileBlocEvent>(_onListOfSubTiles);
    on<LogOutSubCalendarTileBlocEvent>(_onLogOutSubTileCreatedState);
  }

  void _onResetSubCalendarTile(ResetSubCalendarTileBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    emit(SubCalendarTilesInitialState());
  }

  void _onLoadSubCalendarTile(GetSubCalendarTileBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    final state = this.state;
    if (state is SubCalendarTileLoadedState) {
      emit(SubCalendarTilesLoadingState(subEventId: state.subEvent.id!));
    }

    if (state is SubCalendarTilesInitialState) {
      emit(SubCalendarTilesLoadingState(
          subEventId: event.subEvent?.id ?? event.subEventId));
    }

    await subCalendarEventApi
        .getSubEvent(event.subEvent?.id ?? event.subEventId)
        .then((value) {
      emit(SubCalendarTileLoadedState(subEvent: value));
    });
  }

  void _onNewSubTileCreatedState(NewSubCalendarTileBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    emit(NewSubCalendarTilesLoadedState(subEvent: event.subEvent));
  }

  void _onLoadListOfSubCalendarByCalendarEventId(
      GetListOfCalendarTilesSubTilesBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    final state = this.state;
    List<String> subEventIds = [];
    List<SubCalendarEvent> subEvents = [];

    if (state is ListOfSubCalendarTilesLoadingState) {
      subEventIds = state.subEventIds;
      subEvents = state.subEvents ?? [];
    }

    if (state is SubCalendarTilesInitialState) {
      subEvents = event.subEvents ?? [];
    }
    emit(ListOfSubCalendarTilesLoadingState(
        subEventIds: subEventIds,
        subEvents: subEvents,
        requestId: event.requestId));

    await calendarEventApi.getSubEvents(event.calEventId).then((value) {
      emit(ListOfSubCalendarTileLoadedState(
          subEvents: value.toList(), requestId: event.requestId));
    });
  }

  void _onListOfSubTiles(ListOfSubCalendarTileBlocEvent event,
      Emitter<SubCalendarTileState> emit) {
    emit(ListOfSubCalendarTileLoadedState(subEvents: event.subEvents.toList()));
  }

  void _onLoadListOfSubCalendarTiles(GetListOfSubCalendarTilesBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    final state = this.state;
    if (state is ListOfSubCalendarTilesLoadingState) {
      emit(ListOfSubCalendarTilesLoadingState(
          subEventIds: state.subEventIds, subEvents: state.subEvents));
    }

    if (state is SubCalendarTilesInitialState) {
      emit(ListOfSubCalendarTilesLoadingState(
          subEventIds: event.subEventIds, subEvents: event.subEvents));
    }

    await subCalendarEventApi.getSubEvents(event.subEventIds).then((value) {
      emit(ListOfSubCalendarTileLoadedState(subEvents: value.toList()));
    });
  }

  void _onLogOutSubTileCreatedState(LogOutSubCalendarTileBlocEvent event,
      Emitter<SubCalendarTileState> emit) async {
    subCalendarEventApi = SubCalendarEventApi();
    emit(SubCalendarTilesLogOutState());
  }
}
