import 'thirdPartyAuthenticationData.dart';

class AuthResult {
  final ThirdPartyAuthenticationData authData;
  final String displayName;

  AuthResult(this.authData, this.displayName);
}
