import 'package:tiler_app/data/tileObject.dart';

class Location extends TilerObj {
  String? description;
  String? address;
  double? longitude;
  double? latitude;
  bool? isVerified;
  bool? isDefault = true;
  bool? isNotNullAndNotDefault = false;
  String? source;
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
    if (json.containsKey('isNotNullAndNotDefault')) {
      isNotNullAndNotDefault = cast<bool>(json['isNotNullAndNotDefault']);
    }
    if (json.containsKey('source')) {
      source = cast<String>(json['source'])!;
    }
    if (json.containsKey('thirdPartyId')) {
      thirdPartyId = cast<String>(json['thirdPartyId']);
    }
    if (json.containsKey('userId')) {
      userId = cast<String>(json['userId']);
    }
    if (json.containsKey('isDefault')) {
      isDefault = cast<bool>(json['isDefault']);
    }

    if (isNotNullAndNotDefault != null && isVerified != null) {
      if (isDefault != null) {
        isDefault = !(isNotNullAndNotDefault! || isVerified!) && isDefault!;
      } else {
        isDefault = !(isNotNullAndNotDefault! || isVerified!);
      }
    }
  }

  Location.fromDefault() {
    isDefault = true;
  }
}
