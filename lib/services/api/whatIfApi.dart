import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/bloc/forecast/forecast_state.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/preview.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../../constants.dart' as Constants;

class WhatIfApi extends AppApi {
  WhatIfApi() : super() {
    pendingFuture = <Tuple3<StreamSubscription, Future, String>>[];
  }

  Future<dynamic> forecastNewTile(Map<String, Object> externalParams) async {
    List<String> subCalEventIds = [];
    List<SubCalendarEvent> updatedSubCalEvents = [];
    print('externalParams');
    print(externalParams);

    var queryParams = {
      "Name": "Test tile",
      "Count": "1",
      "EndMinute": "59",
      "EndHour": "23",
      "isRestricted": "false",
      "isEveryDay": "False",
      // "DurationDays": "0",
      // "DurationMinute": "0",
      "NewTime": -1,
      "User": {
        "MobileApp": false,
        "TimeZoneOffset": 0,
        "TimeZone": "UTC",
        "IsTimeZoneAdjusted": "false",
        "getTimeSpan": "00:00:00"
      },
      "MobileApp": true,
      "TimeZoneOffset": 0,
      "TimeZone": "UTC",
      "IsTimeZoneAdjusted": "false",
      "getTimeSpan": "00:00:00"
    };

    // Merge externalParams with queryParams
    queryParams.addAll(externalParams);

    try {
      // Perform the initial POST request
      var response = await sendPostRequest('/api/WhatIf/NewTile', queryParams,
          analyze: false);
      var jsonResult = jsonDecode(response.body);

      if (isJsonResponseOk(jsonResult) && isContentInResponse(jsonResult)) {
        Map<String, dynamic> editJson = jsonResult['Content'];
        ForecastResponse forecastResponse = ForecastResponse.fromJson(editJson);

        // Collect sub event IDs
        if (forecastResponse.isViable == true) {
          for (var riskEvent in forecastResponse.riskCalendarEvents!) {
            riskEvent.subEvents!.forEach((e) {
              subCalEventIds.add(e.id!);
            });
          }
        } else {
          for (var conflictEvent in forecastResponse.conflicts!) {
            conflictEvent.subEvents!.forEach((e) {
              subCalEventIds.add(e.id!);
            });
          }
        }

        // Perform concurrent GET requests using the populated subCalEventIds
        final results = await Future.wait(
          subCalEventIds.map((id) async {
            try {
              return await getSubCalEvent(id);
            } catch (e) {
              return null; // Handle the error as needed, maybe return a default value or null
            }
          }),
        );

        // Filter out null values if any
        updatedSubCalEvents = results
            .where((event) => event != null)
            .cast<SubCalendarEvent>()
            .toList();

        return [forecastResponse.isViable, updatedSubCalEvents];
      }

      return ForecastResponse();
    } catch (e) {
      return ForecastResponse();
    }
  }

  // Update SubEvent
  Future<Tuple2<Preview, Preview>?> updateSubEvent(
      EditTilerEvent subEvent) async {
    TilerError error = new TilerError();
    error.message = "Did not update tile";
    var queryParameters = {
      'EventID': subEvent.id,
      'EventName': subEvent.name,
      'Start': subEvent.startTime!.toUtc().millisecondsSinceEpoch.toString(),
      'End': subEvent.endTime!.toUtc().millisecondsSinceEpoch.toString(),
      'CalStart':
          subEvent.calStartTime!.toUtc().millisecondsSinceEpoch.toString(),
      'CalEnd': subEvent.calEndTime!.toUtc().millisecondsSinceEpoch.toString(),
      'Split': subEvent.splitCount.toString(),
      'ThirdPartyEventID': subEvent.thirdPartyId.toString(),
      'ThirdPartyUserID': subEvent.thirdPartyUserId.toString(),
      'ThirdPartyType': subEvent.thirdPartyType.toString(),
      'Notes': subEvent.note.toString(),
    };
    Future<Tuple2<Preview, Preview>?> retValue = sendPostRequest(
            'api/WhatIf/SubeventEdit', queryParameters,
            analyze: false)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> editJson = jsonResult['Content'];
          if (editJson.containsKey('after') && editJson.containsKey('before')) {
            Map<String, dynamic> afterJson = editJson['after'];
            Map<String, dynamic> beforeJson = editJson['before'];
            Preview after = Preview.fromJson(afterJson);
            Preview before = Preview.fromJson(beforeJson);
            return Tuple2<Preview, Preview>(before, after);
          }

          return null;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });

    StreamSubscription? streamSubScription =
        retValue.asStream().listen((event) async {});

    if (pendingFuture != null) {
      pendingFuture!.add(new Tuple3(streamSubScription, retValue,
          Utility.msCurrentTime.toString() + ' || ' + Utility.getUuid));
    }
    return retValue;
  }

  Future<SubCalendarEvent> getSubCalEvent(String id) async {
    String tilerDomain = Constants.tilerDomain;
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {
        'EventID': id,
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, '/api/SubCalendarEvent', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return SubCalendarEvent.fromJson(jsonResult['Content']);
        }
      }
      if (isTilerRequestError(jsonResult)) {
        throw TilerError.fromJson(jsonResult);
      }

      throw TilerError();
    }
    throw TilerError();
  }
}
