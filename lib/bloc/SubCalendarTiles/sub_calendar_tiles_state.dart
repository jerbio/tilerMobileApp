part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTileState extends Equatable {
  const SubCalendarTileState();

  @override
  List<Object> get props => [];
}

class SubCalendarTilesInitialState extends SubCalendarTileState {}

class SubCalendarTilesLogOutState extends SubCalendarTilesInitialState {}

class SubCalendarTilesLoggedOutState extends SubCalendarTilesInitialState {}

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

class ListOfSubCalendarTileLoadedState extends SubCalendarTileState {
  final List<SubCalendarEvent> subEvents;
  ListOfSubCalendarTileLoadedState({required this.subEvents}) {
    print(this.subEvents);
  }

  @override
  List<Object> get props => subEvents.map<String>((e) => e.id!).toList();
}

class ListOfSubCalendarTilesLoadingState extends SubCalendarTileState {
  final List<String> subEventIds;
  List<SubCalendarEvent>? subEvents;
  ListOfSubCalendarTilesLoadingState(
      {required this.subEventIds, this.subEvents});

  @override
  List<Object> get props => subEventIds.toList();
}

class NewSubCalendarTilesLoadedState extends SubCalendarTileState {
  final SubCalendarEvent? subEvent;
  NewSubCalendarTilesLoadedState({required this.subEvent});

  @override
  List<Object> get props => subEvent == null ? [] : [subEvent!];
}
