import 'dart:convert';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class IntegrationApi extends AppApi {
  IntegrationApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  Future<List<CalendarIntegration>?> getIntegrations(
      {String? integrationId}) async {
    try{
      final isAuthenticated = await authentication.isUserAuthenticated();
      if (!isAuthenticated.item1) {
        throw TilerError(message: LocalizationService.instance.translations.userIsNotAuthenticated);
      }
        await checkAndReplaceCredentialCache();
        final queryParameters = {'integrationId': integrationId};
        Map<String, dynamic> updatedParams = await injectRequestParams(
            queryParameters,
            includeLocationParams: false);
        Uri uri = Uri.https(Constants.tilerDomain, 'api/integrations', updatedParams);
        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: LocalizationService.instance.translations.authenticationIssues);
        }
        Utility.debugPrint('Requesting integrations with headers: $header');
        var response = await http.get(uri, headers: header);
        Utility.debugPrint('Integrations API response: ${response.body}');
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            List integrations = jsonResult['Content'];
            return integrations
                .map((e) => CalendarIntegration.fromJson(e))
                .toList();
          }
        }
    }catch (e) {
      Utility.debugPrint('Error fetching integrations: ${e is TilerError ? e.message : e}');
      throw TilerError(
          message: e is TilerError ? e.message : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<Map<String, dynamic>?> addIntegrationLocation(
      Location location, String calendarId) async {
    final isAuthenticated = await authentication.isUserAuthenticated();
    if (!isAuthenticated.item1) {
      throw TilerError(
          message: LocalizationService
              .instance.translations.userIsNotAuthenticated);
    }
    await checkAndReplaceCredentialCache();

      Map<String, dynamic> thirdPartyLocationPostData = {
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
          'api/integrations/location', thirdPartyLocationPostData,
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
        throw TilerError(message: LocalizationService.instance.translations.authenticationIssues);
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
