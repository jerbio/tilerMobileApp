import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'ui_date_manager_event.dart';
part 'ui_date_manager_state.dart';

class UiDateManagerBloc extends Bloc<UiDateManagerEvent, UiDateManagerState> {
  UiDateManagerBloc() : super(UiDateManagerInitial()) {
    on<UiDateManagerEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
