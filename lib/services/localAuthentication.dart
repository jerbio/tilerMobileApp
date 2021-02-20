import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/authorization.dart';

class Authentication {
  final storage = new FlutterSecureStorage();
  final _credentialKey = 'credentials';
  AuthenticationData cachedCredentials;

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
    AuthenticationData authenticationData = await readCredentials();
    cachedCredentials = authenticationData;
    if (cachedCredentials != null) {
      if (cachedCredentials.isExpired()) {
        Authorization authorization = new Authorization();
        if (cachedCredentials.username != null &&
            cachedCredentials.username.isNotEmpty &&
            cachedCredentials.password != null &&
            cachedCredentials.password.isNotEmpty) {
          authenticationData = await authorization.getAuthenticationInfo(
              cachedCredentials.username, cachedCredentials.password);
          if (authenticationData.isValid) {
            cachedCredentials = authenticationData;
          } else {
            cachedCredentials = null;
          }
        }
      }
    }
  }

  Future<AuthenticationData> readCredentials() async {
    String credentialJsonString = await storage.read(key: _credentialKey);
    AuthenticationData retValue;
    if (credentialJsonString != null && credentialJsonString.length > 0) {
      retValue =
          AuthenticationData.fromLocalStorage(jsonDecode(credentialJsonString));
    } else {
      return null;
    }
    return retValue;
  }

  bool isCachedCredentialValid() {
    bool retValue = false;
    if (cachedCredentials != null) {
      if (!cachedCredentials.isExpired()) {
        retValue = true;
      }
    }

    return retValue;
  }

  Future<bool> isUserAuthenticated() async {
    bool retValue = false;
    if (isCachedCredentialValid()) {
    } else {
      await reLoadCredentialsCache();
      retValue = isCachedCredentialValid();
    }
    return retValue;
  }
}
