part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryState extends Equatable {
  const ScheduleSummaryState();

  @override
  List<Object> get props => [];
}

class ScheduleSummaryInitial extends ScheduleSummaryState {}

class ScheduleDaySummaryLoaded extends ScheduleSummaryState {
  Timeline? timeline;
  List<TimelineSummary>? dayData;
  String? requestId;
  ScheduleDaySummaryLoaded(
      {required this.dayData, this.timeline, this.requestId});
}

class ScheduleDaySummaryLoading extends ScheduleSummaryState {
  Timeline? timeline;
  List<TimelineSummary>? dayData;
  String? requestId;
  ScheduleDaySummaryLoading({this.dayData, this.timeline, this.requestId});
}
