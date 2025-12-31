import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'dart:convert';

import '../../constants.dart' as Constants;

class CalendarEventApi extends AppApi {
  CalendarEventApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<CalendarEvent> setAsNow(String eventId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    print('setAsNow ' + eventId);
    return sendPostRequest('api/CalendarEvent/Now', {
      'ID': eventId,
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        var calendarEventAsNowJson = jsonResult['Content'];
        return CalendarEvent.fromJson(calendarEventAsNowJson);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.Message!);
      } else {
        error.Message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> delete(String eventId, String thirdPartyId) async {
    TilerError error = new TilerError();
    print('deleting ' + eventId);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      error.Message = "Did not send request";
      String url = Constants.tilerDomain;

      Uri uri = Uri.https(url, 'api/CalendarEvent');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(Message: 'Issues with authentication');
      }

      var deleteCalendarEventParameters = {
        'ID': eventId,
        'EventID': eventId,
        'TimeZoneOffset':
            Utility.currentTime().timeZoneOffset.inHours.toString(),
        'ThirdPartyEventID': thirdPartyId,
        'MobileApp': true.toString()
      };
      var response = await httpClient
          .delete(uri,
              headers: header, body: json.encode(deleteCalendarEventParameters))
          .timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          var deleteCalendarEventJson = jsonResult['Content'];
          return CalendarEvent.fromJson(deleteCalendarEventJson);
        } else {
          if (isTilerRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
          } else {
            error.Message = "Issues with reaching TIler servers";
          }
        }
      }
    }
    throw error;
  }

  Future<CalendarEvent> updateCalEvent(EditCalendarEvent calEvent,
      {bool clearLocation = false}) async {
    TilerError error = new TilerError();
    error.Message = "Did not update tile";
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
      'CalAddress': calEvent.address?.toString(),
      'CalAddressDescription': calEvent.addressDescription?.toString(),
      'IsCalAddressVerified': calEvent.isAddressVerified?.toString(),
      'IsLocationCleared': clearLocation,
      'RestrictionProfileId': calEvent.restrictionProfileId,
      'RestrictiveWeek':
          calEvent.restrictionProfile?.toRestrictionWeekConfig()?.toJson(),
      'RepetitionConfig': calEvent.repetition?.toRequestJson(),
      'ColorConfig': calEvent.uiConfig?.tileColor?.toRequestJson(),
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
    error.Message = "Did not send request";
    var completeParameters = {
      'ID': eventId,
      'EventID': eventId,
      'TimeZoneOffset': Utility.currentTime().timeZoneOffset.inHours.toString(),
      'MobileApp': true.toString()
    };

    return sendPostRequest('api/CalendarEvent/Complete', completeParameters)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return CalendarEvent.fromJson(jsonResult['Content']);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.Message!);
      } else {
        error.Message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> getCalEvent(
      {String? id, String? designatedTileId}) async {
    String tilerDomain = Constants.tilerDomain;
    // String url = tilerDomain + 'api/SubCalendarEvent';
    // return getAdHocSubEventId(id);
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {
        'EventID': id,
        'TileShareTemplateId': designatedTileId
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/CalendarEvent', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(Message: 'Issues with authentication');
      }
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          print("cal event data");
          print(jsonResult['Content'].toString());
          return CalendarEvent.fromJson(jsonResult['Content']);
        }
      }
      if (isTilerRequestError(jsonResult)) {
        throw TilerError.fromJson(jsonResult);
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
        throw TilerError(Message: 'Issues with authentication');
      }
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return jsonResult['Content']
              .map<SubCalendarEvent>(
                  (eachSubEvent) => SubCalendarEvent.fromJson(eachSubEvent))
              .toList();
        }
      }
      if (isTilerRequestError(jsonResult)) {
        throw TilerError.fromJson(jsonResult);
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
        throw TilerError(Message: 'Issues with authentication');
      }
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
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

      if (isTilerRequestError(jsonResult)) {
        throw TilerError.fromJson(jsonResult);
      }
      throw TilerError();
    }
    throw TilerError();
  }
}
