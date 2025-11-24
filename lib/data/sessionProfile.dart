import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/api/userApi.dart';

class SessionProfile {
  UserProfile? userProfile;
  LocationProfile? locationProfile;
  AccessManager accessManager = AccessManager();
  UserApi userApi = UserApi(
    getContextCallBack: () => null,
  );
  bool isInitialized = false;

  Future initialize({
    Function? getContextCallBack,
  }) async {
    isInitialized = true;
    var locationAccessResponse = await accessManager.locationAccess(
        statusCheck: true, forceDeviceCheck: true);
    locationProfile = locationAccessResponse;
    if (getContextCallBack != null) {
      userApi = UserApi(
        getContextCallBack: getContextCallBack,
      );
    }
    userProfile = await userApi.getUserProfile();
  }

  Future<Location?> getLatestLocation() async {
    var locationAccessResponse = await accessManager.locationAccess();
    locationProfile = locationAccessResponse;
    return locationProfile?.location;
  }

  Future<UserProfile?> getUserProfile() async {
    return await userApi.getUserProfile();
  }

  Future<UserProfile?> updateUserProfile(UserProfile userProfile) async {
    return await userApi.updateUserProfile(userProfile);
  }

}
