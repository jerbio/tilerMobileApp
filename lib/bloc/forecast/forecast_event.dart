import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ForecastEvent extends Equatable {
  const ForecastEvent();

  @override
  List<Object> get props => [];
}

class UpdateDuration extends ForecastEvent {
  final Duration duration;

  const UpdateDuration(this.duration);

  @override
  List<Object> get props => [duration];
}

class UpdateDateTime extends ForecastEvent {
  final DateTime dateTime;

  const UpdateDateTime(this.dateTime);

  @override
  List<Object> get props => [dateTime];
}

class FetchData extends ForecastEvent {}
