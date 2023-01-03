part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTilesEvent extends Equatable {
  const SubCalendarTilesEvent();

  @override
  List<Object> get props => [];
}

class LoadSubCalendarTiles extends SubCalendarTilesEvent {
  final List<SubCalendarEvent> previousSubEvents;
  final Timeline scheduleTimeline;
  final bool isAlreadyLoaded;
  Timeline? previousTimeline;

  LoadSubCalendarTiles(
      {required this.previousSubEvents,
      required this.scheduleTimeline,
      required this.isAlreadyLoaded,
      this.previousTimeline});

  @override
  List<Object> get props => [previousSubEvents, scheduleTimeline];
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

class UpdateSchedule extends SubCalendarTilesEvent {
  Timeline? scheduleTimeline;
  String? message;
  SubCalendarEvent? triggerTile;
  UpdateSchedule({this.scheduleTimeline, this.message, this.triggerTile});

  @override
  List<Object> get props => [];
}
