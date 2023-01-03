import 'dart:convert';
import 'dart:math';

import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants.dart' as Constants;

class SubCalendarEventApi extends AppApi {
  Future<SubCalendarEvent> getSubEvent(String id) {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain + 'api/SubCalendarEvent';
    return getAdHocSubEventId(id);
  }

  Future<SubCalendarEvent> pauseTile(String id) async {
    TilerError error = new TilerError();
    error.Message = "Failed to pause tile";
    return sendPostRequest('api/Schedule/Event/Pause', {'EventID': id})
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> tileJson = jsonResult['Content'];
          SubCalendarEvent retValue = SubCalendarEvent.fromJson(tileJson);
          return retValue;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<SubCalendarEvent> resumeTile(SubCalendarEvent subEvent) async {
    TilerError error = new TilerError();
    error.Message = "Failed to resume tile";
    return sendPostRequest('api/Schedule/Event/Resume', {
      'EventID': subEvent.id,
      'ThirdPartyType': subEvent.thirdpartyType
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> tileJson = jsonResult['Content'];
          SubCalendarEvent retValue = SubCalendarEvent.fromJson(tileJson);
          return retValue;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<SubCalendarEvent> setAsNow(SubCalendarEvent subEvent) async {
    TilerError error = new TilerError();
    error.Message = "Did not move up task";
    return sendPostRequest('api/Schedule/Event/Now', {
      'EventID': subEvent.id,
      'ThirdPartyType': subEvent.thirdpartyType
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> tileJson = jsonResult['Content'];
          SubCalendarEvent retValue = SubCalendarEvent.fromJson(tileJson);
          return retValue;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<SubCalendarEvent> complete(SubCalendarEvent subEvent) async {
    TilerError error = new TilerError();
    error.Message = "Did not send complete request";
    print(subEvent);
    print(subEvent.id);
    return sendPostRequest('api/Schedule/Event/Complete', {
      'EventID': subEvent.id,
      'ThirdPartyType': subEvent.thirdpartyType
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> tileJson = jsonResult['Content'];
          SubCalendarEvent retValue = SubCalendarEvent.fromJson(tileJson);
          return retValue;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<SubCalendarEvent> getAdHocSubEventId(String id) {
//     {
//     "Error": {
//         "code": "0",
//         "Message": ""
//     },
//     "Content": {
//         "id": "0a78ae5d-2858-4842-94b5-cb60edd1d65e_7_07d5f9b3-a71a-4eb9-bd33-096c4ff51b00_22bf7ae0-1299-4de0-b49d-8897edcb69ef",
//         "start": 1615306440000,
//         "end": 1615313640000,
//         "name": "Morning 203 plans",
//         "address": "1240 hover st #200, longmont, co 80501, united states",
//         "addressDescription": "1240 hover st #200, longmont, co 80501, united states",
//         "searchdDescription": "gym",
//         "thirdpartyType": "tiler",
//         "colorOpacity": 1.0,
//         "colorRed": 38,
//         "colorGreen": 255,
//         "colorBlue": 128,
//         "isComplete": true,
//         "isRecurring": true
//     }
// }

    String subEventString =
        "{\"Error\":{\"code\":\"0\",\"Message\":\"\"},\"Content\":{\"id\":\"0a78ae5d-2858-4842-94b5-cb60edd1d65e_7_07d5f9b3-a71a-4eb9-bd33-096c4ff51b00_22bf7ae0-1299-4de0-b49d-8897edcb69ef\",\"start\":1615306440000,\"end\":1615313640000,\"name\":\"Morning 203 plans\",\"travelTimeBefore\":600000,\"travelTimeAfter\":0,\"address\":\"1240 hover st #200, longmont, co 80501, united states\",\"addressDescription\":\"1240 hover st #200, longmont, co 80501, united states\",\"searchdDescription\":\"gym\",\"rangeStart\":1615118400000,\"rangeEnd\":1615118400000,\"thirdpartyType\":\"tiler\",\"colorOpacity\":1,\"colorRed\":38,\"colorGreen\":255,\"colorBlue\":128,\"isPaused\":false,\"isComplete\":true,\"isRecurring\":true}}";

    Map<String, dynamic> subEventMap = jsonDecode(subEventString);
    subEventMap['Content']['id'] = id;

    SubCalendarEvent retValue =
        SubCalendarEvent.fromJson(subEventMap['Content']);
    retValue.colorBlue = Random().nextInt(255);
    retValue.colorGreen = Random().nextInt(255);
    retValue.colorRed = Random().nextInt(255);

    double timeSpanDifference = retValue.end! - retValue.start!;
    int currentTime = Utility.msCurrentTime;

    // currentTile
    int revisedStart = currentTime - Utility.oneHour.inMilliseconds;
    int revisedEnd = currentTime + Utility.fifteenMin.inMilliseconds;

    // nextTile
    // int revisedStart = currentTime + Utility.fifteenMin.inMilliseconds;
    // int revisedEnd = currentTime + Utility.oneHour.inMilliseconds;

    // elapsedTile
    // int revisedStart = currentTime - Utility.oneHour.inMilliseconds;
    // int revisedEnd = currentTime - Utility.fifteenMin.inMilliseconds;

    retValue.start = revisedStart.toDouble();
    retValue.end = revisedEnd.toDouble();

    Future<SubCalendarEvent> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
    return retFuture;
  }
}
