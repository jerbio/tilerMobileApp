part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryEvent extends Equatable {
  const ScheduleSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetScheduleDaySummaryEvent extends ScheduleSummaryEvent {
  final Timeline timeline;
  // final List<DaySummary> daySummarys;
  GetScheduleDaySummaryEvent({required this.timeline});

  @override
  List<Object> get props => [];
}
