import 'dart:convert';
import 'dart:io';
// import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/util.dart';
import '../localAuthentication.dart';

import '../../constants.dart' as Constants;

abstract class AppApi {
  static const String _analyzePath = 'api/Analysis/Analyze';
  Authentication authentication = new Authentication();
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

  Future<Map<String, String?>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    Map<String, String?> requestParams = Map.from(jsonMap);
    Position position = Utility.getDefaultPosition();
    bool isLocationVerified = false;
    if (includeLocationParams) {
      try {
        Position initialPosition = position;
        isLocationVerified = true;
        position =
            await Utility.determineDevicePosition().catchError((onError) {
          isLocationVerified = false;
          print('Tiler app: failed to pull device location.');
          print(onError);
          return initialPosition;
        });
      } catch (e) {
        print('Tiler app error in getting location');
        print(e);
      }
    }
    requestParams['TimeZoneOffset'] = Utility.getTimeZoneOffset().toString();
    requestParams['MobileApp'] = true.toString();
    requestParams['UserLongitude'] = position.longitude.toString();
    requestParams['UserLatitude'] = position.latitude.toString();
    requestParams['UserLocationVerified'] = (isLocationVerified).toString();
    return requestParams;
  }

  getHeaders() {
    if (authentication.cachedCredentials != null &&
        !authentication.cachedCredentials!.isExpired()) {
      var cachedCredentials = authentication.cachedCredentials!;
      String token = cachedCredentials.accessToken;
      var header = {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ' + token,
      };

      return header;
    }

    return null;
  }

  Future<Response> sendPostRequest(String requestPath, Map queryParameters,
      {bool injectLocation = true, bool analyze = true}) async {
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        Map<String, String?> requestParams = Map.from(queryParameters);
        if (!queryParameters.containsKey('UserName')) {
          String? username = this.authentication.cachedCredentials!.username;
          requestParams['UserName'] = username;
        }
        if (!queryParameters.containsKey('MobileApp')) {
          requestParams['MobileApp'] = true.toString();
        }

        Map<String, String?> injectedParameters = await injectRequestParams(
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
              Map<String, String?> analyzeParameters =
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
