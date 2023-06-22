import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/googleSignInApi.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:url_launcher/url_launcher.dart';

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

  Future<ThirdPartyAuthenticationData?> iosSignIn() async {
    final List<String> requestedScopes = Constants.googleApiScopes;
    String clientId = dotenv.env[Constants.googleClientDefaultKey]!;
    String nonParsedURI =
        'https://${Constants.tilerDomain}/account/googleMobileSignIn';
    String redirectUri = Uri.encodeComponent(nonParsedURI);

    Future<String> getAuthorizationUrl() async {
      final authUrl = Uri.parse('https://accounts.google.com/o/oauth2/auth?'
          'client_id=$clientId&'
          'redirect_uri=$redirectUri&'
          'response_type=code&'
          'scope=${requestedScopes.join(' ')}');

      return authUrl.toString();
    }

    Future<ThirdPartyAuthenticationData?> handleCallbackAndExchangeToken(
        Uri uri) async {
      if (uri.queryParameters.containsKey('refreshToken') &&
          uri.queryParameters['refreshToken'] != null) {
        final queryParameter = uri.queryParameters;
        String? accessToken = queryParameter['accessToken']!;
        String? refreshToken = queryParameter['refreshToken']!;
        String? providerId = queryParameter['providerId']!;
        String? email = queryParameter['email']!;

        ThirdPartyAuthenticationData retValue =
            await ThirdPartyAuthenticationData.getThirdPartyuthentication(
                accessToken, refreshToken, email, 'google', providerId);

        if (!retValue.isDefault) {
          Authentication localAuthentication = new Authentication();
          await localAuthentication.saveCredentials(retValue);
        }

        return retValue;
      }
      return null;
    }

    MethodChannel _channel = MethodChannel(
        'TILER_THIRD_PARTY_SIGNUP_CHANNEL'); // Replace with the name of your Flutter method channel

// Listen for the authorization callback and handle it
    _channel.setMethodCallHandler((call) async {
      print("THE CHANNEL IS TALKING ");
      print("call.method -> ${call.method} ");
      if (call.method == 'handleAuthorizationCallback') {
        final uri = Uri.parse(call.arguments as String);
        print("uri parsed -> ${uri} ");
        print("uri queryParameters -> ${uri.queryParameters} ");

        AuthenticationData? authenticationData =
            await handleCallbackAndExchangeToken(uri);
      }
    });
    try {
      final authorizationUrl = await getAuthorizationUrl();
      if (await canLaunch(authorizationUrl)) {
        Uri authorizationUri = Uri.parse(authorizationUrl);
        await launchUrl(authorizationUri);
      }
    } catch (error) {
      print(error);
      // Handle sign-in error
    }
    ThirdPartyAuthenticationData? retValue;
    Function retryLogin = () async {
      Authentication localAuthentication = new Authentication();
      var thirdParty = await localAuthentication.readCredentials();
      if (thirdParty != null &&
          thirdParty is ThirdPartyAuthenticationData &&
          !thirdParty.isDefault) {
        retValue = thirdParty;
      }
    };
    int counter = Constants.retryLoginCount;
    while (retValue == null && counter > 0) {
      var futureUpdate = Future.delayed(Constants.retryLoginDuration, () async {
        await retryLogin();
        counter--;
      });
      await futureUpdate;
    }
    if (counter <= 0 && retValue == null) {
      throw TilerError(message: "Google login timed out");
    }

    return retValue;
  }

  Future<AuthenticationData?> signInToGoogle() async {
    if (Platform.isIOS) {
      return await iosSignIn();
    }
    return await processAndroidGoogleLogin();
  }

  Future<ThirdPartyAuthenticationData> getBearerToken(
      {required String email,
      required String accessToken,
      required String refreshToken,
      required String displayName,
      required String providerId,
      required String thirdpartyType}) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    Uri uri = Uri.https(url, 'account/MobileExternalLogin');
    String providerName = 'Google';
    Map<String, dynamic> parameters = {
      'Email': email,
      'AccessToken': accessToken,
      'DisplayName': displayName,
      'ProviderKey': providerId,
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
      TilerError tilerError = TilerError(message: tilerErrorMessage);
      throw tilerError;
    }

    TilerError tilerError = TilerError(message: 'Failed to authenticate user');
    throw tilerError;
  }

  Future<AuthenticationData?> processAndroidGoogleLogin() async {
    String clientId = dotenv.env[Constants.googleClientIdKey]!;
    String clientSecret = dotenv.env[Constants.googleClientSecretKey]!;
    final requestedScopes = Constants.googleApiScopes;
    Future<Map<String, dynamic>> getRefreshToken(String clientId,
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

      print(requestBody);

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

      String? refreshToken;
      String? accessToken = googleAuthentication.accessToken;
      String? serverAuthCode =
          googleUser.serverAuthCode ?? googleAuthentication.idToken;
      if (serverAuthCode != null) {
        refreshToken = googleAuthentication.idToken!;
        Map serverResponse = await getRefreshToken(
            clientId, clientSecret, serverAuthCode, requestedScopes);

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
      return await getBearerToken(
          accessToken: accessToken!,
          email: googleUser.email,
          providerId: googleUser.id,
          refreshToken: refreshToken!,
          displayName: googleUser.displayName!,
          thirdpartyType: providerName);
    }
    throw TilerError();
  }
}
