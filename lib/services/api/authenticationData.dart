class AuthenticationData {
  final int instantiationTime = (new DateTime.now()).millisecondsSinceEpoch;
  late final String? provider;
  late final String? accessToken;
  late final String? tokenType;
  bool isValid = false;
  late int expirationTime;

  AuthenticationData();
  AuthenticationData.initializedWithRestData(
      this.accessToken, this.tokenType, this.expirationTime, this.provider) {
    assert(this.accessToken != null);
    assert(this.tokenType != null);
    assert(this.provider != null);
    assert(this.expirationTime != null);
    this.expirationTime = this.instantiationTime + (this.expirationTime * 1000);
    this.isValid = !isExpired();
  }

  bool isExpired() {
    var now = new DateTime.now().millisecondsSinceEpoch;
    int expiryTime = this.expirationTime;

    bool retValue = now >= expiryTime;
    return retValue;
  }

  toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expirationTime,
      'provider': provider
    };
  }

  Future<AuthenticationData> reloadAuthenticationData() {
    throw UnimplementedError();
  }
}