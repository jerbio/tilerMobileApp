part of 'forecast_bloc.dart';

@immutable
abstract class ForecastState extends Equatable {
  final Duration? duration;
  final DateTime? endTime;

  ForecastState({this.duration, this.endTime});

  @override
  List<Object?> get props => [duration, endTime];
}

class ForecastInitial extends ForecastState {
  ForecastInitial({Duration? duration, DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}
class ForecastEndTimePicked extends ForecastState {
  ForecastEndTimePicked({Duration? duration, DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastDurationPicked extends ForecastState {
  ForecastDurationPicked({Duration? duration, DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastLoading extends ForecastState {
  ForecastLoading({Duration? duration, DateTime? endTime})
      : super(duration: duration, endTime: endTime);
}

class ForecastLoaded extends ForecastState {
  final List<SubCalendarEvent> forecastRiskEvents;
  final List<SubCalendarEvent> forecastConflictEvents;
  final bool? isViable;
  final int? suggestedTime;

  ForecastLoaded({
    this.forecastRiskEvents = const [],
    this.forecastConflictEvents = const [],
    this.isViable,
    this.suggestedTime,
    Duration? duration,
    DateTime? endTime,
  }) : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [
    super.props,
    forecastRiskEvents,
    forecastConflictEvents,
    isViable,
    suggestedTime,
  ];
}

class ForecastError extends ForecastState {
  final String error;

  ForecastError({
    required this.error,
    Duration? duration,
    DateTime? endTime,
  }) : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [super.props, error];
}
