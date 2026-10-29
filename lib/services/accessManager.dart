import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/permissionProfile.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/services/locationDiagnostics.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class AccessManager {
  SecureStorageManager _secureStorageManager = SecureStorageManager();

  DateTime lastLookup = Utility.currentTime();

  Future<LocationProfile> locationAccess(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool denyAccess = false,
      String? diagnosticId}) async {
    final lookupId = diagnosticId ?? Utility.getUuid;
    final timer = Stopwatch()..start();
    void trace(String event,
        {Map<String, Object?> fields = const {}, Object? error}) {
      locationFlowLog(event,
          fields: {
            'lookupId': lookupId,
            'elapsedMs': timer.elapsedMilliseconds,
            ...fields,
          },
          error: error);
    }

    trace('access_started', fields: {
      'forceDeviceCheck': forceDeviceCheck,
      'statusCheck': statusCheck,
      'denyAccess': denyAccess,
    });
    // return LocationProfile.empty();
    const isAccessPermitedKey = 'accessAllowed';
    const timeOfLastAccessKey = 'lastLocationAccessRequest';
    Position retValue = Utility.getDefaultPosition();
    const Duration thirtyMins = Duration(minutes: 1);
    int currentTime = Utility.msCurrentTime;
    DateTime timeOfNextCheck =
        DateTime.fromMillisecondsSinceEpoch(currentTime).add(thirtyMins);
    Tuple2<bool?, DateTime>? accessStatus;
    bool isLocationVerified = false;
    bool isPermissionGranted = false;
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
    trace('stored_access_loaded', fields: {
      'hasStoredAccess': loadedLocationInfo != null,
      'storedAllowed': accessStatus?.item1,
      'nextCheck': accessStatus?.item2.toUtc().toIso8601String(),
    });
    if (accessStatus == null) {
      // nothing is stored
      if (!forceDeviceCheck) {
        trace('access_empty', fields: {'reason': 'no_stored_access'});
        return LocationProfile.empty();
      }
      //If we need to force the hardware check on gps then we need to set the time check as earlier than now. This might be a hack.
      accessStatus = Tuple2(false,
          DateTime.fromMillisecondsSinceEpoch(currentTime).add(-thirtyMins));
      locationData[isAccessPermitedKey] = true;
      locationData[timeOfLastAccessKey] = DateTime(0).millisecondsSinceEpoch;
      await _secureStorageManager.writeLocationAccess(locationData);
    }

    if (statusCheck) {
      LocationProfile locationProfile = LocationProfile();
      locationProfile.position = retValue;
      locationProfile.permission = accessStatus.item1 == true
          ? PermissionProfile.accept()
          : loadedLocationInfo == null
              ? PermissionProfile.unknown()
              : PermissionProfile.deny();
      lastLookup =
          loadedLocationInfo == null ? DateTime(0) : Utility.currentTime();
      if (accessStatus.item2.isBefore(DateTime.fromMicrosecondsSinceEpoch(0))) {
        locationProfile.permission = PermissionProfile.unknown();
      }

      trace('access_status_only', fields: {
        'permissionGranted': locationProfile.isGranted,
        'isDefaultPosition': true,
      });
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

      trace('access_denied_by_user');
      return locationProfile;
    }

    if (!denyAccess &&
        (forceDeviceCheck ||
            accessStatus.item1 != false ||
            accessStatus.item2.millisecondsSinceEpoch <
                referenceTimeForNextCheck)) {
      trace('access_device_lookup');
      retValue = await Utility.determineDevicePosition(diagnosticId: lookupId)
          .then((value) {
        // A normal return means the permission checks passed, but acquisition
        // can still have timed out and returned the placeholder.
        isPermissionGranted = true;
        isLocationVerified = Utility.isValidPosition(value);
        lastLookup = Utility.currentTime();
        return value;
      }).catchError((onError) async {
        trace('access_device_error', error: onError);
        if (onError is PermissionRequestInProgressException) {
          lastLookup = DateTime(0);
          return Utility.getDefaultPosition();
        }
        lastLookup = Utility.currentTime();
        isLocationVerified = false;
        // Disabled services and acquisition failures must not revoke consent.
        // Re-read Android/iOS permission without opening another prompt.
        try {
          final permission = await Geolocator.checkPermission();
          isPermissionGranted = permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
        } catch (_) {
          isPermissionGranted = accessStatus?.item1 == true;
        }
        referenceTimeForNextCheck = timeOfNextCheck.millisecondsSinceEpoch;
        return retValue;
      });
      locationData[isAccessPermitedKey] = isPermissionGranted;
      locationData[timeOfLastAccessKey] = referenceTimeForNextCheck;
    } else {
      trace('access_device_lookup_skipped',
          fields: {'reason': 'stored_denial_not_expired'});
      timeOfNextCheck =
          accessStatus.item2.millisecondsSinceEpoch < referenceTimeForNextCheck
              ? timeOfNextCheck
              : accessStatus.item2;
      locationData[isAccessPermitedKey] = isLocationVerified;
      locationData[timeOfLastAccessKey] =
          timeOfNextCheck.millisecondsSinceEpoch;
    }
    if (lastLookup.isBefore(Utility.unixTime())) {
      trace('access_empty',
          fields: {'reason': 'permission_request_in_progress'});
      locationData[isAccessPermitedKey] = true;
      locationData[timeOfLastAccessKey] = DateTime(0).millisecondsSinceEpoch;
      return LocationProfile.empty();
    }

    await _secureStorageManager.writeLocationAccess(locationData);
    LocationProfile locationProfile = LocationProfile();
    locationProfile.position = retValue;
    if (isLocationVerified) {
      locationProfile.lastTimeLoaded = DateTime.now();
    }
    locationProfile.permission = isPermissionGranted
        ? PermissionProfile.accept()
        : PermissionProfile.deny();
    trace('access_finished', fields: {
      'permissionGranted': locationProfile.isGranted,
      'isLocationVerified': isLocationVerified,
      'isDefaultPosition': retValue == Utility.getDefaultPosition(),
      'lastTimeLoaded':
          locationProfile.lastTimeLoaded?.toUtc().toIso8601String(),
    });
    return locationProfile;
  }
}
