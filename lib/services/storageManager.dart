import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  final _storage = new FlutterSecureStorage();
  final _accessControlKey = 'access';
  final _locationAccessKey = 'location';

  Future<Map<String, dynamic>?> getAccessObject() async {
    Map<String, dynamic>? accessDataObj;
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
    String? accessData = await _storage.read(key: _accessControlKey);
    if (accessData != null) {
      Map<String, dynamic> retValue = jsonDecode(accessData);
      if (retValue.containsKey(_locationAccessKey)) {
        return jsonDecode(retValue[_locationAccessKey]);
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
  }
}
