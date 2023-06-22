// import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../constants.dart' as Constants;

List<String> scopes = Constants.googleApiScopes;

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
      clientId: dotenv.env[Constants.googleClientIdKey],
      scopes: scopes,
      forceCodeForRefreshToken: true);

  static Future<GoogleSignInAccount?> login() {
    return _googleSignIn.signIn();
  }
}
