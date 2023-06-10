import 'package:google_sign_in/google_sign_in.dart';

const List<String> scopes = <String>[
  // 'https://www.googleapis.com/auth/contacts.readonly',
  'email',
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  "https://www.googleapis.com/auth/calendar.readonly",
  "https://www.googleapis.com/auth/calendar.events",
  'https://www.googleapis.com/auth/userinfo.email'
];

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
      clientId:
          '518133740160-i5ie6s4h802048gujtmui1do8h2lqlfj.apps.googleusercontent.com',
      scopes: scopes,
      forceCodeForRefreshToken: true);

  static Future<GoogleSignInAccount?> login() {
    return _googleSignIn.signIn();
  }
}
