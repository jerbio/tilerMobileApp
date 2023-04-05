part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryEvent extends Equatable {
  const ScheduleSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetScheduleDaySummary extends ScheduleSummaryEvent {
  final Timeline timeline;
  final List<DaySummary> daySummarys;
  GetScheduleDaySummary({required this.daySummarys, required this.timeline});

  @override
  List<Object> get props => [];
}
