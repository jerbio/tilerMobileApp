import 'package:tiler_app/data/tileObject.dart';
import 'dart:math';

class Location extends TilerObj {
  static const String homeLocationNickName = 'home';
  static const String workLocationNickName = 'work';
  static const double defaultLongitudeAndLatitude = 777777.0;
  static const double maxLongLat = 180.0;
  static const double minLongLat = -180.0;
  String? id;
  String? description;
  String? address;
  double? longitude;
  double? latitude;
  bool? isVerified;
  bool? isDefault = true;
  bool? isNull = true;
  String? source;
  String? thirdPartyId;

  bool get isNotNullAndNotDefault {
    if (isNull != null && isDefault != null) {
      return !isNull! && !isDefault!;
    }
    return false;
  }

  Location.fromLatitudeAndLongitude(
      {required this.latitude, required this.longitude}) {
    this.isDefault = false;
    this.isNull = false;
  }

  static T? cast<T>(x) => x is T ? x : null;
  Location.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('id')) {
      id = cast<String>(json['id']);
    }
    if (json.containsKey('description')) {
      description = cast<String>(json['description']);
    }
    if (json.containsKey('address')) {
      address = cast<String>(json['address']);
    }
    if (json.containsKey('Address')) {
      address = cast<String>(json['Address']);
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
    if (json.containsKey('isNull')) {
      isNull = cast<bool>(json['isNull']);
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
  }
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'isVerified': isVerified,
      'isDefault': isDefault,
      'isNull': isNull,
      'source': source,
      'thirdPartyId': thirdPartyId,
      'userId': userId,
    };
  }

  Location.fromDefault() {
    isDefault = true;
    latitude = null;
    longitude = null;
  }

  @override
  String toString() {
    return 'Location{description: $description, address: $address, longitude: $longitude, latitude: $latitude, isVerified: $isVerified, isDefault: $isDefault, isNull: $isNull, source: $source, thirdPartyId: $thirdPartyId}';
  }

  LatitudeAndLongitude? get toLatitudeAndLongitude {
    LatitudeAndLongitude? retValue = null;
    if (this.longitude != null &&
        this.latitude != null &&
        this.longitude! >= minLongLat &&
        this.longitude! <= maxLongLat &&
        this.latitude! >= minLongLat &&
        this.latitude! <= maxLongLat &&
        this.isNotNullAndNotDefault) {
      return LatitudeAndLongitude(this.latitude!, this.longitude!);
    }

    return retValue;
  }
}

class LatitudeAndLongitude {
  double latitude;
  double longitude;

  LatitudeAndLongitude(this.latitude, this.longitude);

  static double _toRad(double value) {
    return value * pi / 180;
  }

  static double distance(
      LatitudeAndLongitude Location24A, LatitudeAndLongitude Location24B) {
    double R = 6400; // Radius of earth in KM
    double dLat = _toRad(Location24A.latitude - Location24B.latitude);
    double dLon = _toRad(Location24A.longitude - Location24B.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(Location24A.latitude)) *
            cos(_toRad(Location24A.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double d = R * c;

    return d;
  }

  static LatitudeAndLongitude? averageLatLong(
      List<LatitudeAndLongitude> Locations) {
    LatitudeAndLongitude retValue;
    if (Locations.isNotEmpty) {
      if (Locations.length == 1) {
        return Locations.first;
      }

      double x = 0;
      double y = 0;
      double z = 0;

      for (var geoCoordinate in Locations) {
        var latitude = geoCoordinate.latitude * pi / 180;
        var longitude = geoCoordinate.longitude * pi / 180;

        x += cos(latitude) * cos(longitude);
        y += cos(latitude) * sin(longitude);
        z += sin(latitude);
      }

      var total = Locations.length;

      x = x / total;
      y = y / total;
      z = z / total;

      var centralLongitude = atan2(y, x);
      var centralSquareRoot = sqrt(x * x + y * y);
      var centralLatitude = atan2(z, centralSquareRoot);

      retValue = new LatitudeAndLongitude(
          centralLatitude * 180 / pi, centralLongitude * 180 / pi);

      return retValue;
    }

    return null;
  }
}
