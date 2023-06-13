import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/googleSignInApi.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthorizationApi extends AppApi {
  Future<UserPasswordAuthenticationData> registerUser(
      String email,
      String password,
      String userName,
      String confirmPassword,
      String? firstname) async {
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
    UserPasswordAuthenticationData retValue =
        UserPasswordAuthenticationData.noCredentials();

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        return await UserPasswordAuthenticationData.getAuthenticationInfo(
            queryUserName, password);
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

  Future<AuthenticationData?> signInToGoogle() async {
    Future<Map<String, dynamic>> getRefreshToken(String clientId,
        String clientSecret, String serverAuthCode, List<String> scopes) async {
      final String refreshTokenEndpoint = 'https://oauth2.googleapis.com/token';

      final Map<String, dynamic> requestBody = {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'code': serverAuthCode,
        'redirect_uri': 'https://${Constants.tilerDomain}/signin-google',
        'scope': scopes.join(' '),
      };

      final http.Response response = await http.post(
        Uri.parse(refreshTokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to authenticate user account');
      }
    }

    var googleUser = await GoogleSignInApi.login();
    if (googleUser != null) {
      var googleAuthentication = await googleUser.authentication;
      var authHeaders = await googleUser.authHeaders;
      print(authHeaders);

      String clientId = dotenv.env[Constants.googleClientIdKey]!;
      String clientSecret = dotenv.env[Constants.googleClientSecretKey]!;

      String? refreshToken;
      String? accessToken = googleAuthentication.accessToken;
      if (googleUser.serverAuthCode != null) {
        refreshToken = googleAuthentication.idToken!;
        final List<String> requestedScopes = [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events.readonly',
          "https://www.googleapis.com/auth/calendar.readonly",
          "https://www.googleapis.com/auth/calendar.events",
          'https://www.googleapis.com/auth/userinfo.email'
        ];
        Map serverResponse = await getRefreshToken(clientId, clientSecret,
            googleUser.serverAuthCode!, requestedScopes);

        refreshToken = serverResponse['refresh_token'];
        accessToken = serverResponse['access_token'];
      }
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      Uri uri = Uri.https(url, 'account/MobileExternalLogin');
      String providerName = 'Google';
      Map<String, dynamic> parameters = {
        'Email': googleUser.email,
        'AccessToken': accessToken,
        'DisplayName': googleUser.displayName,
        'ProviderKey': googleUser.id,
        'ThirdPartyType': providerName,
        'RefreshToken': refreshToken
      };

      var response = await http.post(uri,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: parameters,
          encoding: Encoding.getByName("utf-8"));

      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          ThirdPartyAuthenticationData retValue =
              await ThirdPartyAuthenticationData.getThirdPartyuthentication(
                  accessToken!,
                  refreshToken!,
                  googleUser.email,
                  providerName,
                  googleUser.id);
          return retValue;
        }
        String tilerErrorMessage = errorMessage(jsonResult);
        TilerError tilerError = TilerError(message: tilerErrorMessage);
        throw tilerError;
      }
    }
    throw TilerError();
  }
}
