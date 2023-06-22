// import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../constants.dart' as Constants;

List<String> scopes = Constants.googleApiScopes;

class GoogleSignInApi {
  static final googleSignIn = GoogleSignIn(
      clientId: dotenv.env[Constants.googleClientIdKey],
      scopes: scopes,
      // serverClientId: 'https://${Constants.tilerDomain}/signin-google',
      forceCodeForRefreshToken: true);

  static Future<GoogleSignInAccount?> login() {
    // return _googleSignIn.signInSilently();
    return googleSignIn.signIn();
  }
}
