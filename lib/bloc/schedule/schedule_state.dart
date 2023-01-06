part of 'schedule_bloc.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitialState extends ScheduleState {}

class ScheduleLoadingState extends ScheduleState {
  List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline? previousLookupTimeline;
  bool isAlreadyLoaded = true;
  String? message;
  ConnectionState connectionState = ConnectionState.none;

  ScheduleLoadingState(
      {this.subEvents = const <SubCalendarEvent>[],
      this.timelines = const <Timeline>[],
      required this.isAlreadyLoaded,
      required this.connectionState,
      this.previousLookupTimeline,
      this.message});

  @override
  List<Object> get props => [subEvents];
}

class ScheduleLoadedState extends ScheduleState {
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;

  ScheduleLoadedState(
      {this.subEvents = const <SubCalendarEvent>[],
      required this.timelines,
      required this.lookupTimeline});

  @override
  List<Object> get props => [subEvents];
}

class ScheduleEvaluationState extends ScheduleState {
  String? message;
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;

  ScheduleEvaluationState(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      this.message});

  @override
  List<Object> get props => [subEvents];
}
