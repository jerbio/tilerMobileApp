import 'dart:convert';
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/util.dart';
import '../localAuthentication.dart';

import '../../constants.dart' as Constants;

abstract class AppApi {
  static const String _analyzePath = 'api/Analysis/Analyze';
  static const int batchCount = 10;
  Authentication authentication = new Authentication();
  AccessManager accessManager = AccessManager();
  bool isJsonResponseOk(Map jsonResult) {
    bool retValue = (jsonResult.containsKey('Error') &&
            jsonResult['Error'].containsKey('Code')) &&
        jsonResult['Error']['Code'] == '0';

    return retValue;
  }

  bool isContentInResponse(Map jsonResult) {
    bool retValue =
        jsonResult.containsKey('Content') && jsonResult['Content'] != null;
    return retValue;
  }

  bool isTilerRequestError(Map jsonResult) {
    bool retValue = jsonResult.containsKey('Error') &&
        jsonResult['Error'].containsKey('Code') &&
        jsonResult['Error']['Code'] != '0';
    return retValue;
  }

  static String get analyzePath {
    return _analyzePath;
  }

  String errorMessage(Map jsonResult) {
    bool isError = isTilerRequestError(jsonResult);
    if (isError) {
      if (jsonResult['Error'].containsKey('Message') &&
          jsonResult['Error']['Message'] != null &&
          jsonResult['Error']['Message'].isNotEmpty) {
        return Uri.decodeFull(jsonResult['Error']['Message'])
            .replaceAll('<br> ', '\n\n')
            .replaceAll('<br>', '\n');
      }
      return 'Error: ' + Uri.decodeFull(jsonResult['Error']['Code']);
    }
    return 'Unknown Tiler Error';
  }

  getHeaders() {
    if (authentication.cachedCredentials != null &&
        !authentication.cachedCredentials!.isExpired()) {
      var cachedCredentials = authentication.cachedCredentials!;
      String token = cachedCredentials.accessToken!;

      var header = {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ' + token,
      };

      return header;
    }

    return null;
  }

  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    Utility.isDebugSet = false;
    Map<String, dynamic> requestParams = Map.from(jsonMap);
    Position position = Utility.getDefaultPosition();
    bool isLocationVerified = false;
    if (includeLocationParams) {
      var locationAccessResult = await accessManager.locationAccess();
      isLocationVerified = locationAccessResult.item2;
      position = locationAccessResult.item1;
    }
    if (!requestParams.containsKey('TimeZoneOffset')) {
      requestParams['TimeZoneOffset'] = Utility.getTimeZoneOffset().toString();
    }
    if (!requestParams.containsKey('TimeZone')) {
      requestParams['TimeZone'] = await FlutterTimezone.getLocalTimezone();
    }
    if (!requestParams.containsKey('MobileApp')) {
      requestParams['MobileApp'] = true.toString();
    }
    if (!requestParams.containsKey('UserLongitude')) {
      requestParams['UserLongitude'] = position.longitude.toString();
    }
    if (!requestParams.containsKey('UserLatitude')) {
      requestParams['UserLatitude'] = position.latitude.toString();
    }
    if (!requestParams.containsKey('UserLocationVerified')) {
      requestParams['UserLocationVerified'] = (isLocationVerified).toString();
    }
    return requestParams;
  }

  Future<Response> sendPostRequest(String requestPath, Map queryParameters,
      {bool injectLocation = true, bool analyze = true}) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        Map<String, dynamic> requestParams = Map.from(queryParameters);
        if (!queryParameters.containsKey('UserName')) {
          String? username = '';
          requestParams['UserName'] = username;
        }
        if (!queryParameters.containsKey('MobileApp')) {
          requestParams['MobileApp'] = true.toString();
        }

        Map<String, dynamic> injectedParameters = await injectRequestParams(
            requestParams,
            includeLocationParams: injectLocation);
        var header = this.getHeaders();
        if (header != null) {
          Uri uri = Uri.https(url, requestPath);

          return http
              .post(uri, headers: header, body: jsonEncode(injectedParameters))
              .then((value) async {
            if (analyze) {
              String tilerDomain = Constants.tilerDomain;
              String analyzeUrl = tilerDomain;
              Uri analyzeUri = Uri.https(analyzeUrl, analyzePath);
              Map<String, dynamic> analyzeParameters =
                  await injectRequestParams({},
                      includeLocationParams: injectLocation);
              http.post(analyzeUri,
                  headers: header, body: jsonEncode(analyzeParameters));
            }
            return value;
          });
        }
        throw TilerError();
      }
      throw TilerError();
    }
    throw TilerError();
  }

  TilerError? getTilerResponseError(Map<String, dynamic> responseBody) {
    TilerError? error;
    if (isTilerRequestError(responseBody)) {
      var errorJson = responseBody['Error'];
      error = TilerError.fromJson(errorJson);
    }

    return error;
  }
}
