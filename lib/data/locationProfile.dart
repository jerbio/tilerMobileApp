import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/permissionProfile.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class LocationProfile {
  Position? position;
  DateTime? lastTimeLoaded;
  PermissionProfile? permission;
  LocationProfile();

  LocationProfile.empty() {
    position = Utility.getDefaultPosition();
    permission = PermissionProfile.unknown();
  }

  Location? get location {
    return position?.toLocation ?? Location.fromDefault();
  }

  bool get isGranted {
    return permission?.isGranted ?? false;
  }

  bool canRecheckPermission() {
    if (permission == null ||
        permission!.lastCheck == null ||
        permission!.lastCheck!.isBefore(
            Utility.currentTime().add(-Constants.retryPermissionCheck))) {
      return true;
    }
    return permission!.lastCheck!.isBefore(
        Utility.currentTime().subtract(Constants.retryPermissionCheck));
  }

  @override
  String toString() {
    return 'LocationProfile{position: $position, lastTimeLoaded: $lastTimeLoaded, permission: $permission}';
  }
}
