// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'schedule_bloc.dart';

abstract class ScheduleState extends Equatable {
  final AuthorizedRouteTileListPage currentView;
  const ScheduleState({this.currentView = AuthorizedRouteTileListPage.Daily});

  @override
  List<Object> get props => [currentView];

  static PriorScheduleState generatePriorScheduleState(ScheduleState state) {
    List<SubCalendarEvent> subEvents = [];
    List<Timeline> timelines = [];
    Timeline lookupTimeline = Utility.initialScheduleTimeline;
    DateTime loadingTime = DateTime.fromMillisecondsSinceEpoch(0);
    ScheduleStatus scheduleStatus = ScheduleStatus.fromJson({});
    AuthorizedRouteTileListPage currentView = state.currentView;
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
        scheduleStatus: scheduleStatus,
        currentView: currentView
    );
  }
}

class ScheduleInitialState extends ScheduleState {
  final AuthorizedRouteTileListPage currentView;
  ScheduleInitialState({required this.currentView})
      : super(currentView: currentView);
}

class ScheduleLoggedOutState extends ScheduleState {
  ScheduleLoggedOutState({AuthorizedRouteTileListPage currentView = AuthorizedRouteTileListPage.Daily})
      : super(currentView: currentView);
}

class PriorScheduleState {
  final DateTime loadingTime;
  final List<SubCalendarEvent> subEvents;
  final List<Timeline> timelines;
  final Timeline previousLookupTimeline;
  final ScheduleStatus scheduleStatus;
  final AuthorizedRouteTileListPage currentView;
  PriorScheduleState(
      {required this.loadingTime,
      required this.previousLookupTimeline,
      required this.subEvents,
      required this.timelines,
      required this.scheduleStatus,
      required this.currentView
      });
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
  AuthorizedRouteTileListPage currentView;

  ScheduleLoadingState(
      {this.subEvents = const <SubCalendarEvent>[],
      this.timelines = const <Timeline>[],
      required this.isAlreadyLoaded,
      required this.connectionState,
      required this.loadingTime,
      required this.scheduleStatus,
      required this.previousLookupTimeline,
      required this.currentView,
      this.eventId,
      this.message
      }) : super(currentView: currentView);

  @override
  List<Object> get props => [subEvents,currentView];
}

class ScheduleLoadedState extends ScheduleState {
  final List<SubCalendarEvent> subEvents;
  List<Timeline> timelines;
  Timeline lookupTimeline;
  Timeline? previousLookupTimeline;
  ScheduleStatus scheduleStatus;
  String? eventId;
  AuthorizedRouteTileListPage currentView;

  ScheduleLoadedState(
      {this.subEvents = const <SubCalendarEvent>[],
      required this.timelines,
      required this.lookupTimeline,
      required this.scheduleStatus,
      required this.previousLookupTimeline,
      required this.currentView,
      this.eventId}): super(currentView: currentView);

  @override
  List<Object> get props => [currentView];
}

class DelayedScheduleLoadedState extends ScheduleLoadedState {
  StreamSubscription pendingDelayedScheduleRetrieval;
  DelayedScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required this.pendingDelayedScheduleRetrieval,
      required scheduleStatus,
      required currentView,
      previousLookupTimeline})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline,
            currentView: currentView
      );
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
  FailedScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required this.evaluationTime,
      required scheduleStatus,
      required currentView,
      previousLookupTimeline,
      eventId})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline,
            currentView: currentView,
            eventId: eventId);
}

class LocalScheduleLoadedState extends ScheduleLoadedState {
  LocalScheduleLoadedState(
      {subEvents = const <SubCalendarEvent>[],
      required timelines,
      required lookupTimeline,
      required scheduleStatus,
      required currentView,
      previousLookupTimeline,
      eventId})
      : super(
            subEvents: subEvents,
            timelines: timelines,
            lookupTimeline: lookupTimeline,
            scheduleStatus: scheduleStatus,
            previousLookupTimeline: previousLookupTimeline,
            currentView: currentView,
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
  AuthorizedRouteTileListPage currentView;

  ScheduleEvaluationState(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      required this.evaluationTime,
      required this.currentView,
      this.message,
      required this.scheduleStatus,
      this.previousLookupTimeline});

  @override
  List<Object> get props => [subEvents,currentView];
}

