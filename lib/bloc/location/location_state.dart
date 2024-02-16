import 'package:sealed_unions/sealed_unions.dart';
import 'package:tiler_app/data/location.dart';

// part of 'location_bloc.dart';
// part 'location_state.freezed.dart'; //You need to run 'flutter pub run build_runner' build to update part file

class LocationState extends Union4Impl<_LocationInitial, _LocationLoading,
    _LocationLoaded, _LocationLoadError> {
  String? blocSessionId;
  static const factory = Quartet<_LocationInitial, _LocationLoading,
      _LocationLoaded, _LocationLoadError>();

  LocationState._(
      Union4<_LocationInitial, _LocationLoading, _LocationLoaded,
              _LocationLoadError>
          union,
      {String? blocSessionId})
      : super(union) {
    this.blocSessionId = blocSessionId;
  }

  factory LocationState.initial({String? blocSessionId}) {
    return LocationState._(factory.first(_LocationInitial()),
        blocSessionId: blocSessionId);
  }

  factory LocationState.loading({String? blocSessionId}) {
    return LocationState._(factory.second(_LocationLoading()),
        blocSessionId: blocSessionId);
  }

  factory LocationState.loaded(List<Location?>? model,
      {String? blocSessionId}) {
    return LocationState._(factory.third(_LocationLoaded(locations: model)),
        blocSessionId: blocSessionId);
  }

  factory LocationState.error(String message, {String? blocSessionId}) {
    return LocationState._(factory.fourth(_LocationLoadError()),
        blocSessionId: blocSessionId);
  }

  @override
  List<Object> get props => [];
}
// @freezed
// abstract class LocationState with _$LocationState {
//   const factory LocationState.initial() = _LocationInitial;

//   const factory LocationState.loading() = _LocationLoading;

//   const factory LocationState.loaded(List<Location?> model) = _LocationLoaded;

//   const factory LocationState.error(String message) = _LocationLoadError;
// }

final class _LocationInitial {}

final class _LocationLoading {}

final class _LocationLoaded {
  final List<Location?>? locations;
  _LocationLoaded({required this.locations});
}

final class _LocationLoadError {
  final String? Message;
  _LocationLoadError({this.Message});
}
