import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart' as Constants;

class IntegrationApi extends AppApi {
  Future<List<CalendarIntegration>?> integrations(
      {String? integrationId}) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {'integrationId': integrationId};

      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/integrations', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          List integtaions = jsonResult['Content'];
          return integtaions
              .map((e) => CalendarIntegration.fromJson(e))
              .toList();
        }
      }

      throw TilerError();
    }
    throw TilerError();
  }

  Future<Map<String, dynamic>?> addIntegrationLocation(
      Location location, String calendarId) async {
    Map<String, dynamic> thirdpartyLocationPostData = {
      'Id': location.id,
      'ThirdPartyId': location.thirdPartyId,
      'Longitude': location.longitude,
      'Latitude': location.latitude,
      'Address': location.address,
      'Description': location.description,
      'IsVerified': location.isVerified,
      'ThirdPartyCalendarId': calendarId
    };
    return sendPostRequest(
            'api/integrations/location', thirdpartyLocationPostData,
            injectLocation: false, analyze: false)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      return jsonResult;
    });
  }

  Future<bool?> deleteIntegration(
      CalendarIntegration calendarIntegration) async {
    TilerError error = new TilerError();
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      error.message = "Did not send request";
      String url = Constants.tilerDomain;

      Uri uri = Uri.https(url, 'api/Integrations');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var deleteIntegrationParameters = {
        'IntegrationId': calendarIntegration.id,
        'Provider': calendarIntegration.calendarType,
        'MobileApp': true.toString()
      };

      var injectedDeleteIntegrationParameters =
          await injectRequestParams(deleteIntegrationParameters);
      var response = await http.delete(uri,
          headers: header,
          body: json.encode(injectedDeleteIntegrationParameters));
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return true;
        }
      }
    }
    return false;
  }
}
