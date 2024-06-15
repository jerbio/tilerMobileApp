import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/util.dart';

import '../../data/subCalendarEvent.dart';
import 'forecast_event.dart';
import 'forecast_state.dart';

class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  ForecastBloc() : super(ForecastInitial()) {
    on<UpdateDuration>(_onUpdateDuration);
    on<UpdateDateTime>(_onUpdateDateTime);
    on<FetchData>(_onFetchData);
  }

  void _onUpdateDuration(UpdateDuration event, Emitter<ForecastState> emit) {
    print("Updating duration: ${event.duration}");
    final newState = state;
    emit(ForecastLoading(duration: event.duration, endTime: newState.endTime));
    _checkAndTriggerEvent(event.duration, newState.endTime);
  }

  void _onUpdateDateTime(UpdateDateTime event, Emitter<ForecastState> emit) {
    print("Updating end time: ${event.dateTime}");
    final newState = state;
    emit(ForecastLoading(duration: newState.duration, endTime: event.dateTime));
    _checkAndTriggerEvent(newState.duration, event.dateTime);
  }

  void _checkAndTriggerEvent(Duration duration, DateTime? endTime) {
    if (duration >= Duration(minutes: 1) && endTime != null) {
      print("Emitting FetchData event");
      add(FetchData());
    }
  }

  Future<void> _onFetchData(
      FetchData event, Emitter<ForecastState> emit) async {
    try {
      emit(ForecastLoading(duration: state.duration, endTime: state.endTime));
      print('Fetching data...');

      DateTime now = DateTime.now();
      int currentMinute = now.minute;
      int currentHour = now.hour;
      int currentDay = now.day;
      int currentMonth = now.month;
      int currentYear = now.year;
      int endDay = state.endTime!.day;
      int endMonth = state.endTime!.month;
      int endYear = state.endTime!.year;
      var durInHours = state.duration.inHours;
      var durrInMilliseconds = state.duration.inMilliseconds;
      var durInUtc = durationToUtcString(state.duration);

      Map<String, Object> queryParams = {
        "StartMinute": currentMinute.toString(),
        "StartHour": currentHour.toString(),
        "StartDay": currentDay.toString(),
        "StartMonth": currentMonth.toString(),
        "StartYear": currentYear.toString(),
        "EndDay": endDay.toString(),
        "EndMonth": endMonth.toString(),
        "EndYear": endYear.toString(),
        "DurationHours": durInHours.toString(),
        "DurationInMs": durrInMilliseconds.toString(),
        "Duration": durInUtc.toString(),
      };

      final val = await WhatIfApi().forecastNewTile(queryParams);
      print('Data fetched: $val');

      final isViable = val[0] as bool;
      final subCalEvents = val[1] as List<SubCalendarEvent>;

      emit(ForecastLoaded(
        isViable: isViable,
        subCalEvents: subCalEvents,
        duration: state.duration,
        endTime: state.endTime,
      ));
    } catch (e) {
      print('Error: $e');
      emit(ForecastError(
        'An error occurred while fetching data. Please try again later.',
        duration: state.duration,
        endTime: state.endTime,
      ));
    }
  }

  String durationToUtcString(Duration duration) {
    DateTime utcTime = DateTime.utc(0, 0, 0, duration.inHours,
        duration.inMinutes.remainder(60), duration.inSeconds.remainder(60));
    return utcTime
        .toIso8601String()
        .split('T')[1]
        .split('.')[0]; // Extract the time part in HH:mm:ss format
  }

  // Future<void> _onFetchData(FetchData event, Emitter<ForecastState> emit) async {
  //   final currentState = state;
  //   try {
  //     emit(ForecastLoading(duration: currentState.duration, endTime: currentState.endTime));
  //     print('Fetching data...');
  //     DateTime now = DateTime.now();
  //     int currentMinute = now.minute;
  //     int currentHour = now.hour;
  //     int currentDay = now.day;
  //     int currentMonth = now.month;
  //     int currentYear = now.year;
  //     int endDay = currentState.endTime!.day;
  //     int endMonth = currentState.endTime!.month;
  //     int endYear = currentState.endTime!.year;
  //     var durInHours = currentState.duration.inHours;
  //     var durrInMilliseconds = currentState.duration.inMilliseconds;
  //     var durInUtc = durationToUtcString(currentState.duration);

  //     Map<String, Object> queryParams = {
  //       "StartMinute": currentMinute.toString(),
  //       "StartHour": currentHour.toString(),
  //       "StartDay": currentDay.toString(),
  //       "StartMonth": currentMonth.toString(),
  //       "StartYear": currentYear.toString(),
  //       "EndDay": endDay.toString(),
  //       "EndMonth": endMonth.toString(),
  //       "EndYear": endYear.toString(),
  //       "DurationHours": durInHours.toString(),
  //       "DurationInMs": durrInMilliseconds.toString(),
  //       "Duration": durInUtc.toString(),
  //     };

  //     final val = await WhatIfApi().forecastNewTile(queryParams);
  //     print('Data fetched: $val');
  //     emit(ForecastLoaded(
  //       isViable: val[0],
  //       subCalEvents: val[1],
  //       resp: val.toString(),
  //       duration: currentState.duration,
  //       endTime: currentState.endTime,
  //     ));
  //   } catch (e) {
  //     print('Error: $e');
  //     emit(ForecastError(e.toString(), duration: currentState.duration, endTime: currentState.endTime));
  //   }
  // }

  // String durationToUtcString(Duration duration) {
  //   DateTime utcTime = DateTime.utc(0, 0, 0, duration.inHours,
  //       duration.inMinutes.remainder(60), duration.inSeconds.remainder(60));
  //   return utcTime
  //       .toIso8601String()
  //       .split('T')[1]
  //       .split('.')[0]; // Extract the time part in HH:mm:ss format
  // }
}
