part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class GetScheduleEvent extends ScheduleEvent {
  final List<SubCalendarEvent>? previousSubEvents;
  final Timeline? scheduleTimeline;
  final bool? isAlreadyLoaded;
  bool forceRefresh = false;
  bool emitOnlyLoadedStated = false;
  Timeline? previousTimeline;
  String? message;
  String? eventId;
  GetScheduleEvent(
      {this.previousSubEvents,
      this.scheduleTimeline,
      this.isAlreadyLoaded,
      this.previousTimeline,
      this.message,
      this.eventId,
      this.forceRefresh = false,
      this.emitOnlyLoadedStated = false});

  @override
  List<Object> get props => [];
}

class CompleteTaskEvent extends ScheduleEvent {
  final SubCalendarEvent subEvent;

  CompleteTaskEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

// class AdHocScheduleEvent extends ScheduleEvent {
//   final List<SubCalendarEvent>? previousSubEvents;
//   final Timeline? scheduleTimeline;
//   final bool? isAlreadyLoaded;
//   bool forceRefresh = false;
//   Timeline? previousTimeline;
//   String? message;
//   String? eventId;
//   AdHocScheduleEvent(
//       {this.previousSubEvents,
//       this.scheduleTimeline,
//       this.isAlreadyLoaded,
//       this.previousTimeline,
//       this.message,
//       this.eventId,
//       this.forceRefresh = false});

//   @override
//   List<Object> get props => [];
// }

// class DelayedGetSchedule extends ScheduleEvent {
//   final List<SubCalendarEvent> previousSubEvents;
//   final List<Timeline> renderedTimelines;
//   final Timeline scheduleTimeline;
//   final bool isAlreadyLoaded;
//   final Timeline previousTimeline;
//   final String? message;
//   final Duration delayDuration;
//   final ScheduleStatus scheduleStatus;
//   DelayedGetSchedule(
//       {required this.previousSubEvents,
//       required this.scheduleTimeline,
//       required this.isAlreadyLoaded,
//       required this.previousTimeline,
//       this.message,
//       required this.delayDuration,
//       required this.renderedTimelines,
//       required this.scheduleStatus});

//   @override
//   List<Object> get props => [];
// }

class ReviseScheduleEvent extends ScheduleEvent {
  String? message;
  ReviseScheduleEvent({this.message});

  @override
  List<Object> get props => [];
}

class ShuffleScheduleEvent extends ScheduleEvent {
  String? message;
  ShuffleScheduleEvent({this.message});

  @override
  List<Object> get props => [];
}

class EvaluateSchedule extends ScheduleEvent {
  final String? message;
  final List<SubCalendarEvent> renderedSubEvents;
  final List<Timeline> renderedTimelines;
  final Timeline renderedScheduleTimeline;
  final bool isAlreadyLoaded;
  final Future? callBack;
  final ScheduleStatus scheduleStatus;
  EvaluateSchedule(
      {required this.renderedSubEvents,
      required this.renderedTimelines,
      required this.renderedScheduleTimeline,
      required this.isAlreadyLoaded,
      required this.scheduleStatus,
      this.message,
      this.callBack});

  @override
  List<Object> get props => [];
}

class ReloadLocalScheduleEvent extends ScheduleEvent {
  final List<SubCalendarEvent> subEvents;
  final List<Timeline> timelines;
  final ScheduleStatus scheduleStatus;
  final Timeline lookupTimeline;
  Timeline? previousLookupTimeline;
  ReloadLocalScheduleEvent(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      required this.scheduleStatus,
      this.previousLookupTimeline});
}

// class DelayedReloadLocalScheduleEvent extends ScheduleEvent {
//   final List<SubCalendarEvent> subEvents;
//   final List<Timeline> timelines;
//   final Timeline lookupTimeline;
//   final Duration duration;
//   final ScheduleStatus scheduleStatus;
//   DelayedReloadLocalScheduleEvent(
//       {required this.subEvents,
//       required this.timelines,
//       required this.lookupTimeline,
//       required this.duration,
//       required this.scheduleStatus});
// }

class ChangeViewEvent extends ScheduleEvent {
  final AuthorizedRouteTileListPage newView;

  ChangeViewEvent(this.newView, );

  @override
  List<Object> get props => [newView];

}

class LogOutScheduleEvent extends ScheduleEvent {
  LogOutScheduleEvent();

  @override
  List<Object> get props => [];
}

class LogInScheduleEvent extends ScheduleEvent {
  LogInScheduleEvent();
  @override
  List<Object> get props => [];
}
