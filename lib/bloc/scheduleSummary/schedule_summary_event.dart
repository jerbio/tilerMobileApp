part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryEvent extends Equatable {
  const ScheduleSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetScheduleDaySummaryEvent extends ScheduleSummaryEvent {
  Timeline? timeline;
  String? requestId;
  List<TimelineSummary>? daySummarys;
  GetScheduleDaySummaryEvent({this.timeline, this.requestId});

  @override
  List<Object> get props => [timeline ?? '', requestId ?? ''];
}

class GetElapsedTasksEvent extends ScheduleSummaryEvent {
  GetElapsedTasksEvent();

  @override
  List<Object> get props => [];
}

class CompleteTaskEvent extends ScheduleSummaryEvent {
  final SubCalendarEvent subEvent;

  CompleteTaskEvent({required this.subEvent});

  @override
  List<Object> get props => [subEvent];
}


class LogOutScheduleDaySummaryEvent extends ScheduleSummaryEvent {
  LogOutScheduleDaySummaryEvent();

  @override
  List<Object> get props => [];
}
