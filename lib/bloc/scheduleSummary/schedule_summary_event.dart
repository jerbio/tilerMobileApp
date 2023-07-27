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
  List<Object> get props => [];
}

class LogOutScheduleDaySummaryEvent extends ScheduleSummaryEvent {
  LogOutScheduleDaySummaryEvent();

  @override
  List<Object> get props => [];
}
