import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import '../../data/forecast.dart';
import '../../data/subCalendarEvent.dart';
import '../../../constants.dart' as Constants;
import '../../services/api/forecastApi.dart';

part 'forecast_event.dart';
part 'forecast_state.dart';

class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {

  final SchedulePreviewApi schedulePreviewApi;

  ForecastBloc(this.schedulePreviewApi) : super(ForecastInitial()) {
    on<DurationUpdated>(_onDurationUpdated);
    on<EndTimeUpdated>(_onEndTimeUpdated);
    on<SchedulePreviewRequested>(_onSchedulePreviewRequested);
    on<ResetForecastStateEvent>(_onResetForecastState);

  }

  void _onDurationUpdated(DurationUpdated event, Emitter<ForecastState> emit) {
      emit(ForecastDurationPicked(
        duration: event.duration,
        endTime: state.endTime,
      ));
      add(SchedulePreviewRequested());

  }

  void _onEndTimeUpdated(EndTimeUpdated event, Emitter<ForecastState> emit) {
      emit(ForecastEndTimePicked(
        duration: state.duration,
        endTime: event.endTime,
      ));
      add(SchedulePreviewRequested());
  }

  void _onSchedulePreviewRequested(SchedulePreviewRequested event, Emitter<ForecastState> emit) async {
    await Future.delayed(const Duration(milliseconds: Constants.onTextChangeDelayInMs));
    if ( state.duration != null && state.duration!.inMilliseconds >= 300000) {
      emit(ForecastLoading(
        duration: state.duration,
        endTime: state.endTime,
      ));
      try {
        String endDay = state.endTime?.day.toString() ?? '';
        String endMonth = state.endTime?.month.toString() ?? '';
        String endYear = state.endTime?.year.toString() ?? '';
        Map<String, dynamic> requestPayload = {
          "EndDay": endDay,
          "EndMonth": endMonth,
          "EndYear": endYear,
          "Count": "1",
          "isRestricted": "false",
          "DurationDays": state.duration!.inDays.toString(),
          "DurationHours": (state.duration!.inHours % 24).toString(),
          "DurationMinute": (state.duration!.inMinutes % 60).toString(),
          "DurationInMs": state.duration!.inMilliseconds,
          "User": {
            "MobileApp": "true",
            "TimeZoneOffset": DateTime.now().timeZoneOffset.inHours.toString(),
            "TimeZone": "UTC",
          },
        };

        Forecast forecast = await schedulePreviewApi.sendSchedulePreviewRequest(requestPayload);
        List<SubCalendarEvent> riskEvents = forecast.riskCalendarEvents?.expand((event) => event.subEvents ?? []).toList().cast<SubCalendarEvent>() ?? [];
        List<SubCalendarEvent> conflictEvents = forecast.conflicts?.expand((event) => event.subEvents ?? []).toList().cast<SubCalendarEvent>() ?? [];
        emit(ForecastLoaded(
          forecastRiskEvents: riskEvents,
          forecastConflictEvents: conflictEvents,
          suggestedTime: forecast.deadlineSuggestion,
          isViable: forecast.isViable,
          duration: state.duration,
          endTime: state.endTime,
        ));

      } catch (e) {
        emit(ForecastError(
          error: e.toString(),
          duration: state.duration,
          endTime: state.endTime,
        ),
        );
      }
    }
    else if(state.duration ==null){
      emit(ForecastError(
        error: 'Please pick the Duration',
        duration: state.duration,
        endTime: state.endTime,
      ),
      );
    }
    else {
      emit(ForecastError(
        error: 'Minimum duration is 5 minutes',
        duration: state.duration,
        endTime: state.endTime,
      ),
      );
    }
  }
  void _onResetForecastState(ResetForecastStateEvent event, Emitter<ForecastState> emit) {
    emit(ForecastInitial());
  }

}


