part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class GetSchedule extends ScheduleEvent {
  final List<SubCalendarEvent>? previousSubEvents;
  final Timeline? scheduleTimeline;
  final bool? isAlreadyLoaded;
  Timeline? previousTimeline;
  String? message;
  GetSchedule(
      {this.previousSubEvents,
      this.scheduleTimeline,
      this.isAlreadyLoaded,
      this.previousTimeline,
      this.message});

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
  EvaluateSchedule(
      {required this.renderedSubEvents,
      required this.renderedTimelines,
      required this.renderedScheduleTimeline,
      required this.isAlreadyLoaded,
      this.message});

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
