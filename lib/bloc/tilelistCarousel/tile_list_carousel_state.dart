part of 'tile_list_carousel_bloc.dart';

sealed class TileListCarouselState extends Equatable {
  const TileListCarouselState();

  @override
  List<Object> get props => [];
}

final class TileListCarouselInitial extends TileListCarouselState {}

final class TileListCarouselEnable extends TileListCarouselState {
  final int? dayIndex;
  final bool isImmediate;
  const TileListCarouselEnable({required this.isImmediate, this.dayIndex});
}

final class TileListCarouselDisabled extends TileListCarouselState {
  final int? dayIndex;
  final bool isImmediate;
  const TileListCarouselDisabled({required this.isImmediate, this.dayIndex});
}
