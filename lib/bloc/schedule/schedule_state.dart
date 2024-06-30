// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'schedule_bloc.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];

  static PriorScheduleState generatePriorScheduleState(ScheduleState state) {
    List<SubCalendarEvent> subEvents = [];
    List<Timeline> timelines = [];
    Timeline lookupTimeline = Utility.initialScheduleTimeline;
    DateTime loadingTime = DateTime.fromMillisecondsSinceEpoch(0);
    ScheduleStatus scheduleStatus = ScheduleStatus.fromJson({});
    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.lookupTimeline;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.lookupTimeline;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.previousLookupTimeline;
      loadingTime = state.loadingTime;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleInitialState) {
      subEvents = [];
      timelines = [];
      lookupTimeline = Utility.initialScheduleTimeline;
      scheduleStatus = ScheduleStatus.fromJson({});
    }

    return PriorScheduleState(
        loadingTime: loadingTime,
        previousLookupTimeline: lookupTimeline,
        subEvents: subEvents,
        timelines: timelines,
        scheduleStatus: scheduleStatus);
  }
}

class ScheduleInitialState extends ScheduleState {}

class ScheduleLoggedOutState extends ScheduleState {}

class PriorScheduleState {
  final DateTime loadingTime;
  final List<SubCalendarEvent> subEvents;
  final List<Timeline> timelines;
  final Timeline previousLookupTimeline;
  final ScheduleStatus scheduleStatus;
  PriorScheduleState(
      {required this.loadingTime,
      required this.previousLookupTimeline,
      required this.subEvents,
      required this.timelines,
      required this.scheduleStatus});
}

class ScheduleLoadingState extends ScheduleState {
  DateTime loadingTime;
  List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  final Timeline previousLookupTimeline;
  bool isAlreadyLoaded = true;
  String? message;
  String? eventId;
  ScheduleStatus scheduleStatus;
  ConnectionState connectionState = ConnectionState.none;

  ScheduleLoadingState(
      {this.subEvents = const <SubCalendarEvent>[],
      this.timelines = const <Timeline>[],
      required this.isAlreadyLoaded,
      required this.connectionState,
      required this.loadingTime,
      required this.scheduleStatus,
      required this.previousLookupTimeline,
      this.eventId,
      this.message});

  @override
  List<Object> get props => [subEvents];
}

class ScheduleLoadedState extends ScheduleState {
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;
  Timeline? previousLookupTimeline;
  ScheduleStatus scheduleStatus;
  String? eventId;

  ScheduleLoadedState(
      {this.subEvents = const <SubCalendarEvent>[],
      required this.timelines,
      required this.lookupTimeline,
      required this.scheduleStatus,
      required this.previousLookupTimeline,
      this.eventId});

  @override
  List<Object> get props => [];
}

class DelayedScheduleLoadedState extends ScheduleLoadedState {
  StreamSubscription pendingDelayedScheduleRetrieval;
  DelayedScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required this.pendingDelayedScheduleRetrieval,
      required scheduleStatus,
      previousLookupTimeline})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline);
}

class FailedScheduleLoadedState extends ScheduleLoadedState {
  DateTime evaluationTime;
  FailedScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required this.evaluationTime,
      required scheduleStatus,
      previousLookupTimeline,
      eventId})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline,
            eventId: eventId);
}

class LocalScheduleLoadedState extends ScheduleLoadedState {
  LocalScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required scheduleStatus,
      previousLookupTimeline,
      eventId})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline,
            eventId: eventId);
}

class ScheduleEvaluationState extends ScheduleState {
  DateTime evaluationTime;
  String? message;
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;
  ScheduleStatus scheduleStatus;
  Timeline? previousLookupTimeline;

  ScheduleEvaluationState(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      required this.evaluationTime,
      this.message,
      required this.scheduleStatus,
      this.previousLookupTimeline});

  @override
  List<Object> get props => [subEvents];
}
