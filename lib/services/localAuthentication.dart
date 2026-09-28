import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/emailCodeAuthenticationData.dart';
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
          debugPrint('[Auth] stored token expired; re-authenticating '
              '(provider=${cachedCredentials!.provider})');
          authenticationData =
              await authenticationData!.reloadAuthenticationData();
          if (authenticationData.isValid) {
            cachedCredentials = authenticationData;
            debugPrint('[Auth] re-authentication succeeded');
          } else {
            cachedCredentials = null;
            debugPrint('[Auth] re-authentication failed; no valid credential');
          }
        } else {
          // Stored token still valid — nothing to report.
        }
      } else {
        // Signed-out state — normal, nothing to log.
      }
    } catch (e) {
      print('Error reloading credentials: $e');
    }
  }

  /// Forces a re-authentication round-trip regardless of the stored
  /// credential's client-side expiry. Used to recover from servers that
  /// reject a still-"valid" token (e.g. after a signing-key rotation or a
  /// backend-environment switch).
  ///
  /// Returns the refreshed credential when a genuinely new valid token was
  /// obtained, or `null` when the provider cannot re-authenticate
  /// (email-code / third-party sign-in) or the token request failed — in
  /// which case the previous credential is left in place and the caller
  /// should surface the error (the user must sign out and back in).
  Future<AuthenticationData?> forceRefreshCredentials() async {
    final current = cachedCredentials;
    if (current == null) {
      await reLoadCredentialsCache();
      return isCachedCredentialValid() ? cachedCredentials : null;
    }
    try {
      final refreshed = await current.reloadAuthenticationData();
      if (refreshed.isValid && refreshed.accessToken != current.accessToken) {
        cachedCredentials = refreshed;
        debugPrint('[Auth] forced re-authentication succeeded');
        return refreshed;
      }
    } catch (e) {
      print('Error force-refreshing credentials: $e');
    }
    debugPrint('[Auth] forced re-authentication unavailable '
        '(provider=${current.provider})');
    return null;
  }

  Future<AuthenticationData?> readCredentials() async {
    String? credentialJsonString = await storageManager.readCredentials();
    AuthenticationData retValue;
    if (credentialJsonString != null && credentialJsonString.length > 0) {
      Map jsonData = jsonDecode(credentialJsonString);
      if (jsonData.containsKey('provider') &&
          jsonData['provider'] == EmailCodeAuthenticationData.providerName) {
        retValue = EmailCodeAuthenticationData.fromLocalStorage(
            jsonDecode(credentialJsonString));
      } else if (jsonData.containsKey('provider') &&
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
      print('Cached credentials are not valid');
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
