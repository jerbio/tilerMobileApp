part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTilesEvent extends Equatable {
  const SubCalendarTilesEvent();

  @override
  List<Object> get props => [];
}

class GetSubCalendarTiles extends SubCalendarTilesEvent {
  String subEventId;
  SubCalendarEvent? subEvent;

  GetSubCalendarTiles({required this.subEventId, this.subEvent});

  @override
  List<Object> get props => [subEventId];
}

class AddSubCalendarTile extends SubCalendarTilesEvent {
  final SubCalendarEvent subEvent;
  const AddSubCalendarTile({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class UpdateSubCalendarTile extends SubCalendarTilesEvent {
  final SubCalendarEvent subEvent;
  const UpdateSubCalendarTile({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class DeleteSubCalendarTile extends SubCalendarTilesEvent {
  final SubCalendarEvent subEvent;
  const DeleteSubCalendarTile({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}
