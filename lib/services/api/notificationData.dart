class NotificationData {
  final int instantiationTime = (new DateTime.now()).millisecondsSinceEpoch;
  late final String? channelType;
  late final String? tilerNotificationId;
  late final String? thirdPartyId;
  bool isValid = false;
  int? expirationTime = 0;
  String? _notificationIdKey = 'notificationId';
  String? _thirdPartyIdKey = 'thirdPartyId';
  String? _expiresInKey = 'expiresIn';
  String? _channelTypeKey = 'channelType';
  NotificationData();
  NotificationData.initializedWithRestData(this.tilerNotificationId,
      this.channelType, this.thirdPartyId, this.expirationTime) {
    assert(this.tilerNotificationId != null);
    assert(this.channelType != null);
    this.isValid = true;
    this.expirationTime = 999999999999999;
  }

  NotificationData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_notificationIdKey)) {
      tilerNotificationId = json[_notificationIdKey];
    }
    if (json.containsKey(_thirdPartyIdKey)) {
      thirdPartyId = json[_thirdPartyIdKey];
    }
    if (json.containsKey(_expiresInKey)) {
      this.expirationTime = json[_expiresInKey];
    }
    if (json.containsKey(_channelTypeKey)) {
      channelType = json[_channelTypeKey];
    }
    assert(this.tilerNotificationId != null);
    assert(this.channelType != null);
    this.isValid = true;
    this.expirationTime = 999999999999999;
  }

  NotificationData.noCredentials() {
    this.expirationTime = 0;
    this.isValid = false;
  }

  bool isExpired() {
    var now = new DateTime.now().millisecondsSinceEpoch;
    if (this.expirationTime != null) {
      int expiryTime = this.expirationTime!;
      bool retValue = now >= expiryTime;
      return retValue;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': tilerNotificationId,
      'thirdPartyId': thirdPartyId,
      'expiresIn': expirationTime,
      'channelType': channelType?.toLowerCase() ?? ""
    };
  }

  Future<NotificationData> reloadNotificationData() {
    throw UnimplementedError();
  }
}
