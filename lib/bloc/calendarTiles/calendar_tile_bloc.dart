import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';

import '../../data/calendarEvent.dart';

part 'calendar_tile_event.dart';
part 'calendar_tile_state.dart';

class CalendarTileBloc extends Bloc<CalendarTileEvent, CalendarTileState> {
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  CalendarTileBloc() : super(CalendarTileInitial()) {
    on<CalendarTileAsNowEvent>(_onSetAsNowCalendarTileEvent);

    on<DeleteCalendarTileEvent>(_onDeleteCalendarTileEvent);

    on<CompleteCalendarTileEvent>(_onCompleteCalendarTileEvent);

    on<GetCalendarTileEvent>(_onGetCalendarTileEvent);
  }

  _onSetAsNowCalendarTileEvent(
      CalendarTileAsNowEvent event, Emitter<CalendarTileState> emit) async {
    emit(CalendarTileInitial());
    await calendarEventApi.setAsNow(event.calEventId).then((value) {
      emit(CalendarTileLoaded(calEvent: value));
    });
  }

  _onCompleteCalendarTileEvent(
      CompleteCalendarTileEvent event, Emitter<CalendarTileState> emit) async {
    emit(CalendarTileInitial());
    await calendarEventApi.complete(event.calEventId).then((value) {
      emit(CalendarTileLoaded(calEvent: value));
    });
  }

  _onDeleteCalendarTileEvent(
      DeleteCalendarTileEvent event, Emitter<CalendarTileState> emit) async {
    emit(CalendarTileInitial());
    await calendarEventApi
        .delete(event.calEventId, event.thirdPartyId)
        .then((value) {
      emit(CalendarTileLoaded(calEvent: value));
    });
  }

  _onGetCalendarTileEvent(
      GetCalendarTileEvent event, Emitter<CalendarTileState> emit) async {
    emit(CalendarTileLoading(calEventId: event.calEventId));
    await calendarEventApi.getCalEvent(event.calEventId).then((value) async {
      emit(CalendarTileLoaded(calEvent: value));
    });
  }
}
