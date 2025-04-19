import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

abstract class ForecastState extends Equatable {
  final String? name;
  final Duration? duration;
  final DateTime? endTime;
  final Location? location;
  final RestrictionProfile? restrictionProfile;

  const ForecastState({required this.duration, required this.endTime, this.location, this.name, this.restrictionProfile});

  @override
  List<Object?> get props => [duration, endTime, location];
}

class ForecastInitial extends ForecastState {
  ForecastInitial({Duration? duration, DateTime? endTime, Location? location})
      : super(duration: duration, endTime: endTime, location: location);
}

class ForecastLoading extends ForecastState {
  const ForecastLoading(
      {required Duration duration, required DateTime? endTime, Location? location})
      : super(duration: duration, endTime: endTime, location: location);
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
