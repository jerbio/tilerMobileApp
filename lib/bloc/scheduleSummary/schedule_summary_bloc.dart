import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/dayData.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';

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
    DayData? dayData;
    if (state is ScheduleDaySummaryLoaded) {
      dayData = (state as ScheduleDaySummaryLoaded).dayData;
    }
    if (state is ScheduleDaySummaryLoading) {
      dayData = (state as ScheduleDaySummaryLoading).dayData;
    }
    emit(ScheduleDaySummaryLoading(dayData: dayData));
    scheduleApi.getDaySummary(event.timeline).then((value) {
      DayData updatedDayData = value;
      emit(ScheduleDaySummaryLoaded(dayData: updatedDayData));
    });
  }
}
