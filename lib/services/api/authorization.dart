import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../constants.dart' as Constants;

class Authorization {
  Future<AuthenticationData> getAuthenticationInfo(
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

    if (response.statusCode == 200) {
      var jsonRsult = jsonDecode(response.body);
      var retValue = AuthenticationData.initializedWithRestData(
        jsonRsult['access_token'],
        jsonRsult['token_type'],
        jsonRsult['expires_in'],
      );
      retValue.username = userName;
      retValue.password = password;
      return retValue;
    } else {
      return AuthenticationData.noCredentials();
    }
  }
}

class AuthenticationData {
  late final String accessToken;
  late final String tokenType;
  late int expirationTime;
  final int instantiationTime = (new DateTime.now()).millisecondsSinceEpoch;
  bool isDefault = false;
  String? username;
  String? password;
  bool isValid = false;

  AuthenticationData.initializedWithRestData(
      this.accessToken, this.tokenType, this.expirationTime) {
    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.expirationTime != null);
    this.expirationTime = this.instantiationTime + (this.expirationTime * 1000);
    this.isValid = !isExpired();
  }

  AuthenticationData.initializedWithLocalStorage(this.accessToken,
      this.tokenType, this.expirationTime, this.username, this.password) {
    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.expirationTime != null);
    assert(this.username != null);
    assert(this.password != null);

    this.isValid = !isExpired();
  }

  AuthenticationData.noCredentials() {
    isDefault = true;
    this.accessToken = "";
    tokenType = "";
    expirationTime = -1;
  }

  // int expiryTimeSinceEpochInMs() {
  //   int retValue = instantiationTime + (expiresIn * 1000);
  //   return retValue;
  // }

  bool isExpired() {
    var now = new DateTime.now().millisecondsSinceEpoch;
    int expiryTime = this.expirationTime;

    bool retValue = now >= expiryTime;
    return retValue;
  }

  toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expirationTime,
      'username': username,
      'password': password
    };
  }

  // factory AuthenticationData.fromJson(Map<String, dynamic> json) {
  //   return AuthenticationData.initializedWithRestData(
  //     json['access_token'],
  //     json['token_type'],
  //     json['expires_in'],
  //   );
  // }

  factory AuthenticationData.fromLocalStorage(Map<String, dynamic> json) {
    return AuthenticationData.initializedWithLocalStorage(
        json['accessToken'],
        json['tokenType'],
        json['expiresIn'],
        json['username'],
        json['password']);
  }
}
