import 'dart:convert';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class IntegrationApi extends AppApi {
  IntegrationApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  Future<List<CalendarIntegration>?> getIntegrations(
      {String? integrationId}) async {
    try {
      final isAuthenticated = await authentication.isUserAuthenticated();
      if (!isAuthenticated.item1) {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
      await checkAndReplaceCredentialCache();
      final queryParameters = {'integrationId': integrationId};
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri =
          Uri.https(Constants.tilerDomain, 'api/integrations', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.authenticationIssues);
      }
      Utility.debugPrint('Requesting integrations with headers: $header');
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
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
    } catch (e) {
      Utility.debugPrint(
          'Error fetching integrations: ${e is TilerError ? e.Message : e}');
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
    return null;
  }

  /// Starts the backend-driven calendar-connect flow (tracker P4-2; server
  /// `StartCalendarConnect`).
  ///
  /// Sends an authenticated GET to `api/Integrations/connect` with the
  /// provider name and the app's return deep link ([Constants.calendarConnectRedirectTarget])
  /// as `redirectTarget`. The server replies with a 302 whose `Location`
  /// header points at the provider's authorization URL. The caller opens that
  /// URL in the external browser — the browser cannot carry the mobile Bearer
  /// token, so the authenticated call happens here, on the device. The
  /// connected calendar appears once the provider redirects back via the
  /// `tilerapp://` deep link (handled by `RedirectHandler`), which refreshes
  /// the integrations list.
  ///
  /// [provider] must be `google` or `microsoft` (the only providers the
  /// server accepts for the connect flow).
  Future<String> startCalendarConnect({required String provider}) async {
    final isAuthenticated = await authentication.isUserAuthenticated();
    if (!isAuthenticated.item1) {
      throw TilerError(
          Message: LocalizationService
              .instance.translations.userIsNotAuthenticated);
    }
    await checkAndReplaceCredentialCache();
    final queryParameters = {
      'provider': provider,
      'redirectTarget': Constants.calendarConnectRedirectTarget,
    };
    Map<String, dynamic> updatedParams = await injectRequestParams(
        queryParameters,
        includeLocationParams: false);
    Uri uri = Uri.https(
        Constants.tilerDomain, 'api/Integrations/connect', updatedParams);
    var header = this.getHeaders();
    if (header == null) {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.authenticationIssues);
    }
    Utility.debugPrint('Starting calendar connect for provider: $provider');
    var response = await httpClient.get(uri, headers: header).timeout(
      AppApi.requestTimeout,
      onTimeout: () {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.requestTimeout);
      },
    );
    // The http client does not follow redirects: a 302 whose Location header
    // holds the provider authorization URL is the expected success shape.
    String? authorizationUrl = response.headers['Location'];
    if (authorizationUrl == null || authorizationUrl.isEmpty) {
      Utility.debugPrint(
          'Calendar connect response missing Location header: '
          '${response.statusCode} ${response.body}');
      throw TilerError(
          Message: LocalizationService.instance.translations.errorOccurred);
    }
    return authorizationUrl;
  }

  Future<Map<String, dynamic>?> addIntegrationLocation(
      Location location, String calendarId) async {
    final isAuthenticated = await authentication.isUserAuthenticated();
    if (!isAuthenticated.item1) {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.userIsNotAuthenticated);
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
      error.Message = "Did not send request";
      String url = Constants.tilerDomain;
      Uri uri = Uri.https(url, 'api/Integrations');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.authenticationIssues);
      }
      var deleteIntegrationParameters = {
        'IntegrationId': calendarIntegration.id,
        'Provider': calendarIntegration.calendarType,
        'MobileApp': true.toString()
      };

      var injectedDeleteIntegrationParameters =
          await injectRequestParams(deleteIntegrationParameters);
      var response = await httpClient
          .delete(uri,
              headers: header,
              body: json.encode(injectedDeleteIntegrationParameters))
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
          return true;
        }
      }
    }
    return false;
  }

  Future<CalendarItem?> updateCalendarItem({
    required String calendarId,
    required String calendarName,
    required bool isSelected,
    required String integrationId,
    required String calendarItemId,
  }) async {
    try {
      final isAuthenticated = await authentication.isUserAuthenticated();
      if (!isAuthenticated.item1) {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
      await checkAndReplaceCredentialCache();

      Map<String, dynamic> updateCalendarItemData = {
        'CalendarId': calendarId,
        'CalendarName': calendarName,
        'IsSelected': isSelected,
        'IntegrationId': integrationId,
        'ThirdPartyType': 'google',
        'CalendarItemId': calendarItemId,
        'MobileApp': true,
      };

      // Inject common request parameters
      Map<String, dynamic> injectedParams = await injectRequestParams(
          updateCalendarItemData,
          includeLocationParams: false);

      Utility.debugPrint('Updating calendar item with data: $injectedParams');
      var response = await sendPostRequest(
          'api/Integrations/google/calendarItem', injectedParams,
          injectLocation: false, analyze: false);

      Utility.debugPrint('Update calendar item API response: ${response.body}');
      var jsonResult = jsonDecode(response.body);

      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          // Parse the updated calendar item from the response
          return CalendarItem.fromJson(jsonResult['Content']);
        }
      }
      return null;
    } catch (e) {
      Utility.debugPrint(
          'Error updating calendar item: ${e is TilerError ? e.Message : e}');
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }
}
