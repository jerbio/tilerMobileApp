import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class AccessManager {
  SecureStorageManager _secureStorageManager = SecureStorageManager();

  bool isPermissionPending = false;

  ///Tuple3
  ///Item1 is the gps position retrieved from the system
  ///Item2 is a boolean and true if the location was verified from the actual gps device
  ///Item3 is a boolean and true if the call was a fresh attempt at reaching the gps device as opposed to a retry
  ////The response will be null if the we have no storage reference with prior calls
  Future<Tuple3<Position, bool, bool>?> locationAccess(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool denyAccess = false}) async {
    if (isPermissionPending) {
      return null;
    }
    const isAccessPermitedKey = 'accessAllowed';
    const timeOfLastAccessKey = 'lastLocationAccessRequest';
    Position retValue = Utility.getDefaultPosition();
    const Duration thirtyMins = Duration(minutes: 1);
    int currentTime = Utility.msCurrentTime;
    DateTime timeOfNextCheck =
        DateTime.fromMillisecondsSinceEpoch(currentTime).add(thirtyMins);
    Tuple2<bool, DateTime>? accessStatus;
    bool isLocationVerified = false;
    Map<String, dynamic>? loadedLocationInfo =
        await _secureStorageManager.getLocationAccess();
    if (loadedLocationInfo != null) {
      bool storedIsLocationAccessAllowed = false;
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
      if (!forceDeviceCheck) {
        return null;
      }
      //If we need to force the hardware check on gps then we need to set the time check as earlier than now. This might be a hack.
      accessStatus = Tuple2(false,
          DateTime.fromMillisecondsSinceEpoch(currentTime).add(-thirtyMins));
    }

    if (statusCheck) {
      return Tuple3(
          retValue,
          accessStatus.item1,
          accessStatus.item2.millisecondsSinceEpoch <
              referenceTimeForNextCheck);
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
      isPermissionPending = false;
      return Tuple3(retValue, isLocationVerified, false);
    }

    if (!denyAccess &&
        (forceDeviceCheck ||
            accessStatus.item1 ||
            accessStatus.item2.millisecondsSinceEpoch <
                referenceTimeForNextCheck)) {
      retValue = await Utility.determineDevicePosition().then((value) {
        isLocationVerified = true;
        isPermissionPending = false;
        return value;
      }).catchError((onError) {
        if (onError is PermissionRequestInProgressException) {
          isPermissionPending = true;
          return Utility.getDefaultPosition();
        }
        isPermissionPending = false;
        isLocationVerified = false;
        referenceTimeForNextCheck = timeOfNextCheck.millisecondsSinceEpoch;
        print('Tiler app: failed to pull device location.');
        print(onError);
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
    if (isPermissionPending) {
      return null;
    }

    await _secureStorageManager.writeLocationAccess(locationData);
    bool isWaitTimeElapsed =
        ((locationData[timeOfLastAccessKey] as int) < currentTime) ||
            forceDeviceCheck;
    return Tuple3(retValue, isLocationVerified, isWaitTimeElapsed);
  }
}
