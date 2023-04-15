part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTileEvent extends Equatable {
  const SubCalendarTileEvent();

  @override
  List<Object> get props => [];
}

class GetSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  String subEventId;
  SubCalendarEvent? subEvent;

  GetSubCalendarTileBlocEvent({required this.subEventId, this.subEvent});

  @override
  List<Object> get props => [subEventId];
}

class NewSubCalendarTileBlocEvent extends SubCalendarTileEvent {
  SubCalendarEvent? subEvent;

  NewSubCalendarTileBlocEvent({required this.subEvent});

  @override
  List<Object> get props => subEvent == null ? [] : [subEvent!];
}

class GetListOfSubCalendarTilesBlocEvent extends SubCalendarTileEvent {
  List<String> subEventIds;
  List<SubCalendarEvent>? subEvents;

  GetListOfSubCalendarTilesBlocEvent(
      {required this.subEventIds, this.subEvents});

  @override
  List<Object> get props => subEventIds.toList();
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
