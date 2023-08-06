import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tiler_app/services/api/authenticationData.dart';

class SecureStorageManager {
  static final _storage = new FlutterSecureStorage();
  final _accessControlKey = 'access';
  final _locationAccessKey = 'location';
  final _credentialKey = 'credentials';

  Future<Map<String, dynamic>?> getAccessObject() async {
    Map<String, dynamic>? accessDataObj;
    print("read access , getAccessObject");
    bool hasAccess = await _storage.containsKey(key: _accessControlKey);
    print("read access flag , $hasAccess");
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
    print("read access , getAccessObject $accessDataString");
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
    print("read access , readCredentials $retValue");
    return retValue;
  }
}
