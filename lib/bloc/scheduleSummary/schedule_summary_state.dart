part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryState extends Equatable {
  const ScheduleSummaryState();

  @override
  List<Object> get props => [];
}

class ScheduleSummaryInitial extends ScheduleSummaryState {}

class ScheduleDaySummaryLoaded extends ScheduleSummaryState {
  DayData? dayData;
  ScheduleDaySummaryLoaded({required this.dayData});
}

class ScheduleDaySummaryLoading extends ScheduleSummaryState {
  DayData? dayData;
  ScheduleDaySummaryLoading({this.dayData});
}
