// import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../constants.dart' as Constants;

List<String> scopes = Constants.googleApiScopes;

class GoogleSignInApi {
  // static final _googleSignIn = GoogleSignIn(
  //     serverClientId: dotenv.env[Constants.googleClientDefaultKey],
  //     scopes: scopes,
  //     forceCodeForRefreshToken: true);

  // static GoogleSignInAccount? get googleUser {
  //   return _googleUser;
  // }

  // static GoogleSignInAccount? _googleUser;
  // static Future<GoogleSignInAccount?> login() async {
  //   try {
  //     _googleUser = await _googleSignIn.signIn();
  //     return _googleUser;
  //   } catch (e) {
  //     throw e;
  //   }
  // }

  // static Future<GoogleSignInAccount?> logout() {
  //   return _googleSignIn.signOut();
  // }
}
