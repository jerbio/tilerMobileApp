part of 'tile_list_carousel_bloc.dart';

sealed class TileListCarouselState extends Equatable {
  const TileListCarouselState();

  @override
  List<Object> get props => [];
}

final class TileListCarouselInitial extends TileListCarouselState {}

final class TileListCarouselEnable extends TileListCarouselState {
  final int? dayIndex;
  const TileListCarouselEnable({this.dayIndex});
}

final class TileListCarouselDisabled extends TileListCarouselState {
  final int dayIndex;
  const TileListCarouselDisabled({required this.dayIndex});
}
