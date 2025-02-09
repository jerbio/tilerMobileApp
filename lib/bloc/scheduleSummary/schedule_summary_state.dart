part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryState extends Equatable {
  const ScheduleSummaryState();

  @override
  List<Object?> get props => [];
}

class ScheduleSummaryInitial extends ScheduleSummaryState {}

class LoggedOutScheduleSummaryState extends ScheduleSummaryState {}

class ScheduleDaySummaryLoaded extends ScheduleSummaryState {
  final Timeline? timeline;
  final List<TimelineSummary>? dayData;
  final String? requestId;
  final List<TilerEvent> elapsedTiles;

  ScheduleDaySummaryLoaded({
    required this.dayData,
    this.timeline,
    this.requestId,
    required this.elapsedTiles,
  });

  @override
  List<Object?> get props => [timeline, dayData, requestId, elapsedTiles];
}

class ScheduleDaySummaryLoading extends ScheduleSummaryState {
  final Timeline? timeline;
  final List<TimelineSummary>? dayData;
  final String? requestId;

  ScheduleDaySummaryLoading({this.dayData, this.timeline, this.requestId});
}

class ScheduleSummaryLoadingTaskState extends ScheduleSummaryState {
  @override
  List<Object> get props => [Utility.currentTime().millisecondsSinceEpoch];
}

class ScheduleSummaryCompleteTaskState extends ScheduleSummaryState {
  final SubCalendarEvent completedEvent;

  ScheduleSummaryCompleteTaskState({required this.completedEvent});

  @override
  List<Object> get props => [completedEvent];
}

class ScheduleSummaryErrorState extends ScheduleSummaryState {
  final String error;

  ScheduleSummaryErrorState({required this.error, required String message});

  @override
  List<Object?> get props => [error];
}
