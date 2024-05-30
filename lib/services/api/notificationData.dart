class NotificationData {
  final int instantiationTime = (new DateTime.now()).millisecondsSinceEpoch;
  late final String? platform;
  late final String? tilerNotificationId;
  late final String? thirdPartyId;
  bool isValid = false;
  late int expirationTime;

  NotificationData();
  NotificationData.initializedWithRestData(this.tilerNotificationId,
      this.thirdPartyId, this.expirationTime, this.platform) {
    assert(this.tilerNotificationId != null);
    assert(this.thirdPartyId != null);
    assert(this.platform != null);
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
      'notificationId': tilerNotificationId,
      'thirdPartyId': thirdPartyId,
      'expiresIn': expirationTime,
      'platform': platform?.toLowerCase() ?? ""
    };
  }

  Future<NotificationData> reloadNotificationData() {
    throw UnimplementedError();
  }
}
