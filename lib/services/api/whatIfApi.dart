import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Preview;
import 'package:http/http.dart' as http;
import 'package:tiler_app/bloc/forecast/forecast_state.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/prediction.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../../constants.dart' as Constants;

class WhatIfApi extends AppApi {
  WhatIfApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack) {
    pendingFuture = <Tuple3<StreamSubscription, Future, String>>[];
  }

  Future<ForecastResponse> forecastNewTile(
      Map<String, Object> externalParams) async {
    var queryParams = {};
    queryParams.addAll(externalParams);

    try {
      // Perform the initial POST request
      var response = await sendPostRequest('/api/WhatIf/NewTile', queryParams,
          analyze: false);
      var jsonResult = jsonDecode(response.body);

      if (isJsonResponseOk(jsonResult) && isContentInResponse(jsonResult)) {
        Map<String, dynamic> editJson = jsonResult['Content'];
        ForecastResponse forecastResponse = ForecastResponse.fromJson(editJson);

        return forecastResponse;
      }

      return ForecastResponse();
    } catch (e) {
      throw TilerError(Message: "Failed to get preview");
    }
  }

  // Update SubEvent
  Future<Tuple2<Preview, Preview>?> updateSubEvent(
      EditTilerEvent subEvent) async {
    TilerError error = new TilerError();
    error.Message = "Did not update tile";
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
        throw TilerError(Message: 'Issues with authentication');
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
