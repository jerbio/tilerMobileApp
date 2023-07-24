import 'dart:async';
import 'dart:convert';

import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/preview.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class WhatIfApi extends AppApi {
  WhatIfApi() : super() {
    pendingFuture = <Tuple3<StreamSubscription, Future, String>>[];
  }
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
}
