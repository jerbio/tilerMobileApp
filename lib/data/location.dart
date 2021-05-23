import 'package:tiler_app/data/tileObject.dart';

class Location extends TilerObj {
  String? description;
  String? address;
  double? longitude;
  double? latitude;
  bool? isVerified;
  String? thirdPartyId;
  static T? cast<T>(x) => x is T ? x : null;
  Location.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('description')) {
      description = cast<String>(json['description']);
    }
    if (json.containsKey('address')) {
      address = cast<String>(json['address']);
    }
    if (json.containsKey('longitude')) {
      longitude = cast<double>(json['longitude'])!.toDouble();
    }
    if (json.containsKey('latitude')) {
      latitude = cast<double>(json['latitude'])!.toDouble();
    }
    if (json.containsKey('isVerified')) {
      isVerified = cast<bool>(json['isVerified']);
    }
    if (json.containsKey('thirdPartyId')) {
      thirdPartyId = cast<String>(json['thirdPartyId']);
    }
  }
}
