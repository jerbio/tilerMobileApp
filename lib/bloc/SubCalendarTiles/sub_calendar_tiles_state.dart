part of 'sub_calendar_tiles_bloc.dart';

abstract class SubCalendarTilesState extends Equatable {
  const SubCalendarTilesState();

  @override
  List<Object> get props => [];
}

class SubCalendarTilesInitialState extends SubCalendarTilesState {}

class SubCalendarTilesLoadingState extends SubCalendarTilesState {
  List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline? previousLookupTimeline;
  bool isAlreadyLoaded = true;
  String? message;
  ConnectionState connectionState = ConnectionState.none;

  SubCalendarTilesLoadingState(
      {this.subEvents = const <SubCalendarEvent>[],
      this.timelines = const <Timeline>[],
      required this.isAlreadyLoaded,
      required this.connectionState,
      this.previousLookupTimeline,
      this.message});

  @override
  List<Object> get props => [subEvents];
}

class SubCalendarTilesLoadedState extends SubCalendarTilesState {
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;

  SubCalendarTilesLoadedState(
      {this.subEvents = const <SubCalendarEvent>[],
      required this.timelines,
      required this.lookupTimeline});

  @override
  List<Object> get props => [subEvents];
}
