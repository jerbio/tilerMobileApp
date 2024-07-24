// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'schedule_bloc.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitialState extends ScheduleState {}

class ScheduleLoggedOutState extends ScheduleState {}

class ScheduleLoadingState extends ScheduleState {
  DateTime loadingTime;
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
      required this.loadingTime,
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

class DelayedScheduleLoadedState extends ScheduleLoadedState {
  StreamSubscription pendingDelayedScheduleRetrieval;
  DelayedScheduleLoadedState({
    subEvents = const <SubCalendarEvent>[],
    required timelines,
    required lookupTimeline,
    required this.pendingDelayedScheduleRetrieval,
  }) : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline);
}

class ScheduleLoadingTaskState extends ScheduleState {
  @override
  List<Object> get props => [];
}

class ScheduleCompleteTaskState extends ScheduleState {
  final SubCalendarEvent completedEvent;

  ScheduleCompleteTaskState({required this.completedEvent});

  @override
  List<Object> get props => [completedEvent];
}

class FailedScheduleLoadedState extends ScheduleLoadedState {
  DateTime evaluationTime;
  FailedScheduleLoadedState({
    subEvents = const <SubCalendarEvent>[],
    required timelines,
    required lookupTimeline,
    required this.evaluationTime,
  }) : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline);
}

class ScheduleEvaluationState extends ScheduleState {
  DateTime evaluationTime;
  String? message;
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;

  ScheduleEvaluationState(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      required this.evaluationTime,
      this.message});

  @override
  List<Object> get props => [subEvents];
}
