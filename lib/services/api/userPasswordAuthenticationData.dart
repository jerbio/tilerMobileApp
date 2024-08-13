import 'dart:convert';

import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/authorization.dart';

import 'package:http/http.dart' as http;
import '../../constants.dart' as Constants;

class UserPasswordAuthenticationData extends AuthenticationData {
  bool isDefault = false;
  String? username;
  String? password;

  late final String? errorMessage;

  UserPasswordAuthenticationData();
  UserPasswordAuthenticationData.initializedWithRestData(
      String accessToken, String tokenType, int expirationTime)
      : super.initializedWithRestData(
            accessToken, tokenType, expirationTime, 'tiler');

  UserPasswordAuthenticationData.initializedWithLocalStorage(String accessToken,
      String tokenType, int expirationTime, this.username, this.password,
      {provider = 'tiler'}) {
    this.tokenType = tokenType;
    this.expirationTime = expirationTime;
    this.accessToken = accessToken;

    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.expirationTime != null);
    assert(this.username != null);
    assert(this.password != null);

    this.isValid = !isExpired();
  }

  UserPasswordAuthenticationData.noCredentials() {
    isDefault = true;
    this.accessToken = "";
    tokenType = "";
    expirationTime = -1;
  }

  toJson() {
    var retValue = super.toJson();
    retValue['username'] = username;
    retValue['password'] = password;
    return retValue;
  }

  factory UserPasswordAuthenticationData.fromLocalStorage(
      Map<String, dynamic> json) {
    return UserPasswordAuthenticationData.initializedWithLocalStorage(
        json['accessToken'],
        json['tokenType'],
        json['expiresIn'],
        json['username'],
        json['password'],
        provider: (json.containsKey('provider') ? json['provider'] : 'tiler'));
  }

  static Future<UserPasswordAuthenticationData> getAuthenticationInfo(
      String userName, String password) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    final queryParameters = {
      'username': userName,
      'password': password,
      'grant_type': 'password'
    };

    var requestBody = 'username=' +
        userName +
        '&password=' +
        password +
        '&grant_type=password';
    Uri uri = Uri.https(url, 'account/token', queryParameters);
    http.Response response = await http.post(uri,
        headers: {"Content-Type": "text/plain"},
        body: requestBody,
        encoding: Encoding.getByName("utf-8"));

    UserPasswordAuthenticationData retValue =
        UserPasswordAuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      var retValue = UserPasswordAuthenticationData.initializedWithRestData(
        jsonResult['access_token'],
        jsonResult['token_type'],
        jsonResult['expires_in'],
      );
      retValue.username = userName;
      retValue.password = password;
      Constants.userName = userName;
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

  Future<AuthenticationData> reloadAuthenticationData() {
    return getAuthenticationInfo(this.username!, this.password!);
  }
}
