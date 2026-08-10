import 'dart:async';
import 'dart:convert';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appleSignInApi.dart';
import 'package:tiler_app/services/api/emailCodeAuthenticationData.dart';
import 'package:tiler_app/services/api/googleSignInApi.dart';
import 'package:tiler_app/services/api/microsoftSignInApi.dart';
import 'package:tiler_app/services/api/thirdPartyAuthenticationData.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';

import '../../data/forgot_password_response.dart';
import 'thirdPartyAuthResult.dart';

class AuthorizationApi extends AppApi {
  static const String emailCodeGrantType = 'EmailCodeAuthentication';

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
      print('Error during registration: ${response.statusCode}');
      print('Response body: ${response.body}');
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

  Future<AuthResult?> signInWithApple() async {
    return await processAppleLogin();
  }

  Future<AuthResult?> signInWithMicrosoft() async {
    return await processMicrosoftLogin();
  }

  /// "Sign in with Apple" (identity-only). Mirrors [processAndroidGoogleLogin]:
  /// two server round-trips — (1) `Account/AppleMobileSignIn` creates/links the
  /// Tiler user and the (`apple`, sub) login row, then (2) the
  /// `AppleAuthentication` OWIN grant re-verifies the identity token and issues a
  /// Tiler bearer token. Errors and user cancellation resolve to `null` so the
  /// caller can react uniformly.
  ///
  /// iOS uses the native sheet; Android has no native Apple SDK, so the plugin
  /// runs Apple's web flow in a Chrome Custom Tab. The server is told which
  /// surface it was so it can expect the right `aud` claim.
  Future<AuthResult?> processAppleLogin() async {
    try {
      final String rawNonce = AppleSignInApi.generateRawNonce();
      final String hashedNonce = AppleSignInApi.sha256OfString(rawNonce);
      // On Android the response returns via a browser redirect, so round-trip a
      // random state and reject any response that doesn't echo it back.
      final String requestState = AppleSignInApi.generateRawNonce();
      final AuthorizationCredentialAppleID credential =
          await AppleSignInApi.login(hashedNonce, state: requestState);

      if (credential.state != null && credential.state != requestState) {
        throw TilerError(
            Message: 'Apple sign-in response did not match the request');
      }

      final String? identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw TilerError(Message: 'Apple sign-in did not return an identity token');
      }

      final String firstName = credential.givenName ?? '';
      final String lastName = credential.familyName ?? '';
      final String email = credential.email ?? '';
      // Apple only returns `userIdentifier` on Apple platforms. On Android it is
      // always null, so fall back to the `sub` claim of the identity token — the
      // same value, and the server independently re-derives it from the verified
      // token anyway, so this is only used for local bookkeeping.
      final String providerKey =
          credential.userIdentifier ?? _subjectFromIdentityToken(identityToken);
      final String timeZone = await FlutterTimezone.getLocalTimezone();

      // Step 1: create/link the Tiler account (Apple only returns name/email on
      // the first sign-in, so forward whatever it gives us).
      await _appleMobileSignIn(
        identityToken: identityToken,
        rawNonce: rawNonce,
        firstName: firstName,
        lastName: lastName,
        timeZone: timeZone,
      );

      // Step 2: exchange the verified identity token for a Tiler bearer token.
      ThirdPartyAuthenticationData authData =
          await ThirdPartyAuthenticationData.getAppleAuthentication(
              identityToken, rawNonce, email, providerKey);

      final String displayName =
          [firstName, lastName].where((p) => p.isNotEmpty).join(' ');
      return AuthResult(authData, displayName);
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled the native sheet — treat as a silent no-op.
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      print(e);
    } catch (e) {
      print(e);
    }

