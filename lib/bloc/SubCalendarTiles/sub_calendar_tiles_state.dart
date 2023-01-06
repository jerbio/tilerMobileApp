part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTilesState extends Equatable {
  const SubCalendarTilesState();

  @override
  List<Object> get props => [];
}

class SubCalendarTilesInitialState extends SubCalendarTilesState {}

class SubCalendarTilesLoadingState extends SubCalendarTilesState {
  String subEventId;
  SubCalendarEvent? subEvent;
  ConnectionState connectionState = ConnectionState.none;

  SubCalendarTilesLoadingState({required this.subEventId, this.subEvent});

  @override
  List<Object> get props => [subEventId];
}

class SubCalendarTilesLoadedState extends SubCalendarTilesState {
  final SubCalendarEvent subEvent;
  SubCalendarTilesLoadedState({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}
