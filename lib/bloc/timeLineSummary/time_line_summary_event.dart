part of 'time_line_summary_bloc.dart';

abstract class TimeLineSummaryEvent extends Equatable {
  const TimeLineSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetDayTimeLineSummaryEvent implements TimeLineSummaryEvent {
  Timeline timeline;
  TimelineSummary? timelineSummary;

  GetDayTimeLineSummaryEvent(this.timeline, {this.timelineSummary});

  @override
  List<Object> get props => [];

  @override
  bool? get stringify => null;
}
