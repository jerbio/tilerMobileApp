import 'dart:async';
import 'dart:convert';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/googleSignInApi.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/forgot_password_response.dart';
import 'thirdPartyAuthResult.dart';

class AuthorizationApi extends AppApi {
  AuthorizationApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
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

  Future<AuthResult?> signInToGoogle() async {
    return await processAndroidGoogleLogin();
  }

  Future<ThirdPartyAuthenticationData> getBearerToken(
      {required String email,
      required String accessToken,
      required String refreshToken,
      required String displayName,
      required String providerId,
      required String thirdpartyType,
      required String timeZone}) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    Uri uri = Uri.https(url, 'account/MobileExternalLogin');
    String providerName = 'Google';
    Map<String, dynamic> parameters = {
      'Email': email,
      'AccessToken': accessToken,
      'DisplayName': displayName,
      'ProviderKey': providerId,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'ThirdPartyType': thirdpartyType,
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
                accessToken, refreshToken, email, providerName, providerId);
        return retValue;
      }
      String tilerErrorMessage = errorMessage(jsonResult);
      TilerError tilerError = TilerError(Message: tilerErrorMessage);
      throw tilerError;
    }

    TilerError tilerError = TilerError(Message: 'Failed to authenticate user');
    throw tilerError;
  }

  Future<Map<String, dynamic>> _getRefreshToken(String clientId,
      String clientSecret, String serverAuthCode, List<String> scopes) async {
    final String refreshTokenEndpoint = 'https://oauth2.googleapis.com/token';

    final Map<String, dynamic> requestBody = {
      'access_type': 'offline',
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

  Future<Map<String, dynamic>?> getRemoteGoogleCredentials() async {
    String clientId = dotenv.env[Constants.googleClientDefaultKey]!;
    String clientSecret = dotenv.env[Constants.googleClientSecretKey]!;
    final requestedScopes = Constants.googleApiScopes;

    var googleUser = await GoogleSignInApi.login()
        .then((value) => value)
        .catchError((onError) {
      print("ERROR GoogleSignInApi.login" + onError.toString());
      print(onError);
    });
    if (googleUser != null) {
      var googleAuthentication = await googleUser.authentication;

      String? refreshToken;
      String? accessToken = googleAuthentication.accessToken;
      String? serverAuthCode =
          googleUser.serverAuthCode ?? googleAuthentication.idToken;
      if (serverAuthCode != null) {
        refreshToken = googleAuthentication.idToken!;
        Map<String, dynamic> serverResponse = await _getRefreshToken(
            clientId, clientSecret, serverAuthCode, requestedScopes);
        serverResponse["googleUser"] = googleUser;
        serverResponse["authCode"] = serverAuthCode;
        return serverResponse;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> addGoogleCalendar() async {
    if (GoogleSignInApi.googleUser != null) {
      GoogleSignInApi.googleUser!.clearAuthCache();
      await GoogleSignInApi.logout();
    }
    Map<String, dynamic>? remoteGoogleCredentials =
        await getRemoteGoogleCredentials();
    GoogleSignInAccount? googleUser = null;
    String? refreshToken = null;
    String? accessToken = null;

    if (remoteGoogleCredentials != null &&
        remoteGoogleCredentials.containsKey('googleUser') &&
        remoteGoogleCredentials.containsKey('refresh_token') &&
        remoteGoogleCredentials.containsKey('access_token')) {
      refreshToken = remoteGoogleCredentials['refresh_token'];
      accessToken = remoteGoogleCredentials['access_token'];
      googleUser = remoteGoogleCredentials["googleUser"];
    }

    if (refreshToken != null && accessToken != null && googleUser != null) {
      String providerName = 'Google';
      String timeZone = await FlutterTimezone.getLocalTimezone();

      Map<String, String?> thirdpartyCredentialPostData = {
        'ThirdPartyId': googleUser.id,
        'AccessToken': accessToken,
        'RefreshToken': refreshToken,
        'Email': googleUser.email,
        'DisplayName': googleUser.displayName,
        'Provider': providerName,
        'ServerAuthCode': googleUser.serverAuthCode,
      };
      return sendPostRequest(
              'api/integrations/google', thirdpartyCredentialPostData,
              injectLocation: false, analyze: false)
          .then((response) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          return jsonResult;
        }
        return null;
      });
    }
  }

  Future<AuthResult?> processAndroidGoogleLogin() async {
    try {
      if (GoogleSignInApi.googleUser != null) {
        GoogleSignInApi.googleUser!.clearAuthCache();
        await GoogleSignInApi.logout();
      }

      Map<String, dynamic>? remoteGoogleCredentials =
          await getRemoteGoogleCredentials();

      GoogleSignInAccount? googleUser = null;
      String? refreshToken = null;
      String? accessToken = null;

      if (remoteGoogleCredentials != null &&
          remoteGoogleCredentials.containsKey('googleUser') &&
          remoteGoogleCredentials.containsKey('refresh_token') &&
          remoteGoogleCredentials.containsKey('access_token')) {
        refreshToken = remoteGoogleCredentials['refresh_token'];
        accessToken = remoteGoogleCredentials['access_token'];
        googleUser = remoteGoogleCredentials["googleUser"];
      }
      if (refreshToken != null && accessToken != null && googleUser != null) {
        String providerName = 'Google';
        String timeZone = await FlutterTimezone.getLocalTimezone();
        ThirdPartyAuthenticationData authData = await getBearerToken(
            accessToken: accessToken,
            email: googleUser.email,
            providerId: googleUser.id,
            refreshToken: refreshToken,
            displayName: googleUser.displayName!,
            timeZone: timeZone,
            thirdpartyType: providerName);

        return AuthResult(authData, googleUser.displayName!);
      }

      throw TilerError();
    } catch (e) {
      print(e);
    }
  }

  Future<bool> deleteTilerAccount() async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    return sendPostRequest('Account/DeleteAccount', {},
            injectLocation: false, analyze: false)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return true;
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.Message!);
      } else {
        error.Message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<Map<String, dynamic>?> statusSupport() async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    // https://localhost-44388-x-if7.conveyor.cloud/home/Supported
    Uri uri = Uri.https(url, 'home/Supported');
    // var header = this.getHeaders();
    // if (header == null) {
    //   throw TilerError(message: 'Issues with authentication');
    // }

    var response = await http.get(uri);
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      return jsonResult;
    }

    return null;
  }

  static Future<ForgotPasswordResponse> sendForgotPasswordRequest(
      String email) async {
    String tilerDomain = Constants.tilerDomain;
    String path = '/Account/VerifyForgotPassword';
    Uri uri = Uri.https(tilerDomain, path);
    var headers = {'Content-Type': 'application/json'};
    var requestBody = jsonEncode({'Email': email});
    print('Sending forgot password request to: $uri');
    print('Request body: $requestBody');
    http.Response response =
        await http.post(uri, headers: headers, body: requestBody);
    print('Forgot password request response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return ForgotPasswordResponse.fromJson({
        "Error": {
          "Code": responseBody["Error"]["Code"],
          "Message": responseBody["Error"]["Message"]
        },
        "Content": responseBody["Content"]
      });
    } else {
      String errorReason =
          "Request failed with status code ${response.statusCode}. Reason: ${response.reasonPhrase}";
      print(errorReason);
      return ForgotPasswordResponse.fromJson({
        "Error": {
          "Code": response.statusCode.toString(),
          "Message":
              "Request failed with status code ${response.statusCode}. Reason: ${response.reasonPhrase}"
        },
        "Content": responseBody["Content"] ?? null
      });
    }
  }
}
