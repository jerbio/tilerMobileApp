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
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../localAuthentication.dart';
import 'package:async/async.dart'; // Import necessary packages.

import '../../constants.dart' as Constants;

/// Authentication failure is not a successful, empty schedule.
class ScheduleAuthenticationRequired extends TilerError {
  ScheduleAuthenticationRequired()
      : super(Message: 'Sign in to load your schedule.', Code: '401');
}

/// The server answered with something other than JSON (an error page from
/// a gateway, or a server still starting).
class ScheduleServerUnavailable extends TilerError {
  ScheduleServerUnavailable({required this.status, this.contentType})
      : super(Message: 'The server is unavailable (HTTP $status).');
  final int status;
  final String? contentType;
}

/// Decodes a schedule response, telling an unavailable server apart from a
/// malformed answer.
Map<String, dynamic> decodeServerJson(Response response,
    {required String operation}) {
  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    decoded = null;
  }
  if (decoded is Map<String, dynamic>) return decoded;
  final contentType = response.headers['content-type']?.split(';').first.trim();
  // Status and content type only: never the body.
  scheduleFlowLog('server_unavailable', fields: {
    'operation': operation,
    'status': response.statusCode,
    'contentType': contentType,
  });
  throw ScheduleServerUnavailable(
      status: response.statusCode, contentType: contentType);
}

abstract class AppApi {
  static const String _analyzePath = 'api/Analysis/Analyze';
  static const int batchCount = 10;
  static const Duration requestTimeout = Duration(seconds: 180);
  static const Duration connectionTimeout = Duration(seconds: 180);

  List<Tuple3<StreamSubscription, Future, String>>? pendingFuture;
  late Authentication authentication;
  late AccessManager accessManager;
  Function? getContextCallBack;
  late RetryHttpClient httpClient;
  ScheduleBloc? _scheduleLifecycle;

  ScheduleBloc? get scheduleLifecycle {
    // A call made as part of a schedule change belongs to that change's bloc.
    final owner = ScheduleBloc.ofCurrentChange;
    if (owner != null) return owner;
    if (_scheduleLifecycle != null) return _scheduleLifecycle;
    final Object? source;
    try {
      source = getContextCallBack?.call();
    } on FlutterError {
      // The State behind the callback is gone (e.g. a closed sheet).
      return null;
    }
    if (source is ScheduleBloc) return _scheduleLifecycle = source;
    if (source is! BuildContext || !source.mounted) return null;
    try {
      return _scheduleLifecycle = source.read<ScheduleBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<T> runScheduleMutation<T>(
      ScheduleChangeKind kind, Future<T> Function() request,
      {String? eventName, List<String> affectedTileIds = const []}) {
    final lifecycle = scheduleLifecycle;
    return lifecycle == null
        ? request()
        : lifecycle.runScheduleChange(request,
            kind: kind, eventName: eventName, affectedTileIds: affectedTileIds);
  }

  AppApi({required this.getContextCallBack}) {
    authentication = new Authentication();
    accessManager = AccessManager();
    httpClient = RetryHttpClient(scheduleLifecycle: () => scheduleLifecycle);
  }

  void dispose() {
    httpClient.close();
  }

  /// Refreshes the HTTP client by closing the old one and creating a new instance.
  /// This helps resolve stale connection issues when the app resumes from background.
  void refreshHttpClient() {
    httpClient.refreshClient();
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
      String subject = 'unidentified';
      try {
        final payload = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(token.split('.')[1])))) as Map;
        subject = (payload['sub'] ??
                payload[
                    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
                payload['nameid'] ??
                subject)
            .toString();
      } catch (_) {}
      scheduleLifecycle
          ?.bindEvaluationAccount('${Constants.tilerDomain}:$subject');

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
                Future.delayed(const Duration(seconds: 600)));

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

            var cancelledOrValue =
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
    print(
        "Longitude and latitude sent: ${position.longitude}, ${position.latitude}");
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
      String? eventName,
      bool analyze = true,
      bool usePutRequest = false}) {
    final kind =
        scheduleMutationKind(usePutRequest ? 'PUT' : 'POST', requestPath);
    Future<Response> request() => _sendPostRequest(requestPath, queryParameters,
        injectLocation: injectLocation,
        analyze: analyze,
        usePutRequest: usePutRequest);
    return kind == null
        ? request()
        : runScheduleMutation(kind, request,
            eventName: eventName ??
                (queryParameters['EventName'] is String
                    ? queryParameters['EventName'] as String
                    : null),
            affectedTileIds: [
                (queryParameters['EventID'] ??
                        (requestPath.toLowerCase().contains('calendarevent')
                            ? queryParameters['ID']
                            : null) ??
                        '')
                    .toString()
              ]);
  }

  Future<Response> _sendPostRequest(String requestPath, Map queryParameters,
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

            try {
              Response response;
              if (usePutRequest) {
                response = await httpClient
                    .put(uri,
                        headers: header, body: jsonEncode(injectedParameters))
                    .timeout(
                  requestTimeout,
                  onTimeout: () {
                    throw TilerError(
                        cause: TimeoutException(
                            'Request timed out', requestTimeout),
                        Message:
                            'Request timed out after ${requestTimeout.inSeconds} seconds');
                  },
                );
                print("Concluded Sending PUT REQUEST " +
                    requestPath +
                    "\t Code: " +
                    response.statusCode.toString());
              } else {
                response = await httpClient
                    .post(uri,
                        headers: header, body: jsonEncode(injectedParameters))
                    .timeout(
                  requestTimeout,
                  onTimeout: () {
                    throw TilerError(
                        cause: TimeoutException(
                            'Request timed out', requestTimeout),
                        Message:
                            'Request timed out after ${requestTimeout.inSeconds} seconds');
                  },
                );
                print("Concluded Sending POST REQUEST " +
                    requestPath +
                    "\t Code: " +
                    response.statusCode.toString());
              }

              // Only analyze if request was successful
              if (analyze && response.statusCode == HttpStatus.ok) {
                // Run analyze in background, don't wait for it
                analyzeSchedule(injectLocation: injectLocation)
                    .catchError((error) {
                  print("Background analyze failed: $error");
                });
              }

              return response;
            } catch (e) {
              print("Error with " +
                  (usePutRequest ? "PUT" : "POST") +
                  " REQUEST " +
                  requestPath +
                  ": $e");
              if (e is TilerError) {
                rethrow;
              }
              throw TilerError(
                  Message: 'Network error: ${e.toString()}', cause: e);
            }
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
      if (e is TilerError) rethrow;
      throw TilerError(
          Message: LocalizationService.instance.translations.errorOccurred,
          cause: e);
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
    try {
      var header = this.getHeaders();
      if (header != null) {
        String tilerDomain = Constants.tilerDomain;
        String analyzeUrl = tilerDomain;
        Uri analyzeUri = Uri.https(analyzeUrl, analyzePath);
        Map<String, dynamic> analyzeParameters = await injectRequestParams({},
            includeLocationParams: injectLocation);
        await httpClient
            .post(analyzeUri,
                headers: header, body: jsonEncode(analyzeParameters))
            .timeout(
          Duration(seconds: 20),
          onTimeout: () {
            print("Analyze schedule timed out");
            return http.Response('{}', 408);
          },
        );
      }
    } catch (e) {
      print("Error in analyzeSchedule: $e");
      // Don't throw - this is a background operation
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
