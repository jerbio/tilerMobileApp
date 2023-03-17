part of 'calendar_tile_bloc.dart';

abstract class CalendarTileState extends Equatable {
  const CalendarTileState();

  @override
  List<Object> get props => [];
}

class CalendarTileInitial extends CalendarTileState {}

class CalendarTileLoaded extends CalendarTileState {
  final CalendarEvent calEvent;
  CalendarTileLoaded({required this.calEvent});
}

// ignore: must_be_immutable
class CalendarTileLoading extends CalendarTileState {
  final String calEventId;
  TilerEvent? calEvent;
  CalendarTileLoading({required this.calEventId, this.calEvent});
}
