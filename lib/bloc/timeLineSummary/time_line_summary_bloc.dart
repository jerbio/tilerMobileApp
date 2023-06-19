import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';

part 'time_line_summary_event.dart';
part 'time_line_summary_state.dart';

class TimeLineSummaryBloc
    extends Bloc<TimeLineSummaryEvent, TimeLineSummaryState> {
  ScheduleApi scheduleApi = ScheduleApi();
  TimeLineSummaryBloc() : super(TimeLineSummaryInitial()) {
    on<GetDayTimeLineSummaryEvent>(_onGetTimeLineSummary);
  }

  void _onGetTimeLineSummary(GetDayTimeLineSummaryEvent event,
      Emitter<TimeLineSummaryState> emit) async {
    TimelineSummary? timelineSummary;

    final currentState = this.state;
    if (currentState is TimeLineSummaryLoading) {
      Timeline timeline = event.timeline;
      emit(TimeLineSummaryLoading(timeline));
      this.scheduleApi.getTimelineSummary(timeline).then(
        (value) {
          emit(TimeLineSummaryLoaded(timeline, timelineSummary: value));
        },
      ).catchError((error) {
        emit(
            TimeLineSummaryErrorLoaded(timeline, error, timelineSummary: null));
      });
    }

    if (currentState is TimeLineSummaryLoading) {
      Timeline timeline = event.timeline;
      TimelineSummary? timelineSummary = event.timelineSummary;
      emit(TimeLineSummaryLoading(
        timeline,
        timelineSummary: timelineSummary,
      ));
      this.scheduleApi.getTimelineSummary(timeline).then(
        (value) {
          emit(TimeLineSummaryLoaded(timeline, timelineSummary: value));
        },
      ).catchError((error) {
        emit(
            TimeLineSummaryErrorLoaded(timeline, error, timelineSummary: null));
      });
    }

    if (currentState is TimeLineSummaryLoaded) {
      Timeline timeline = event.timeline;
      TimelineSummary? timelineSummary = event.timelineSummary;
      emit(TimeLineSummaryLoading(
        timeline,
        timelineSummary: timelineSummary,
      ));
      this.scheduleApi.getTimelineSummary(timeline).then(
        (value) {
          emit(TimeLineSummaryLoaded(timeline, timelineSummary: value));
        },
      ).catchError((error) {
        emit(
            TimeLineSummaryErrorLoaded(timeline, error, timelineSummary: null));
      });
    }
  }
}
