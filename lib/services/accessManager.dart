import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class AccessManager {
  SecureStorageManager _secureStorageManager = SecureStorageManager();

  ///Tuple3
  ///Item1 is the gps position retrieved from the system
  ///Item2 is a boolean and true if the location was verified from the actual gps device
  ///Item3 is a boolean and true if the call was a fresh attempt at reaching the gps device as opposed to a retry
  Future<Tuple3<Position, bool, bool>> locationAccess(
      {bool forceDeviceCheck = false}) async {
    const isAccessPermitedKey = 'accessAllowed';
    const timeOfLastAccessKey = 'lastLocationAccessRequest';
    Position retValue = Utility.getDefaultPosition();
    const Duration thirtyMins = Duration(minutes: 30);
    DateTime timeOfNextCheck = Utility.currentTime().add(thirtyMins);
    Tuple2<bool, DateTime> accessStatus = new Tuple2(false, timeOfNextCheck);
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
    int currentTime = Utility.msCurrentTime;
    int referenceTimeForNextCheck = currentTime;
    if (forceDeviceCheck ||
        accessStatus.item1 ||
        accessStatus.item2.millisecondsSinceEpoch < referenceTimeForNextCheck) {
      retValue = await Utility.determineDevicePosition().then((value) {
        isLocationVerified = true;
        return value;
      }).catchError((onError) {
        isLocationVerified = false;
        referenceTimeForNextCheck = timeOfNextCheck.millisecondsSinceEpoch;
        print('Tiler app: failed to pull device location.');
        print(onError);
        return retValue;
      });
      locationData[isAccessPermitedKey] = accessStatus.item1;
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
    bool isWaitTimeElapsed =
        ((locationData[timeOfLastAccessKey] as int) < currentTime) ||
            forceDeviceCheck;
    return Tuple3(retValue, isLocationVerified, isWaitTimeElapsed);
  }
}
