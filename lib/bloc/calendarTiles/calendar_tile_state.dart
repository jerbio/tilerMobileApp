part of 'calendar_tile_bloc.dart';

abstract class CalendarTileState extends Equatable {
  const CalendarTileState();

  @override
  List<Object> get props => [];
}

class CalendarTileInitial extends CalendarTileState {}

class CalendarTileLoggedOutState extends CalendarTileInitial {}

class CalendarTileLoaded extends CalendarTileState {
  final CalendarEvent calEvent;
  CalendarTileLoaded({required this.calEvent});
}

// ignore: must_be_immutable
class CalendarTileLoading extends CalendarTileState {
  final String? calEventId;
  final String? designatedTileTemplateId;
  TilerEvent? calEvent;
  CalendarTileLoading(
      {this.calEventId, this.designatedTileTemplateId, this.calEvent});
}
