import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/request/NewTile.dart';

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

class NewTileEvent extends ForecastEvent {
  final NewTile newTile;

  const NewTileEvent(this.newTile);

  @override
  List<Object> get props => [newTile.getDuration() ?? Duration.zero, 
  newTile.LocationAddress ?? "",
  newTile.StartHour ?? "",
  newTile.StartMinute ?? "",
  newTile.StartDay ?? "",
  newTile.StartMonth ?? "",
  newTile.StartYear ?? "",
  newTile.EndHour ?? "",
  newTile.EndMinute ?? "",
  newTile.EndDay ?? "",
  newTile.EndMonth ?? "",
  newTile.EndYear ?? "",
  newTile.LocationAddress ?? "",
  newTile.LocationTag ?? "",
  newTile.LocationId ?? "",
  newTile.LocationSource ?? "",
  newTile.LocationIsVerified ?? false  
  ];

  
}

class UpdateDateTime extends ForecastEvent {
  final DateTime dateTime;

  const UpdateDateTime(this.dateTime);

  @override
  List<Object> get props => [dateTime];
}

class FetchData extends ForecastEvent {}
