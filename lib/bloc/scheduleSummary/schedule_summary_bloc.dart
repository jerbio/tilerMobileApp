import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc
    extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  ScheduleApi scheduleApi = ScheduleApi();
  ScheduleSummaryBloc() : super(ScheduleSummaryInitial()) {
    on<GetScheduleDaySummaryEvent>(_onGetDayData);
  }

  Future<void> _onGetDayData(GetScheduleDaySummaryEvent event,
      Emitter<ScheduleSummaryState> emit) async {
    List<TimelineSummary>? dayData;
    Timeline? timeline = event.timeline ?? Utility.todayTimeline();
    if (state is ScheduleDaySummaryLoaded) {
      dayData = (state as ScheduleDaySummaryLoaded).dayData;
    }
    if (state is ScheduleDaySummaryLoading) {
      dayData = (state as ScheduleDaySummaryLoading).dayData;
    }
    emit(ScheduleDaySummaryLoading(timeline: timeline, dayData: dayData));

    await scheduleApi.getDaySummary(timeline).then((value) async {
      emit(ScheduleDaySummaryLoaded(
          timeline: timeline, dayData: value.values.toList()));
    });
  }
}
