import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/util.dart';

part 'tile_list_carousel_event.dart';
part 'tile_list_carousel_state.dart';

class TileListCarouselBloc
    extends Bloc<TileListCarouselEvent, TileListCarouselState> {
  TileListCarouselBloc() : super(TileListCarouselInitial()) {
    on<DisableCarouselScrollEvent>(_onDisableCarouselScrollEvent);
    on<EnableCarouselScrollEvent>(_onEnableCarouselScrollEvent);
  }

  _onDisableCarouselScrollEvent(
      DisableCarouselScrollEvent event, Emitter emit) {
    Utility.debugPrint("Disable carousel emitted");
    emit(TileListCarouselDisabled(isImmediate: event.isImmediate));
  }

  _onEnableCarouselScrollEvent(EnableCarouselScrollEvent event, Emitter emit) {
    Utility.debugPrint("Enable carousel emitted");
    emit(TileListCarouselEnable(isImmediate: event.isImmediate));
  }
}
