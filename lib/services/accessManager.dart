import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/permissionProfile.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class AccessManager {
  SecureStorageManager _secureStorageManager = SecureStorageManager();

  DateTime lastLookup = Utility.currentTime();

  Future<LocationProfile> locationAccess(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool denyAccess = false}) async {
    const isAccessPermitedKey = 'accessAllowed';
    const timeOfLastAccessKey = 'lastLocationAccessRequest';
    Position retValue = Utility.getDefaultPosition();
    const Duration thirtyMins = Duration(minutes: 1);
    int currentTime = Utility.msCurrentTime;
    DateTime timeOfNextCheck =
        DateTime.fromMillisecondsSinceEpoch(currentTime).add(thirtyMins);
    Tuple2<bool?, DateTime>? accessStatus;
    bool isLocationVerified = false;
    Map<String, dynamic>? loadedLocationInfo =
        await _secureStorageManager.getLocationAccess();
    if (loadedLocationInfo != null) {
      bool? storedIsLocationAccessAllowed = false;
      DateTime? storedTimeOfNextCheck;
      if (loadedLocationInfo.containsKey(isAccessPermitedKey)) {
        storedIsLocationAccessAllowed = loadedLocationInfo[isAccessPermitedKey];
      }

      if (loadedLocationInfo.containsKey(timeOfLastAccessKey)) {
        storedTimeOfNextCheck = DateTime.fromMillisecondsSinceEpoch(
            loadedLocationInfo[timeOfLastAccessKey]);
      }
      accessStatus = Tuple2(
          storedIsLocationAccessAllowed,
          storedTimeOfNextCheck ??
              Utility.currentTime().add(Duration(minutes: -5)));
    }

    Map<String, Object> locationData = {};
    int referenceTimeForNextCheck = currentTime;
    if (accessStatus == null) {
      // nothing is stored
      if (!forceDeviceCheck) {
        return LocationProfile.empty();
      }
      //If we need to force the hardware check on gps then we need to set the time check as earlier than now. This might be a hack.
      accessStatus = Tuple2(false,
          DateTime.fromMillisecondsSinceEpoch(currentTime).add(-thirtyMins));
      locationData[isAccessPermitedKey] = false;
      locationData[timeOfLastAccessKey] = DateTime(0).millisecondsSinceEpoch;
      await _secureStorageManager.writeLocationAccess(locationData);
    }

    if (statusCheck) {
      LocationProfile locationProfile = LocationProfile();
      locationProfile.lastTimeLoaded = accessStatus.item2;
      locationProfile.position = retValue;
      locationProfile.permission = accessStatus.item1 == true
          ? PermissionProfile.accept()
          : loadedLocationInfo == null
              ? PermissionProfile.unknown()
              : PermissionProfile.deny();
      lastLookup =
          loadedLocationInfo == null ? DateTime(0) : Utility.currentTime();
      return locationProfile;
    }

    if (denyAccess) {
      isLocationVerified = false;
      referenceTimeForNextCheck =
          DateTime.fromMillisecondsSinceEpoch(currentTime)
              .add(Utility.oneDay)
              .millisecondsSinceEpoch;
      locationData[isAccessPermitedKey] = false;
      locationData[timeOfLastAccessKey] = referenceTimeForNextCheck;
      await _secureStorageManager.writeLocationAccess(locationData);
      lastLookup = Utility.currentTime();
      LocationProfile locationProfile = LocationProfile();
      locationProfile.permission = PermissionProfile.deny();

      return locationProfile;
    }

    if (!denyAccess &&
        (forceDeviceCheck ||
            accessStatus.item1 != false ||
            accessStatus.item2.millisecondsSinceEpoch <
                referenceTimeForNextCheck)) {
      retValue = await Utility.determineDevicePosition().then((value) {
        isLocationVerified = true;
        lastLookup = Utility.currentTime();
        return value;
      }).catchError((onError) {
        if (onError is PermissionRequestInProgressException) {
          lastLookup = Utility.currentTime();
          return Utility.getDefaultPosition();
        }
        lastLookup = Utility.currentTime();
        isLocationVerified = false;
        referenceTimeForNextCheck = timeOfNextCheck.millisecondsSinceEpoch;
        return retValue;
      });
      locationData[isAccessPermitedKey] = isLocationVerified;
      locationData[timeOfLastAccessKey] = referenceTimeForNextCheck;
    } else {
      timeOfNextCheck =
          accessStatus.item2.millisecondsSinceEpoch < referenceTimeForNextCheck
              ? timeOfNextCheck
              : accessStatus.item2;
      locationData[isAccessPermitedKey] = isLocationVerified;
      locationData[timeOfLastAccessKey] =
          timeOfNextCheck.millisecondsSinceEpoch;
    }

    await _secureStorageManager.writeLocationAccess(locationData);
    LocationProfile locationProfile = LocationProfile();
    locationProfile.position = retValue;
    locationProfile.permission = isLocationVerified
        ? PermissionProfile.accept()
        : PermissionProfile.deny();
    return locationProfile;
  }
}
