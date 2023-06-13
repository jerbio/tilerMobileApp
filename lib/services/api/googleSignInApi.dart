import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../constants.dart' as Constants;

const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  "https://www.googleapis.com/auth/calendar.readonly",
  "https://www.googleapis.com/auth/calendar.events",
  'https://www.googleapis.com/auth/userinfo.email'
];

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
      clientId: dotenv.env[Constants.googleClientIdKey],
      scopes: scopes,
      forceCodeForRefreshToken: true);

  static Future<GoogleSignInAccount?> login() {
    return _googleSignIn.signIn();
  }
}
