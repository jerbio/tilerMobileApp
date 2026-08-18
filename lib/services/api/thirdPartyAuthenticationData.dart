import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tiler_app/services/api/appleSignInApi.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class ThirdPartyAuthenticationData extends AuthenticationData {
  bool isDefault = false;
  String? refreshToken;
  String? providerKey;

  late final String? errorMessage;

  ThirdPartyAuthenticationData();
  ThirdPartyAuthenticationData.initializedWithRestData(String accessToken,
      String tokenType, this.providerKey, int expirationTime, String provider)
      : super.initializedWithRestData(
            accessToken, tokenType, expirationTime, provider,);

  ThirdPartyAuthenticationData.initializedWithLocalStorage(
      String accessToken,
      String tokenType,
      String providerKey,
      int expirationTime,
      this.refreshToken,
      String provider) {
    this.tokenType = tokenType;
    this.expirationTime = expirationTime;
    this.accessToken = accessToken;
    this.providerKey = providerKey;
    this.provider = provider;

    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.providerKey != null);

    this.isValid = !isExpired();
  }

  ThirdPartyAuthenticationData.noCredentials() {
    isDefault = true;
    this.accessToken = "";
    tokenType = "";
    providerKey = "";
    expirationTime = -1;
  }

  toJson() {
    var retValue = super.toJson();
    retValue['refreshToken'] = refreshToken;
    retValue['providerKey'] = providerKey;
    return retValue;
  }

  static Future<ThirdPartyAuthenticationData> getThirdPartyuthentication(
    String email,
    String provider,
    String providerKey, {
    String? idToken,
  }) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    String timeZone = await FlutterTimezone.getLocalTimezone();
    // Group 4: this grant is identity-only. The calendar auth (and its access/refresh tokens) is
    // linked earlier by MobileExternalLogin, which is the single place the one-time auth code is
    // exchanged server-side. The grant just re-verifies the id_token and mints the Tiler bearer.
    final queryParameters = {
      'providerKey': providerKey,
      'Email': email,
      'ThirdPartyType': provider,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'grant_type': 'ThirdPartyAuthentication',
      // The server re-verifies this Google-signed id_token and resolves the account from it;
      // Email/providerKey are ignored for identity. Required for Google.
      if (idToken != null) 'IdToken': idToken,
    };

    Uri uri = Uri.https(url, 'account/token');
    http.Response response = await http.post(uri,
        body: queryParameters,
        headers: {"Content-Type": 'application/x-www-form-urlencoded'});

    ThirdPartyAuthenticationData retValue =
        ThirdPartyAuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      var retValue = ThirdPartyAuthenticationData.initializedWithRestData(
          jsonResult['access_token'],
          jsonResult['token_type'],
          providerKey,
          jsonResult['expires_in'],
          provider,
          );
      return retValue;
    } else {
      var jsonResult = jsonDecode(response.body);
      if (jsonResult.containsKey('error') &&
          jsonResult.containsKey('error_description') &&
          jsonResult['error_description'] != null &&
          jsonResult['error_description'].isNotEmpty) {
        retValue.errorMessage = jsonResult['error_description'];
      }
      return retValue;
    }
  }

  factory ThirdPartyAuthenticationData.fromLocalStorage(
      Map<String, dynamic> json) {
    return ThirdPartyAuthenticationData.initializedWithLocalStorage(
        json['accessToken'],
        json['tokenType'],
        json['providerKey'],
        json['expiresIn'],
        json['username'],
        json['provider']);
  }

  /// Exchanges a verified Apple identity token for a Tiler bearer token via the
  /// `AppleAuthentication` OWIN custom grant (identity-only, T6). Mirrors
  /// [getThirdPartyuthentication] but the server re-verifies the Apple identity
  /// token (rather than trusting a provider access token), so no access/refresh
  /// token is sent — only the identity token and the raw nonce.
  static Future<ThirdPartyAuthenticationData> getAppleAuthentication(
    String identityToken,
    String rawNonce,
    String email,
    String providerKey,
  ) async {
    String tilerDomain = Constants.tilerDomain;
    const String provider = 'apple';
    String timeZone = await FlutterTimezone.getLocalTimezone();
    final queryParameters = {
      'IdentityToken': identityToken,
      'RawNonce': rawNonce,
      'Email': email,
      'ThirdPartyType': provider,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      // Tells the server which audience to expect: Android runs Apple's web flow
      // so its tokens carry the Services ID, not the iOS bundle id.
      'ClientType': AppleSignInApi.clientType,
      'grant_type': 'AppleAuthentication',
    };

    Uri uri = Uri.https(tilerDomain, 'account/token');
    http.Response response = await http.post(uri,
        body: queryParameters,
        headers: {"Content-Type": 'application/x-www-form-urlencoded'});

    ThirdPartyAuthenticationData retValue =
        ThirdPartyAuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      var retValue = ThirdPartyAuthenticationData.initializedWithRestData(
        jsonResult['access_token'],
        jsonResult['token_type'],
        providerKey,
        jsonResult['expires_in'],
        provider,
      );
      return retValue;
    } else {
      try {
        var jsonResult = jsonDecode(response.body);
        if (jsonResult.containsKey('error') &&
            jsonResult.containsKey('error_description') &&
            jsonResult['error_description'] != null &&
            jsonResult['error_description'].toString().isNotEmpty) {
          retValue.errorMessage = jsonResult['error_description'];
        }
      } catch (_) {}
      return retValue;
    }
  }

  /// Exchanges a verified Microsoft (Entra) identity token for a Tiler bearer
  /// token via the `MicrosoftAuthentication` OWIN custom grant (identity-only).
  /// Mirrors [getAppleAuthentication]: the server re-verifies the id_token
  /// (signature, per-tenant issuer, audience, nonce) and resolves the account
  /// from it, so only the identity token and the raw nonce are sent — no
  /// access/refresh token. Entra echoes the raw nonce into the token's `nonce`
  /// claim, so no client-side hashing is required (unlike Apple).
  static Future<ThirdPartyAuthenticationData> getMicrosoftAuthentication(
    String identityToken,
    String rawNonce,
    String? email,
    String? providerKey,
  ) async {
    String tilerDomain = Constants.tilerDomain;
    const String provider = 'microsoft';
    String timeZone = await FlutterTimezone.getLocalTimezone();
    final queryParameters = {
      'IdentityToken': identityToken,
      'RawNonce': rawNonce,
      'Email': email ?? '',
      'ThirdPartyType': provider,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'grant_type': 'MicrosoftAuthentication',
    };

    Uri uri = Uri.https(tilerDomain, 'account/token');
    http.Response response = await http.post(uri,
        body: queryParameters,
        headers: {"Content-Type": 'application/x-www-form-urlencoded'});

    ThirdPartyAuthenticationData retValue =
        ThirdPartyAuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      var retValue = ThirdPartyAuthenticationData.initializedWithRestData(
        jsonResult['access_token'],
        jsonResult['token_type'],
        providerKey,
        jsonResult['expires_in'],
        provider,
      );
      return retValue;
    } else {
      try {
        var jsonResult = jsonDecode(response.body);
        if (jsonResult.containsKey('error') &&
            jsonResult.containsKey('error_description') &&
            jsonResult['error_description'] != null &&
            jsonResult['error_description'].toString().isNotEmpty) {
          retValue.errorMessage = jsonResult['error_description'];
        }
      } catch (_) {}
      return retValue;
    }
  }
}
