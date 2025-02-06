part of 'tile_list_carousel_bloc.dart';

abstract class TileListCarouselEvent extends Equatable {
  const TileListCarouselEvent();

  @override
  List<Object> get props => [];
}

class DisableCarouselScrollEvent extends TileListCarouselEvent {
  final int dayIndex;
  final bool isImmediate;
  const DisableCarouselScrollEvent(
      {this.isImmediate = false, required this.dayIndex});

  @override
  List<Object> get props => [];
}

class EnableCarouselScrollEvent extends TileListCarouselEvent {
  final int? dayIndex;
  final bool isImmediate;
  const EnableCarouselScrollEvent({this.isImmediate = false, this.dayIndex});

  @override
  List<Object> get props => [];
}