    return null;
  }

  /// "Sign in with Microsoft" (Entra, identity-only). Mirrors [processAppleLogin]:
  /// AppAuth runs the interactive Entra sign-in and returns an `id_token`, then
  /// two server round-trips follow — (1) `Account/MicrosoftMobileSignIn`
  /// creates/links the Tiler user and the (`microsoft`, sub) login row, then (2)
  /// the `MicrosoftAuthentication` OWIN grant re-verifies the identity token and
  /// issues a Tiler bearer token. User cancellation and errors resolve to `null`.
  Future<AuthResult?> processMicrosoftLogin() async {
    try {
      final MicrosoftSignInResult? signIn = await MicrosoftSignInApi.login();
      // Null means the user cancelled the Entra sheet — silent no-op.
      if (signIn == null) {
        return null;
      }

      final String identityToken = signIn.identityToken;
      if (identityToken.isEmpty) {
        throw TilerError(
            Message: 'Microsoft sign-in did not return an identity token');
      }

      final String firstName = signIn.firstName;
      final String lastName = signIn.lastName;
      final String email = signIn.email ?? '';
      // Entra always returns `sub`, but fall back to decoding the token locally
      // just in case; the server independently derives it from the verified token.
      final String providerKey =
          signIn.providerKey ?? _subjectFromIdentityToken(identityToken);
      final String timeZone = await FlutterTimezone.getLocalTimezone();

      // Step 1: create/link the Tiler account.
      await _microsoftMobileSignIn(
        identityToken: identityToken,
        rawNonce: signIn.rawNonce,
        firstName: firstName,
        lastName: lastName,
        timeZone: timeZone,
      );

      // Step 2: exchange the verified identity token for a Tiler bearer token.
      ThirdPartyAuthenticationData authData =
          await ThirdPartyAuthenticationData.getMicrosoftAuthentication(
              identityToken, signIn.rawNonce, email, providerKey);

      final String displayName =
          [firstName, lastName].where((p) => p.isNotEmpty).join(' ');
      return AuthResult(authData, displayName);
    } catch (e) {
      print(e);
    }

    return null;
  }

  /// Reads the `sub` claim out of an Apple identity token without verifying it.
  ///
  /// Safe as a local convenience only: this value is never trusted for
  /// authorization. The server re-verifies the token's signature, audience and
  /// nonce and derives `sub` itself, so a tampered token fails there regardless.
  String _subjectFromIdentityToken(String identityToken) {
    try {
      final parts = identityToken.split('.');
      if (parts.length < 2) {
        return '';
      }
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return (jsonDecode(payload) as Map<String, dynamic>)['sub']?.toString() ??
          '';
    } catch (_) {
      return '';
    }
  }

  /// Creates/links the Tiler user for an Apple identity (T6). Matches
  /// `AppleMobileSignInViewModel` on the server. Throws [TilerError] on failure.
  Future<void> _appleMobileSignIn({
    required String identityToken,
    required String rawNonce,
    required String firstName,
    required String lastName,
    required String timeZone,
  }) async {
    String tilerDomain = Constants.tilerDomain;
    Uri uri = Uri.https(tilerDomain, 'Account/AppleMobileSignIn');
    Map<String, dynamic> parameters = {
      'IdentityToken': identityToken,
      'RawNonce': rawNonce,
      'FirstName': firstName,
      'LastName': lastName,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'ClientType': AppleSignInApi.clientType,
    };

    var response = await http.post(uri,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: parameters,
        encoding: Encoding.getByName("utf-8"));

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        return;
      }
      print('Error during Apple sign-in: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw TilerError(Message: errorMessage(jsonResult));
    }

    throw TilerError(Message: 'Failed to authenticate user');
  }

  /// Creates/links the Tiler user for a Microsoft identity. Matches
  /// `MicrosoftMobileSignInViewModel` on the server (no `ClientType`: the server
  /// picks the expected audience from the `microsoftClientIds` allow-list).
  /// Throws [TilerError] on failure.
  Future<void> _microsoftMobileSignIn({
    required String identityToken,
    required String rawNonce,
    required String firstName,
    required String lastName,
    required String timeZone,
  }) async {
    String tilerDomain = Constants.tilerDomain;
    Uri uri = Uri.https(tilerDomain, 'Account/MicrosoftMobileSignIn');
    Map<String, dynamic> parameters = {
      'IdentityToken': identityToken,
      'RawNonce': rawNonce,
      'FirstName': firstName,
      'LastName': lastName,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
    };

    var response = await http.post(uri,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: parameters,
        encoding: Encoding.getByName("utf-8"));

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        return;
      }
      print('Error during Microsoft sign-in: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw TilerError(Message: errorMessage(jsonResult));
    }

    throw TilerError(Message: 'Failed to authenticate user');
  }

  Future<void> requestEmailAuthenticationCode(String email) async {
    String tilerDomain = Constants.tilerDomain;
    Uri uri = Uri.https(tilerDomain, 'Account/emailauthentication');
    final requestBody = await injectRequestParams({'Email': email});
    http.Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
        encoding: Encoding.getByName('utf-8'));

    Map<String, dynamic> jsonResult = jsonDecode(response.body);
    if (response.statusCode == 200 && isJsonResponseOk(jsonResult)) {
      return;
    }

    final tilerErrorMessage = isTilerRequestError(jsonResult)
        ? errorMessage(jsonResult)
        : 'Failed to send verification code';
    throw TilerError(Message: tilerErrorMessage);
  }

  Future<EmailCodeAuthenticationData> verifyEmailCode(
      String email, String code) async {
    String tilerDomain = Constants.tilerDomain;
    Uri uri = Uri.https(tilerDomain, 'account/token');
    String timeZone = await FlutterTimezone.getLocalTimezone();

    Map<String, String> parameters = {
      'Email': email,
      'Code': code,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'grant_type': emailCodeGrantType,
    };

    http.Response response = await http.post(uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: parameters,
        encoding: Encoding.getByName('utf-8'));

    EmailCodeAuthenticationData retValue =
        EmailCodeAuthenticationData.noCredentials();
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      Constants.userName = email;
      return EmailCodeAuthenticationData.initializedWithRestData(
        jsonResult['access_token'],
        jsonResult['token_type'],
        jsonResult['expires_in'],
        email,
      );
    }

    try {
      var jsonResult = jsonDecode(response.body);
      if (jsonResult.containsKey('error_description') &&
          jsonResult['error_description'] != null &&
          jsonResult['error_description'].toString().isNotEmpty) {
        retValue.errorMessage = jsonResult['error_description'];
      }
    } catch (_) {}

    return retValue;
  }

  Future<ThirdPartyAuthenticationData> getBearerToken(
      {required String email,
      required String serverAuthCode,
      required String redirectUri,
      required String displayName,
      required String providerId,
      required String thirdpartyType,
      required String timeZone,
      String? idToken}) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    Uri uri = Uri.https(url, 'account/MobileExternalLogin');
    String providerName = 'Google';
    Map<String, dynamic> parameters = {
      'Email': email,
      'DisplayName': displayName,
      'ProviderKey': providerId,
      'TimeZone': timeZone,
      'TimeZoneOffset': Utility.getTimeZoneOffset().toString(),
      'ThirdPartyType': thirdpartyType,
      // SECURITY (Group 4): the app no longer ships the OAuth client secret. Instead of exchanging
      // the code on-device, we hand the one-time serverAuthCode (and the redirect uri it was minted
      // against) to the server, which redeems it for the access/refresh tokens it stores and links
      // the calendar. The auth code is single-use, so only this endpoint exchanges it.
      'ServerAuthCode': serverAuthCode,
      'RedirectUri': redirectUri,
      // The server verifies this Google-signed id_token and derives the account identity from it;
      // Email/ProviderKey above are ignored for identity. Required for Google sign-in.
      if (idToken != null) 'IdToken': idToken,
    };

    var response = await http.post(uri,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: parameters,
        encoding: Encoding.getByName("utf-8"));

    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        // The single-use code was consumed by MobileExternalLogin above; the token grant is
        // identity-only, so it only needs the verified id_token to mint the Tiler bearer.
        ThirdPartyAuthenticationData retValue =
            await ThirdPartyAuthenticationData.getThirdPartyuthentication(
                email, providerName, providerId,
                idToken: idToken);
        return retValue;
      }
      print('Error during third-party authentication: ${response.statusCode}');
      print('Response body: ${response.body}');
      String tilerErrorMessage = errorMessage(jsonResult);
      TilerError tilerError = TilerError(Message: tilerErrorMessage);
      throw tilerError;
    }

    TilerError tilerError = TilerError(Message: 'Failed to authenticate user');
    throw tilerError;
  }

  Future<Map<String, dynamic>?> addGoogleCalendar() async {
    if (GoogleSignInApi.googleUser != null) {
      GoogleSignInApi.googleUser!.clearAuthCache();
      await GoogleSignInApi.logout();
    }

    // SECURITY (Group 4): the OAuth code exchange now happens server-side, so the app no longer
    // ships or uses the Google client secret for calendar linking. We sign in, hand the one-time
    // serverAuthCode (plus the redirect uri it was minted against) to the Tiler server, and the
    // server redeems it for the access/refresh tokens it stores.
    GoogleSignInAccount? googleUser = await GoogleSignInApi.login()
        .then((value) => value)
        .catchError((onError) {
      print("ERROR GoogleSignInApi.login" + onError.toString());
      return null;
    });

    String? serverAuthCode = googleUser?.serverAuthCode;
    if (googleUser != null && serverAuthCode != null) {
      String providerName = 'Google';

      Map<String, String?> thirdpartyCredentialPostData = {
        'ThirdPartyId': googleUser.id,
        'Email': googleUser.email,
        'DisplayName': googleUser.displayName,
        'Provider': providerName,
        'ServerAuthCode': serverAuthCode,
        'RedirectUri': 'https://${Constants.tilerDomain}/signin-google',
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

    return null;
  }

  Future<AuthResult?> processAndroidGoogleLogin() async {
    try {
      if (GoogleSignInApi.googleUser != null) {
        GoogleSignInApi.googleUser!.clearAuthCache();
        await GoogleSignInApi.logout();
      }

      // SECURITY (Group 4): identity-only on the client. We sign in natively to get the one-time
      // serverAuthCode and the OIDC id_token, then hand both (plus the redirect uri the code was
      // minted against) to the server. The server exchanges the code for tokens using the client
      // secret it alone holds, links the calendar, and mints the Tiler bearer — the app never
      // touches the OAuth client secret.
      GoogleSignInAccount? googleUser = await GoogleSignInApi.login()
          .then((value) => value)
          .catchError((onError) {
        print("ERROR GoogleSignInApi.login" + onError.toString());
        return null;
      });

      if (googleUser != null) {
        final googleAuthentication = await googleUser.authentication;
        final String? serverAuthCode = googleUser.serverAuthCode;
        final String? idToken = googleAuthentication.idToken;
        if (serverAuthCode != null && idToken != null) {
          String providerName = 'Google';
          String timeZone = await FlutterTimezone.getLocalTimezone();
          ThirdPartyAuthenticationData authData = await getBearerToken(
              email: googleUser.email,
              providerId: googleUser.id,
              serverAuthCode: serverAuthCode,
              redirectUri: 'https://${Constants.tilerDomain}/signin-google',
              displayName: googleUser.displayName ?? '',
              timeZone: timeZone,
              thirdpartyType: providerName,
              idToken: idToken);

          return AuthResult(authData, googleUser.displayName ?? '');
        }
      }

      throw TilerError();
    } catch (e) {
      print(e);
    }

    return null;
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
