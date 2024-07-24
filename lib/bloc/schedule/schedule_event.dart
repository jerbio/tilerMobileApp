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
  Timeline? previousTimeline;
  String? message;
  GetScheduleEvent(
      {this.previousSubEvents,
      this.scheduleTimeline,
      this.isAlreadyLoaded,
      this.previousTimeline,
      this.message,
      this.forceRefresh = false});

  @override
  List<Object> get props => [];
}

class CompleteTaskEvent extends ScheduleEvent {
  final SubCalendarEvent subEvent;

  CompleteTaskEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}

class DelayedGetSchedule extends ScheduleEvent {
  final List<SubCalendarEvent>? previousSubEvents;
  final List<Timeline>? renderedTimelines;
  final Timeline? scheduleTimeline;
  final bool? isAlreadyLoaded;
  Timeline? previousTimeline;
  String? message;
  Duration? delayDuration;
  DelayedGetSchedule(
      {this.previousSubEvents,
      this.scheduleTimeline,
      this.isAlreadyLoaded,
      this.previousTimeline,
      this.message,
      this.delayDuration,
      this.renderedTimelines});

  @override
  List<Object> get props => [];
}

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
  String? message;
  final List<SubCalendarEvent> renderedSubEvents;
  final List<Timeline> renderedTimelines;
  final Timeline renderedScheduleTimeline;
  final bool isAlreadyLoaded;
  final Future? callBack;
  EvaluateSchedule(
      {required this.renderedSubEvents,
      required this.renderedTimelines,
      required this.renderedScheduleTimeline,
      required this.isAlreadyLoaded,
      this.message,
      this.callBack});

  @override
  List<Object> get props => [];
}

class ReloadLocalScheduleEvent extends ScheduleEvent {
  final List<SubCalendarEvent> subEvents;
  final List<Timeline> timelines;
  final Timeline lookupTimeline;
  ReloadLocalScheduleEvent(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline});
}

class DelayedReloadLocalScheduleEvent extends ScheduleEvent {
  final List<SubCalendarEvent> subEvents;
  final List<Timeline> timelines;
  final Timeline lookupTimeline;
  final Duration duration;
  DelayedReloadLocalScheduleEvent(
      {required this.subEvents,
      required this.timelines,
      required this.lookupTimeline,
      required this.duration});
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
