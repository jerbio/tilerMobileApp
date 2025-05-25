import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../localAuthentication.dart';
import 'package:async/async.dart'; // Import necessary packages.

import '../../constants.dart' as Constants;

abstract class AppApi {
  static const String _analyzePath = 'api/Analysis/Analyze';
  static const int batchCount = 10;

  List<Tuple3<StreamSubscription, Future, String>>? pendingFuture;
  late Authentication authentication;
  late AccessManager accessManager;
  Function? getContextCallBack;
  AppApi({required this.getContextCallBack}) {
    authentication = new Authentication();
    accessManager = AccessManager();
  }

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

  ///Function checks if the cached credential is valid and if not it reloads it
  checkAndReplaceCredentialCache() async {
    if (this.authentication.cachedCredentials == null ||
        !this.authentication.cachedCredentials!.isValid) {
      await this.authentication.reLoadCredentialsCache();
    }
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
    Map<String, dynamic> requestParams = Map.from(jsonMap);
    Position position = Utility.getDefaultPosition();
    bool isLocationVerified = false;
    LocationProfile locationAccessResult = LocationProfile.empty();
    if (includeLocationParams) {
      try {
        if (this.getContextCallBack != null) {
          BuildContext? buildContext = this.getContextCallBack!();
          if (buildContext != null && buildContext.mounted) {
            var awaitableUiChanges = CancelableOperation.fromFuture(
                Future.delayed(const Duration(seconds: 50)));

            BlocProvider.of<DeviceSettingBloc>(buildContext).add(
                GetLocationProfileDeviceSettingEvent(
                    id: 'injectRequestParams-' +
                        Utility.msCurrentTime.toString() +
                        '-' +
                        Utility.getUuid,
                    showLocationPermissionWidget: true,
                    context: buildContext,
                    callBacks: <Function>[
                  (_) {
                    awaitableUiChanges.cancel();
                  }
                ]));

            await awaitableUiChanges.valueOrCancellation();
            if (buildContext.mounted) {
              var deviceSettingState =
                  BlocProvider.of<DeviceSettingBloc>(buildContext).state;
              if (deviceSettingState is DeviceSettingLoaded) {
                if (deviceSettingState.sessionProfile?.locationProfile !=
                    null) {
                  locationAccessResult =
                      deviceSettingState.sessionProfile!.locationProfile!;
                }
              } else {
                print("DeviceSetting not Loaded");
              }
            } else {
              locationAccessResult = await accessManager.locationAccess();
            }
          }
        }
      } catch (e) {
        debugPrint("Error in injectRequestParams: $e");
        locationAccessResult = await accessManager.locationAccess();
      }

      if (locationAccessResult.permission != null) {
        if (locationAccessResult.permission!.isGranted == true &&
            locationAccessResult.position != null) {
          isLocationVerified = true;
          position = locationAccessResult.position!;
        }
      }
      if (position == Utility.getDefaultPosition()) {
        print("location not set");
      } else {
        print("location is set");
      }
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
      {bool injectLocation = true,
      bool analyze = true,
      bool usePutRequest = false}) async {
    try {
      Utility.debugPrint("Sending POST REQUEST " + requestPath);
      if ((await this.authentication.isUserAuthenticated()).item1) {
        await checkAndReplaceCredentialCache();
        if (this.authentication.cachedCredentials != null) {
          Map<String, dynamic> requestParams = Map.from(queryParameters);
          if (!queryParameters.containsKey('UserName')) {
            String? username = '';
            requestParams['UserName'] = username;
          }
          if (!queryParameters.containsKey('MobileApp')) {
            requestParams['MobileApp'] = true.toString();
          }
          String url = Constants.tilerDomain;
          Map<String, dynamic> injectedParameters = await injectRequestParams(
              requestParams,
              includeLocationParams: injectLocation);
          var header = this.getHeaders();
          if (header != null) {
            Uri uri = Uri.https(url, requestPath);
            print("Called POST REQUEST " + requestPath + " domain:" + url);
            if (usePutRequest) {
              return http
                  .put(uri,
                      headers: header, body: jsonEncode(injectedParameters))
                  .then((value) async {
                print("Concluded Sending PUT REQUEST " +
                    requestPath +
                    "\t Code: " +
                    value.statusCode.toString());

                if (analyze) {
                  analyzeSchedule(injectLocation: injectLocation);
                }
                return value;
              }).catchError((onError) {
                print("Issues with PUT REQUEST " + requestPath);
                return onError;
              });
            }
            return http
                .post(uri,
                    headers: header, body: jsonEncode(injectedParameters))
                .then((value) async {
              print("Concluded Sending POST REQUEST " +
                  requestPath +
                  "\t Code: " +
                  value.statusCode.toString());
              if (analyze) {
                analyzeSchedule(injectLocation: injectLocation);
              }
              return value;
            }).catchError((onError) {
              print("Issues with POST REQUEST " + requestPath);
              return onError;
            });
          }
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
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

  Future analyzeSchedule({bool injectLocation = false}) async {
    var header = this.getHeaders();
    if (header != null) {
      String tilerDomain = Constants.tilerDomain;
      String analyzeUrl = tilerDomain;
      Uri analyzeUri = Uri.https(analyzeUrl, analyzePath);
      Map<String, dynamic> analyzeParameters =
      await injectRequestParams({}, includeLocationParams: injectLocation);
      await http.post(analyzeUri,
          headers: header, body: jsonEncode(analyzeParameters));
    }
  }

  void HandleHttpStatusFailure(Response response,
      {String? serviceName, String? message}) {
    if (response.statusCode != HttpStatus.ok) {
      switch (response.statusCode) {
        case HttpStatus.notFound:
          throw TilerError(
              Message: serviceName ?? '' + (message ?? ' Not Found'));

        default:
          throw TilerError(Message: serviceName ?? '' + ' Is Having issues');
      }
    }
  }
}
