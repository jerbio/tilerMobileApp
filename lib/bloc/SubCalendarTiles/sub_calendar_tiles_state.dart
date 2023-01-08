part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTileState extends Equatable {
  const SubCalendarTileState();

  @override
  List<Object> get props => [];
}

class SubCalendarTilesInitialState extends SubCalendarTileState {}

class SubCalendarTilesLoadingState extends SubCalendarTileState {
  final String subEventId;

  SubCalendarTilesLoadingState({required this.subEventId});

  @override
  List<Object> get props => [subEventId];
}

class SubCalendarTileLoadedState extends SubCalendarTileState {
  final SubCalendarEvent subEvent;
  SubCalendarTileLoadedState({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}
