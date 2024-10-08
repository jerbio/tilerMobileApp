import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/notificationData.dart';

class SecureStorageManager {
  static final _storage = new FlutterSecureStorage();
  final _accessControlKey = 'access';
  final _locationAccessKey = 'location';
  final _credentialKey = 'credentials';
  final _notificationKey = 'notification';

  Future<Map<String, dynamic>?> getAccessObject() async {
    Map<String, dynamic>? accessDataObj;

    bool hasAccess = await _storage.containsKey(key: _accessControlKey);
    if (!hasAccess) {
      return null;
    }
    try {
      if (await _storage.read(key: _accessControlKey) == null) {
        return null;
      }
    } on PlatformException catch (e) {
      print(e);
      return null;
    }

    String? accessDataString = await _storage.read(key: _accessControlKey);

    if (accessDataString != null) {
      accessDataObj = jsonDecode(accessDataString);
    }

    return accessDataObj;
  }

  Future writeAccessObject(Map<String, dynamic> accessDataObj) async {
    String encodedAccessObj = jsonEncode(accessDataObj);
    await _storage.write(key: _accessControlKey, value: encodedAccessObj);
  }

  Future<Map<String, dynamic>?> getLocationAccess() async {
    await readCredentials();
    Map<String, dynamic>? accessData = await getAccessObject();
    if (accessData != null) {
      if (accessData.containsKey(_locationAccessKey)) {
        return jsonDecode(accessData[_locationAccessKey]);
      }
    }
    return null;
  }

  Future writeLocationAccess(Map<String, dynamic> locationData) async {
    Map<String, dynamic>? accessDataObj = await getAccessObject();
    String encodedLocationData = jsonEncode(locationData);
    if (accessDataObj == null) {
      accessDataObj = {};
    }
    accessDataObj[_locationAccessKey] = encodedLocationData;
    await writeAccessObject(accessDataObj);
  }

  Future deleteAllStorageData() async {
    await _storage.delete(key: _accessControlKey);
    await _storage.delete(key: _locationAccessKey);
    await _storage.delete(key: _credentialKey);
    await _storage.delete(key: _notificationKey);
  }

  Future saveCredentials(AuthenticationData credentials) async {
    String credentialJsonString = jsonEncode(credentials.toJson());
    await _storage.write(key: _credentialKey, value: credentialJsonString);
  }

  Future deleteCredentials() async {
    await _storage.delete(key: _credentialKey);
  }

  Future<String?> readCredentials() async {
    String? retValue = await _storage.read(key: _credentialKey);
    return retValue;
  }

  Future saveNotificationData(NotificationData notificationData) async {
    String notificationJsonString = jsonEncode(notificationData.toJson());
    await _storage.write(key: _notificationKey, value: notificationJsonString);
  }

  Future deleteNotificationData() async {
    await _storage.delete(key: _notificationKey);
  }

  Future<NotificationData?> readNotificationData() async {
    String? retValueJsonString = await _storage.read(key: _notificationKey);
    NotificationData retValue = NotificationData.noCredentials();
    if (retValueJsonString != null && retValueJsonString.isNotEmpty) {
      Map<String, dynamic> jsonData = jsonDecode(retValueJsonString);
      try {
        retValue = NotificationData.fromJson(jsonData);
      } catch (e) {}
    }
    return retValue;
  }
}
