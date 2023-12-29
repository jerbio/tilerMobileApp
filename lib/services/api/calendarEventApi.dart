import 'package:http/http.dart' as http;
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'dart:convert';

import '../../constants.dart' as Constants;

class CalendarEventApi extends AppApi {
  Future<CalendarEvent> setAsNow(String eventId) async {
    TilerError error = new TilerError();
    error.message = "Did not send request";
    print('setAsNow ' + eventId);
    return sendPostRequest('api/CalendarEvent/Now', {
      'ID': eventId,
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        var calendarEventAsNowJson = jsonResult['Content'];
        return CalendarEvent.fromJson(calendarEventAsNowJson);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.message!);
      } else {
        error.message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> delete(String eventId, String thirdPartyId) async {
    TilerError error = new TilerError();
    print('deleting ' + eventId);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      error.message = "Did not send request";
      String url = Constants.tilerDomain;

      Uri uri = Uri.https(url, 'api/CalendarEvent');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }

      var deleteCalendarEventParameters = {
        'ID': eventId,
        'EventID': eventId,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'ThirdPartyEventID': thirdPartyId,
        'MobileApp': true.toString()
      };
      var response = await http.delete(uri,
          headers: header, body: json.encode(deleteCalendarEventParameters));
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          var deleteCalendarEventJson = jsonResult['Content'];
          return CalendarEvent.fromJson(deleteCalendarEventJson);
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

  Future<CalendarEvent> updateCalEvent(EditCalendarEvent calEvent) async {
    TilerError error = new TilerError();
    error.message = "Did not update tile";
    var queryParameters = {
      'EventID': calEvent.id,
      'EventName': calEvent.name,
      'Start': calEvent.startTime!.millisecondsSinceEpoch.toString(),
      'End': calEvent.endTime!.millisecondsSinceEpoch.toString(),
      'Split': calEvent.splitCount.toString(),
      'ThirdPartyEventID': calEvent.thirdPartyId.toString(),
      'ThirdPartyUserID': calEvent.thirdPartyUserId.toString(),
      'ThirdPartyType': calEvent.thirdPartyType.toString(),
      'Notes': calEvent.note.toString(),
      'IsAutoDeadline': calEvent.isAutoDeadline?.toString(),
      'IsAutoReviseDeadline': calEvent.isAutoReviseDeadline?.toString(),
    };
    if (calEvent.tileDuration != null) {
      queryParameters['Duration'] =
          calEvent.tileDuration!.inMilliseconds.toString();
    }
    return sendPostRequest('api/CalendarEvent/Update', queryParameters)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> tileJson = jsonResult['Content'];
          CalendarEvent retValue = CalendarEvent.fromJson(tileJson);
          return retValue;
        }
      }
      error = getTilerResponseError(jsonResult) ?? error;
      throw error;
    });
  }

  Future<CalendarEvent> complete(String eventId) async {
    TilerError error = new TilerError();
    print('completing ' + eventId);
    error.message = "Did not send request";
    var completeParameters = {
      'ID': eventId,
      'EventID': eventId,
      'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
      'MobileApp': true.toString()
    };

    return sendPostRequest('api/CalendarEvent/Complete', completeParameters)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return CalendarEvent.fromJson(jsonResult['Content']);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.message!);
      } else {
        error.message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> getCalEvent(String id) async {
    String tilerDomain = Constants.tilerDomain;
    // String url = tilerDomain + 'api/SubCalendarEvent';
    // return getAdHocSubEventId(id);
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
      Uri uri = Uri.https(url, 'api/CalendarEvent', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return CalendarEvent.fromJson(jsonResult['Content']);
        }
      }

      throw TilerError();
    }
    throw TilerError();
  }

  Future<List<SubCalendarEvent>> getSubEvents(String id,
      {int? index, int? batchSize}) async {
    String tilerDomain = Constants.tilerDomain;
    // String url = tilerDomain + 'api/SubCalendarEvent';
    // return getAdHocSubEventId(id);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {
        'EventID': id,
        'BatchSize': batchSize,
        'Index': index
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/CalendarEvent/subEvents', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return jsonResult['Content']
              .map<SubCalendarEvent>(
                  (eachSubEvent) => SubCalendarEvent.fromJson(eachSubEvent))
              .toList();
        }
      }

      throw TilerError();
    }
    throw TilerError();
  }

  Future<List<NextTileSuggestion>> getNextTileSuggestion(String id) async {
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
      Uri uri = Uri.https(url, 'api/CalendarEvent/Suggestions', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          List<NextTileSuggestion> retValue = [];
          if (jsonResult['Content'].length > 0) {
            retValue = jsonResult['Content']
                .map<NextTileSuggestion>((e) => NextTileSuggestion.fromJson(e))
                .toList();
          }
          return retValue;
        }
      }
      throw TilerError();
    }
    throw TilerError();
  }
}
