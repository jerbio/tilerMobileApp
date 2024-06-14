import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

abstract class ForecastState extends Equatable {
  final Duration duration;
  final DateTime? endTime;

  const ForecastState({required this.duration, required this.endTime});

  @override
  List<Object?> get props => [duration, endTime];
}

class ForecastInitial extends ForecastState {
  ForecastInitial() : super(duration: Duration(hours: 0, minutes: 0), endTime: null);
}

class ForecastLoading extends ForecastState {
  const ForecastLoading({required Duration duration, required DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastLoaded extends ForecastState {
  final bool isViable;
  final List<SubCalendarEvent> subCalEvents;
  final String resp;

  const ForecastLoaded({
    required this.isViable,
    required this.subCalEvents,
    required this.resp,
    required Duration duration,
    required DateTime? endTime,
  }) : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [isViable, subCalEvents, resp, duration, endTime];
}

class ForecastError extends ForecastState {
  final String error;

  const ForecastError(this.error, {required Duration duration, required DateTime? endTime})
      : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [error, duration, endTime];
}
