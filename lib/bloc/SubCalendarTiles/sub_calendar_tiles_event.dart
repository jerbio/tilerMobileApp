part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTileEvent extends Equatable {
  const SubCalendarTileEvent();

  @override
  List<Object> get props => [];
}

class GetSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final String subEventId;
  final String? calendarSource;
  final String? thirdPartyUserId;
  SubCalendarEvent? subEvent;

  GetSubCalendarTileBlocEvent(
      {required this.subEventId,
      this.subEvent,
      this.calendarSource,
      this.thirdPartyUserId});

  @override
  List<Object> get props => [subEventId];
}

class NewSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final SubCalendarEvent? subEvent;

  NewSubCalendarTileBlocEvent({required this.subEvent});

  @override
  List<Object> get props => subEvent == null ? [] : [subEvent!];
}

class GetListOfSubCalendarTilesBlocEvent extends SubCalendarTileEvent {
  final List<String> subEventIds;
  final List<SubCalendarEvent>? subEvents;
  final String? requestId;

  GetListOfSubCalendarTilesBlocEvent(
      {required this.subEventIds, this.subEvents, this.requestId});

  @override
  List<Object> get props => subEventIds.toList();
}

class GetListOfCalendarTilesSubTilesBlocEvent extends SubCalendarTileEvent {
  final String calEventId;
  final String? requestId;
  final List<SubCalendarEvent>? subEvents;

  GetListOfCalendarTilesSubTilesBlocEvent(
      {required this.calEventId, this.subEvents, this.requestId});

  @override
  List<Object> get props => [];
}

class AddSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final SubCalendarEvent subEvent;
  const AddSubCalendarTileBlocEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class UpdateSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final SubCalendarEvent subEvent;
  const UpdateSubCalendarTileBlocEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class DeleteSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final SubCalendarEvent subEvent;
  const DeleteSubCalendarTileBlocEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class ResetSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  const ResetSubCalendarTileBlocEvent();

  @override
  List<Object> get props => [];
}

class ListOfSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  final List<SubCalendarEvent> subEvents;
  ListOfSubCalendarTileBlocEvent({required this.subEvents});

  @override
  List<Object> get props => [];
}

class LogOutSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  const LogOutSubCalendarTileBlocEvent();

  @override
  List<Object> get props => [];
}
