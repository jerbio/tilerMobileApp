import 'dart:convert';
import 'dart:math';

import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart' as Constants;

class SubCalendarEventApi extends AppApi {
  SubCalendarEventApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<SubCalendarEvent> getSubEvent(String id,
      {String calendarSource = "", String thirdPartyUserId = ""}) async {
    // return getAdHocSubEventId(id);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {
        'EventID': id,
        "ThirdPartyType": calendarSource,
        "ThirdPartyUserID": thirdPartyUserId
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/SubCalendarEvent', updatedParams);
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

      throw TilerError();
    }
    throw TilerError();
  }

  Future<List<SubCalendarEvent>> getSubEvents(Iterable<String> ids,
      {int batchSize = AppApi.batchCount}) async {
    if (batchSize < 1) {
      batchSize = AppApi.batchCount;
    }
    // return getAdHocSubEventId(id);
    if (ids.length <= batchSize) {
      if ((await this.authentication.isUserAuthenticated()).item1) {
        await checkAndReplaceCredentialCache();
        String tilerDomain = Constants.tilerDomain;
        String url = tilerDomain;
        final queryParameters = {
          'EventID': ids.take(batchSize).join(Constants.requestDelimiter),
        };
        Map<String, dynamic> updatedParams = await injectRequestParams(
            queryParameters,
            includeLocationParams: false);
        Uri uri = Uri.https(url, 'api/SubCalendarEvent', updatedParams);
        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (jsonResult['Content'] is List) {
              return jsonResult['Content']
                  .map<SubCalendarEvent>((eachSubEventJson) =>
                      SubCalendarEvent.fromJson(eachSubEventJson))
                  .toList();
            }
            return [SubCalendarEvent.fromJson(jsonResult['Content'])];
          }
        }

        throw TilerError();
      }
      throw TilerError();
    }
    List<Future<List<SubCalendarEvent>>> waitingFutures =
        <Future<List<SubCalendarEvent>>>[];
    for (int i = 0; i < ids.length;) {
      int skipCount = i;
      List<String> fetchIds = ids.skip(skipCount).take(batchSize).toList();
      Future<List<SubCalendarEvent>> futureSubEvents =
          getSubEvents(fetchIds, batchSize: batchSize);
      waitingFutures.add(futureSubEvents);
      i += batchSize;
    }
    var futureResult = await Future.wait(waitingFutures);

    List<SubCalendarEvent> retValue = <SubCalendarEvent>[];
    for (var listOfSubEventFuture in futureResult) {
      retValue.addAll(listOfSubEventFuture);
    }

    return retValue;
  }

  Future<SubCalendarEvent> pauseTile(String id) async {
    TilerError error = new TilerError();
    error.message = "Failed to pause tile";
    return sendPostRequest('api/Schedule/Event/Pause', {'EventID': id},
            analyze: false)
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
    error.message = "Failed to resume tile";
    return sendPostRequest('api/Schedule/Event/Resume', {
      'EventID': subEvent.id,
      'ThirdPartyType': subEvent.thirdpartyType?.name ?? ""
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
    error.message = "Did not move up task";
    return sendPostRequest('api/Schedule/Event/Now', {
      'EventID': subEvent.id,
      'ThirdPartyType': subEvent.thirdpartyType?.name ?? ""
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

  Future<SubCalendarEvent> updateSubEvent(EditTilerEvent subEvent) async {
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
    return sendPostRequest('api/SubCalendarEvent/Update', queryParameters)
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

  Future<SubCalendarEvent> complete(SubCalendarEvent subEvent) async {
    TilerError error = new TilerError();
    error.message = "Did not send complete request";
    print(subEvent);
    print(subEvent.id);
    return sendPostRequest('api/Schedule/Event/Complete', {
      'EventID': subEvent.id,
      'ThirdPartyType':
          subEvent.thirdpartyType?.name.toString().toLowerCase() ?? "",
      'ThirdPartyUserID': subEvent.thirdPartyUserId,
      'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
      'ThirdPartyEventID': subEvent.thirdpartyId,
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

  Future completeTiles(String id, String type, String userId) async {
    TilerError error = new TilerError();
    error.message = "Did not send complete request";
    return sendPostRequest('api/Schedule/Events/Complete', {
      'EventID': id,
      'ThirdPartyType': type,
      'ThirdPartyUserID': userId,
      'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      print("jsonResult:$jsonResult");
      if (isJsonResponseOk(jsonResult)) {
        return true;
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<CalendarEvent?> delete(String eventId, String? thirdPartyEventID,
      String? thirdPartyUserId, String? thirdPartyType) async {
    TilerError error = new TilerError();
    print('deleting ' + eventId);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      error.message = "Did not send request";
      String url = Constants.tilerDomain;

      Uri uri = Uri.https(url, 'api/Schedule/Event');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var deleteSubEventParameters = {
        'ID': eventId,
        'EventID': eventId,
        'ThirdPartyUserID': thirdPartyUserId,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'ThirdPartyEventID': thirdPartyEventID,
        'ThirdPartyType': thirdPartyType,
        'MobileApp': true.toString()
      };

      var injectedDeleteSubEventParameters =
          await injectRequestParams(deleteSubEventParameters);
      var response = await http.delete(uri,
          headers: header, body: json.encode(injectedDeleteSubEventParameters));
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          var deleteCalendarEventJson = jsonResult['Content'];
          if (!deleteCalendarEventJson is String) {
            return CalendarEvent.fromJson(deleteCalendarEventJson);
          }
        } else {
          if (isTilerRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
          } else {
            error.message = "Issues with reaching TIler servers";
          }
        }
      }
    }
    throw error;
  }

  Future procrastinate(Duration duration, String tileId) async {
    TilerError error = new TilerError();
    error.message = "Did not procrastinate tile";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final procrastinateParameters = {
          'UserName': username,
          'DurationInMs': duration.inMilliseconds.toString(),
          'EventID': tileId
        };
        Map injectedParameters = await injectRequestParams(
            procrastinateParameters,
            includeLocationParams: true);

        return sendPostRequest(
                'api/Schedule/Event/Procrastinate', injectedParameters)
            .then((response) {
          var jsonResult = jsonDecode(response.body);
          error.message = "Issues with reaching Tiler servers";
          if (isJsonResponseOk(jsonResult)) {
            return;
          }
          if (isTilerRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
            throw FormatException(error.message!);
          } else {
            error.message = "Issues with reaching Tiler servers";
          }
        });
      }
    }
    throw error;
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

    int timeSpanDifference = retValue.end! - retValue.start!;
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

    retValue.start = revisedStart.toInt();
    retValue.end = revisedEnd.toInt();

    Future<SubCalendarEvent> retFuture =
        new Future.delayed(const Duration(seconds: 5), () => retValue);
    return retFuture;
  }
}
