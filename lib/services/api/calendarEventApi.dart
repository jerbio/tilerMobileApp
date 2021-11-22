import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'dart:convert';

import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class CalendarEventApi extends AppApi {
  setAsNow(String eventId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    String url = Constants.tilerDomain;

    Uri uri = Uri.https(url, 'api/CalendarEvent/Now');
    var header = this.getHeaders();

    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();

      if (header != null) {
        var setAsNowParameters = {
          'ID': eventId,
          'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
          'MobileApp': true.toString()
        };
        var response = await http.post(uri,
            headers: header, body: json.encode(setAsNowParameters));
        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            var setAsNowJson = jsonResult['Content'];
            return setAsNowJson;
          } else {
            if (isTileRequestError(jsonResult)) {
              var errorJson = jsonResult['Error'];
              error = TilerError.fromJson(errorJson);
            } else {
              error.Message = "Issues with reaching TIler servers";
            }
          }
        }
      }
    } else {
      throw NullThrownError();
    }
  }

  delete(String eventId, String thirdPartyId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    String url = Constants.tilerDomain;

    Uri uri = Uri.https(url, 'api/CalendarEvent');
    var header = this.getHeaders();

    if (header != null) {
      var setAsNowParameters = {
        'ID': eventId,
        'EventID': eventId,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'ThirdPartyEventID': thirdPartyId,
        'MobileApp': true.toString()
      };
      var response = await http.delete(uri,
          headers: header, body: json.encode(setAsNowParameters));
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          var setAsNowJson = jsonResult['Content'];
          return setAsNowJson;
        } else {
          if (isTileRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
          } else {
            error.Message = "Issues with reaching TIler servers";
          }
        }
      }
    }
  }

  complete(String eventId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    String url = Constants.tilerDomain;

    Uri uri = Uri.https(url, 'api/CalendarEvent/Complete');
    var header = this.getHeaders();

    if (header != null) {
      var setAsNowParameters = {
        'ID': eventId,
        'EventID': eventId,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };
      var response = await http.post(uri,
          headers: header, body: json.encode(setAsNowParameters));
      var jsonResult = jsonDecode(response.body);
      error.Message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          var setAsNowJson = jsonResult['Content'];
          return setAsNowJson;
        } else {
          if (isTileRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
          } else {
            error.Message = "Issues with reaching TIler servers";
          }
        }
      }
    }
  }
}
