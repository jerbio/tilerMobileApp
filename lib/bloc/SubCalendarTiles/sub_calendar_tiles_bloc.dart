import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tuple/tuple.dart';

part 'sub_calendar_tiles_event.dart';
part 'sub_calendar_tiles_state.dart';

class SubCalendarTileBloc
    extends Bloc<SubCalendarTileEvent, SubCalendarTileState> {
  SubCalendarEventApi subCalendarEventApi = SubCalendarEventApi();
  SubCalendarTileBloc() : super(SubCalendarTilesInitialState()) {
    on<GetSubCalendarTileBlocEvent>(_onLoadSubCalendarTile);
    on<ResetSubCalendarTileBlocEvent>(_onResetSubCalendarTile);
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
}
