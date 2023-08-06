import 'dart:convert';

import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class Authentication {
  AuthenticationData? cachedCredentials;
  SecureStorageManager storageManager = SecureStorageManager();

  Future deauthenticateCredentials() async {
    await storageManager.deleteCredentials();
    cachedCredentials = null;
  }

  Future reLoadCredentialsCache() async {
    try {
      AuthenticationData? authenticationData = await readCredentials();
      cachedCredentials = authenticationData;
      if (cachedCredentials != null) {
        if (cachedCredentials!.isExpired()) {
          authenticationData =
              await authenticationData!.reloadAuthenticationData();
          if (authenticationData.isValid) {
            cachedCredentials = authenticationData;
          } else {
            cachedCredentials = null;
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<AuthenticationData?> readCredentials() async {
    String? credentialJsonString = await storageManager.readCredentials();
    AuthenticationData retValue;
    if (credentialJsonString != null && credentialJsonString.length > 0) {
      Map jsonData = jsonDecode(credentialJsonString);
      if (jsonData.containsKey('provider') &&
          jsonData['provider']!.toLowerCase() != 'tiler') {
        retValue = ThirdPartyAuthenticationData.fromLocalStorage(
            jsonDecode(credentialJsonString));
      } else {
        retValue = UserPasswordAuthenticationData.fromLocalStorage(
            jsonDecode(credentialJsonString));
      }
    } else {
      return null;
    }
    return retValue;
  }

  bool isCachedCredentialValid() {
    bool retValue = false;
    if (cachedCredentials != null) {
      if (!cachedCredentials!.isExpired()) {
        retValue = true;
      }
    }

    return retValue;
  }

  saveCredentials(AuthenticationData credentials) async {
    storageManager.saveCredentials(credentials);
    cachedCredentials = credentials;
  }

  Future<Tuple2<bool, String>> isUserAuthenticated() async {
    bool retValue = false;
    String message = '';
    if (isCachedCredentialValid()) {
      retValue = true;
    } else {
      await reLoadCredentialsCache().then((value) {
        retValue = isCachedCredentialValid();
      }).catchError((onError) {
        retValue = false;
        message = Constants.cannotVerifyError;
      });
    }
    return Tuple2<bool, String>(retValue, message);
  }
}
