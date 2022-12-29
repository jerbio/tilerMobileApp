import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';

class Authorization extends AppApi {
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

    AuthenticationData retValue = AuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      var retValue = AuthenticationData.initializedWithRestData(
        jsonResult['access_token'],
        jsonResult['token_type'],
        jsonResult['expires_in'],
      );
      retValue.username = userName;
      retValue.password = password;
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

  Future<AuthenticationData> registerUser(String email, String password,
      String userName, String confirmPassword, String? firstname) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    String queryFirstName = firstname == null ? email : firstname;
    String queryUserName = userName.isEmpty ? email : userName;

    final queryParameters = await injectRequestParams({
      'Username': queryUserName,
      'Password': password,
      'FirstName': queryFirstName,
      'ConfirmPassword': confirmPassword,
      'Email': email,
    });

    Uri uri = Uri.https(url, 'Account/mobileSignup');
    http.Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(queryParameters),
        encoding: Encoding.getByName('utf-8'));
    AuthenticationData retValue = AuthenticationData.noCredentials();

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return await getAuthenticationInfo(queryUserName, password);
        }
      }

      retValue.errorMessage = errorMessage(jsonResult);
      retValue.isValid = false;
      return retValue;
    } else {
      var jsonResult = jsonDecode(response.body);
      if (jsonResult.containsKey('error') &&
          jsonResult.containsKey('error_description') &&
          jsonResult.containsKey('error_description') != null &&
          jsonResult.containsKey('error_description').isNotEmpty) {
        retValue.errorMessage = jsonResult['error_description'];
      }
      return retValue;
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
  late final String? errorMessage;

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

  factory AuthenticationData.fromLocalStorage(Map<String, dynamic> json) {
    return AuthenticationData.initializedWithLocalStorage(
        json['accessToken'],
        json['tokenType'],
        json['expiresIn'],
        json['username'],
        json['password']);
  }
}
