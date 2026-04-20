import 'package:tiler_app/services/api/authenticationData.dart';

class EmailCodeAuthenticationData extends AuthenticationData {
  static const String providerName = 'tiler-email-code';

  bool isDefault = false;
  String? email;
  String? errorMessage;

  EmailCodeAuthenticationData();

  EmailCodeAuthenticationData.initializedWithRestData(
    String accessToken,
    String tokenType,
    int expirationTime,
    this.email,
  ) : super.initializedWithRestData(
          accessToken,
          tokenType,
          expirationTime,
          providerName,
        );

  EmailCodeAuthenticationData.initializedWithLocalStorage(
    String accessToken,
    String tokenType,
    int expirationTime,
    this.email,
  ) {
    this.tokenType = tokenType;
    this.expirationTime = expirationTime;
    this.accessToken = accessToken;
    this.provider = providerName;

    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.email != null);

    isValid = !isExpired();
  }

  EmailCodeAuthenticationData.noCredentials() {
    isDefault = true;
    accessToken = '';
    tokenType = '';
    expirationTime = -1;
    provider = providerName;
  }

  @override
  Map<String, dynamic> toJson() {
    final retValue = super.toJson();
    retValue['email'] = email;
    return retValue;
  }

  factory EmailCodeAuthenticationData.fromLocalStorage(
    Map<String, dynamic> json,
  ) {
    return EmailCodeAuthenticationData.initializedWithLocalStorage(
      json['accessToken'],
      json['tokenType'],
      json['expiresIn'],
      json['email'],
    );
  }

  @override
  Future<AuthenticationData> reloadAuthenticationData() async {
    return EmailCodeAuthenticationData.noCredentials();
  }
}
