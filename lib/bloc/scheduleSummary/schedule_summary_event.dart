part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryEvent extends Equatable {
  const ScheduleSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetScheduleDaySummaryEvent extends ScheduleSummaryEvent {
  Timeline? timeline;
  List<TimelineSummary>? daySummarys;
  GetScheduleDaySummaryEvent({this.timeline});

  @override
  List<Object> get props => [];
}
