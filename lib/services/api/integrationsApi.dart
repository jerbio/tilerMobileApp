import 'dart:convert';
import 'package:http/http.dart' as http;
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
    // The server answers with a 302 whose Location header holds the provider
    // authorization URL. The helper sends the request with redirect-following
    // disabled so we read that raw redirect instead of receiving the
    // provider's consent page (a 200 HTML page with no Location header).
    return getCalendarConnectAuthorizationUrl(httpClient, uri, header);
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

  /// Deletes (disconnects) [calendarIntegration] from the backend.
  ///
  /// Sends `DELETE api/Integrations` with the integration id, its provider,
  /// and the mobile marker. Returns `true` when the server acknowledges the
  /// delete (`Error.Code == '0'`). A successful delete carries no `Content`
  /// (there is nothing to echo back), so success is judged by the error code
  /// alone — not by the presence of a `Content` field. Throws [TilerError]
  /// with the server's message when the delete fails, so the caller can show
  /// the actual reason instead of a generic error.
  Future<bool> deleteIntegration(
      CalendarIntegration calendarIntegration) async {
    final isAuthenticated = await authentication.isUserAuthenticated();
    if (!isAuthenticated.item1) {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.userIsNotAuthenticated);
    }
    await checkAndReplaceCredentialCache();

    var header = this.getHeaders();
    if (header == null) {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.authenticationIssues);
    }

    final deleteIntegrationParameters = {
      'IntegrationId': calendarIntegration.id,
      'Provider': calendarIntegration.calendarType,
      // Match the working POST endpoints (e.g. updateCalendarItem), which send
      // the mobile marker as a JSON boolean rather than the string "true".
      'MobileApp': true,
    };
    final injectedDeleteIntegrationParameters =
        await injectRequestParams(deleteIntegrationParameters);

    Utility.debugPrint(
        'Deleting integration: $injectedDeleteIntegrationParameters');
    final response = await httpClient
        .delete(
            Uri.https(Constants.tilerDomain, 'api/Integrations'),
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
    Utility.debugPrint('Delete integration API response: '
        '${response.statusCode} ${response.body}');

    final dynamic jsonResult;
    try {
      jsonResult = jsonDecode(response.body);
    } catch (_) {
      throw TilerError(
          Message: LocalizationService.instance.translations.errorOccurred);
    }

    // Success is the server reporting `Error.Code == '0'`. A delete returns no
    // `Content` (nothing to echo back), so it must not be rejected for lacking
    // one — the previous `isContentInResponse` check turned a successful
    // delete into a failure and left the row on the list.
    if (isJsonResponseOk(jsonResult)) {
      return true;
    }
    throw TilerError(Message: errorMessage(jsonResult));
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

/// Sends [uri] through [client] and returns the server's `Location` header.
///
/// The calendar-connect endpoint (`GET api/Integrations/connect`) answers with
/// a 302 whose `Location` header holds the provider authorization URL. The
/// request is sent with `followRedirects` disabled: with the http client's
/// default (follow), the 302 is chased to the provider's consent page and the
/// caller receives that page's 200 HTML body instead of the redirect — no
/// `Location` header, no authorization URL to launch in the external browser.
///
/// Throws [TilerError] when the response carries no usable `Location` header
/// (e.g. an auth failure answered with a 200/401 body) or when the request
/// times out after [timeout].
Future<String> getCalendarConnectAuthorizationUrl(
  http.Client client,
  Uri uri,
  Map<String, String> headers, {
  Duration timeout = AppApi.requestTimeout,
}) async {
  final request = http.Request('GET', uri)
    ..headers.addAll(headers)
    ..followRedirects = false
    ..maxRedirects = 0;
  final streamed = await client.send(request).timeout(timeout, onTimeout: () {
    throw TilerError(
        Message: LocalizationService.instance.translations.requestTimeout);
  });
  final response = await http.Response.fromStream(streamed);
  // Response header names are case-insensitive and the VM's http client
  // lower-cases them, so look the name up ignoring case.
  final String? authorizationUrl =
      _headerValueIgnoreCase(response.headers, 'Location');
  if (authorizationUrl == null || authorizationUrl.isEmpty) {
    Utility.debugPrint(
        'Calendar connect response missing Location header: '
        '${response.statusCode} ${response.body}');
    throw TilerError(
        Message: LocalizationService.instance.translations.errorOccurred);
  }
  return authorizationUrl;
}

/// Case-insensitive lookup in a response header map.
///
/// `package:http` hands back a plain `Map<String, String>` (no
/// case-insensitivity), and the VM's `HttpClient` lower-cases response header
/// names — so read the header by exact name first, then case-insensitively.
String? _headerValueIgnoreCase(Map<String, String> headers, String name) {
  final String? direct = headers[name];
  if (direct != null) return direct;
  final String target = name.toLowerCase();
  for (final MapEntry<String, String> entry in headers.entries) {
    if (entry.key.toLowerCase() == target) return entry.value;
  }
  return null;
}
