import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tuple/tuple.dart';

import 'api/authorization.dart';
import '../../constants.dart' as Constants;

class Authentication {
  final storage = new FlutterSecureStorage();
  final _credentialKey = 'credentials';
  AuthenticationData? cachedCredentials;

  Future saveCredentials(AuthenticationData credentials) async {
    String credentialJsonString = jsonEncode(credentials.toJson());
    await storage.write(key: _credentialKey, value: credentialJsonString);
    cachedCredentials = credentials;
  }

  Future deleteCredentials() async {
    await storage.delete(key: _credentialKey);
  }

  void deauthenticateCredentials() async {
    await deleteCredentials();
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
    String? credentialJsonString = await storage.read(key: _credentialKey);
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
