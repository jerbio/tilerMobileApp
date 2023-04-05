part of 'schedule_summary_bloc.dart';

abstract class ScheduleSummaryState extends Equatable {
  const ScheduleSummaryState();

  @override
  List<Object> get props => [];
}

class ScheduleSummaryInitial extends ScheduleSummaryState {}

// class ScheduleDaySummaryLoading extends ScheduleSummaryState {}

class ScheduleDaySummaryLoaded extends ScheduleSummaryState {
  List<SubCalendarEvent> tardySubEvent;
  List<SubCalendarEvent> nonViableSubEvent;
  List<SubCalendarEvent> wakeSubEvent;
  List<SubCalendarEvent> sleepSubEvent;
  List<SubCalendarEvent> completeSubEvent;
  List<SubCalendarEvent> deletedSubEvent;

  ScheduleDaySummaryLoaded(
      {required this.tardySubEvent,
      required this.nonViableSubEvent,
      required this.wakeSubEvent,
      required this.sleepSubEvent,
      required this.completeSubEvent,
      required this.deletedSubEvent});
}
