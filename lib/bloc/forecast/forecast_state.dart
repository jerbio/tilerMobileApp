import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

abstract class ForecastState extends Equatable {
  final Duration? duration;
  final DateTime? endTime;

  const ForecastState({required this.duration, required this.endTime});

  @override
  List<Object?> get props => [duration, endTime];
}

class ForecastInitial extends ForecastState {
  ForecastInitial({Duration? duration, DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastLoading extends ForecastState {
  const ForecastLoading(
      {required Duration duration, required DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastLoaded extends ForecastState {
  final bool isViable;
  final ForecastResponse foreCastResponse;

  const ForecastLoaded({
    required this.isViable,
    required this.foreCastResponse,
    required Duration duration,
    required DateTime? endTime,
  }) : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [isViable, foreCastResponse, duration, endTime];
}

class ForecastError extends ForecastState {
  final String error;

  const ForecastError(this.error,
      {required Duration duration, required DateTime? endTime})
      : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [error, duration, endTime];
}
