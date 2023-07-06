import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
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
            accessToken, tokenType, expirationTime, provider);

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
      String accessToken,
      String refreshToken,
      String email,
      String provider,
      String providerKey) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    String timeZone = await FlutterTimezone.getLocalTimezone();
    final queryParameters = {
      'AccessToken': accessToken,
      'RefreshToken': refreshToken,
      'providerKey': providerKey,
      'Email': email,
      'ThirdPartyType': provider,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'grant_type': 'ThirdPartyAuthentication',
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
          provider);
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
}
