part of 'time_line_summary_bloc.dart';

abstract class TimeLineSummaryState extends Equatable {
  const TimeLineSummaryState();

  @override
  List<Object> get props => [];
}

class TimeLineSummaryInitial extends TimeLineSummaryState {}

class TimeLineSummaryLoading extends TimeLineSummaryState {
  Timeline timeline;
  TimelineSummary? timelineSummary;
  TimeLineSummaryLoading(this.timeline, {this.timelineSummary});
}

class TimeLineSummaryLoaded extends TimeLineSummaryState {
  Timeline timeline;
  TimelineSummary? timelineSummary;
  TimeLineSummaryLoaded(this.timeline, {this.timelineSummary});
}

class TimeLineSummaryErrorLoaded extends TimeLineSummaryLoaded {
  Timeline timeline;
  var errorMessage;
  TimelineSummary? timelineSummary;
  TimeLineSummaryErrorLoaded(this.timeline, this.errorMessage,
      {this.timelineSummary})
      : super(timeline, timelineSummary: timelineSummary);
}
