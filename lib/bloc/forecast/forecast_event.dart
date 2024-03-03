part of 'forecast_bloc.dart';

@immutable
abstract class ForecastEvent extends Equatable {
  const ForecastEvent();

  @override
  List<Object?> get props => [];

}

class DurationUpdated extends ForecastEvent {
  final Duration? duration;
  DurationUpdated(this.duration);
  @override
  List<Object?> get props => [duration];
}

class EndTimeUpdated extends ForecastEvent {
  final DateTime? endTime;
  EndTimeUpdated(this.endTime);

  @override
  List<Object?> get props => [endTime];

}


class SchedulePreviewRequested extends ForecastEvent {}

class ResetForecastStateEvent extends ForecastEvent {}


