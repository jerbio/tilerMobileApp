part of 'location_bloc.dart';

sealed class LocationEvent extends Equatable {
  String? blocSessionId;

  @override
  List<Object> get props => [];
}

class GetLocationEvent extends LocationEvent {
  String? locationId;
  String? name;
  String? subEventId;
  String? calEventId;
  GetLocationEvent();
  GetLocationEvent.byName(
      {required String locationName, String? blocSessionId}) {
    this.name = locationName;
    this.blocSessionId = blocSessionId ?? Utility.getUuid;
  }

  GetLocationEvent.byId({required String id, String? blocSessionId}) {
    this.blocSessionId = blocSessionId ?? Utility.getUuid;
    locationId = id;
  }

  GetLocationEvent.bySubEventId(
      {required this.subEventId, String? blocSessionId}) {
    this.blocSessionId = blocSessionId ?? Utility.getUuid;
  }

  GetLocationEvent.byCalEventId(
      {required this.calEventId, String? blocSessionId}) {
    this.blocSessionId = blocSessionId ?? Utility.getUuid;
  }

  @override
  List<Object> get props => [];
}

class SetLocationEvent extends LocationEvent {
  List<Location?>? locations;
  SetLocationEvent(
      {required List<Location?>? location, String? blocSessionId}) {
    this.blocSessionId = blocSessionId ?? Utility.getUuid;
    this.locations = locations;
  }

  @override
  List<Object> get props => [];
}
