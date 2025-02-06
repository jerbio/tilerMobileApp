import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/bloc/location/location_state.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/util.dart';

part 'location_event.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  late LocationApi locationApi;
  LocationBloc({required Function getContextCallBack})
      : super(LocationState.initial()) {
    on<GetLocationEvent>(_onGetLocationEvent);
    on<SetLocationEvent>(_onSetLocationEvent);
    locationApi = new LocationApi(getContextCallBack: getContextCallBack);
  }

  _onGetLocationEvent(
      GetLocationEvent event, Emitter<LocationState> emit) async {
    emit(LocationState.loading(blocSessionId: event.blocSessionId));

    if ((event.locationId != null && event.locationId!.isNotEmpty) ||
        (event.calEventId != null && event.calEventId!.isNotEmpty) ||
        (event.subEventId != null && event.subEventId!.isNotEmpty)) {
      await locationApi
          .getLocationById(
            id: event.locationId,
            calendarId: event.calEventId,
            subEventId: event.subEventId,
          )
          .then((value) => emit(LocationState.loaded(<Location?>[value],
              blocSessionId: event.blocSessionId)))
          .catchError((e) => emit(LocationState.error(e.toString(),
              blocSessionId: event.blocSessionId)));
      return;
    }

    if (event.name != null && event.name!.isNotEmpty) {
      await locationApi
          .getLocationsByName(event.locationId!)
          .then((value) => emit(
              LocationState.loaded(value, blocSessionId: event.blocSessionId)))
          .catchError((e) => emit(LocationState.error(e.toString(),
              blocSessionId: event.blocSessionId)));
      return;
    }

    emit(LocationState.error("Provide either location Name or location Id "));
  }

  _onSetLocationEvent(
      SetLocationEvent event, Emitter<LocationState> emit) async {
    LocationState.loaded(event.locations, blocSessionId: event.blocSessionId);
  }
}
