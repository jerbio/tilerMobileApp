import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';
import 'dart:convert';

import '../../constants.dart' as Constants;

class TileNameApi extends AppApi {
  TileNameApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<List<TilerEvent>>? chainPending;

  var nextRequestParams = [];

  List<TilerEvent> processTileEventList(http.Response response) {
    var jsonResult = jsonDecode(response.body);
    if (isJsonResponseOk(jsonResult)) {
      if (isContentInResponse(jsonResult)) {
        List calEventJson = jsonResult['Content'];
        List sleepTimelinesJson = [];
        print("Got more data " + calEventJson.length.toString());
        List<Timeline> sleepTimelines = sleepTimelinesJson
            .map((timelinesJson) => Timeline.fromJson(timelinesJson))
            .toList();

        List<TilerEvent> calEvents = calEventJson
            .map((eachSubEventJson) => TilerEvent.fromJson(eachSubEventJson))
            .toList();
        List<TilerEvent> retValue = calEvents;
        return retValue;
      }
    }
    throw TilerError();
  }

  Future<List<TilerEvent>> _createEventFuture(Uri uri, var header) async {
    var pendingRequest = httpClient.get(uri, headers: header).timeout(
      AppApi.requestTimeout,
      onTimeout: () {
        throw TilerError(
            Message: LocalizationService.instance.translations.requestTimeout);
      },
    );
    http.Response response = await pendingRequest;
    while (nextRequestParams.length > 0) {
      var params = nextRequestParams.last;
      nextRequestParams = [];
      header = params['header'];
      uri = params['uri'];
      response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
    }
    this.chainPending = null;
    return processTileEventList(response);
  }

  Future<List<TilerEvent>> getTilesByName(String name) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;

    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();

      final queryParameters = {
        'Data': name,
        'TimeZoneOffset':
            Utility.currentTime().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };

      Uri uri = Uri.https(url, 'api/CalendarEvent/Name', queryParameters);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(Message: 'Issues with authentication');
      }
      if (chainPending != null) {
        var param = {
          'header': header,
          'uri': uri,
        };
        this.nextRequestParams.add(param);
        List<TilerEvent>? events = await chainPending;
        if (events != null) {
          return events;
        }
        throw TilerError();
      }

      chainPending = this._createEventFuture(uri, header);
      List<TilerEvent> retValue = await chainPending!;
      chainPending = null;
      return retValue;
    }
    throw TilerError();
  }

  /// Multi-source calendar event search (`GET api/CalendarEvent/Search`).
  ///
  /// Returns a typed [CalendarSearchResult]:
  /// - `success` when the PostBack envelope is available (it may still carry a
  ///   partial-failure warning via `envelope.hasPartialFailure`).
  /// - `flagOff` on a plain 404 — the endpoint's feature flag is off for this
  ///   user; callers fall back to the legacy `api/CalendarEvent/Name` search.
  /// - `unavailable` on a 502 total source failure (typed
  ///   [CalendarSearchUnavailableError]).
  /// - `error` on any other failure (400, network, timeout).
  ///
  /// Mobile has no client-side rollout flag, so a plain 404 (never an error) is the
  /// signal to preserve the legacy name-search behavior.
  Future<CalendarSearchResult> searchCalendarEvents(
    String query, {
    List<String>? sources,
  }) async {
    if (!(await this.authentication.isUserAuthenticated()).item1) {
      return CalendarSearchResult.error(
          LocalizationService.instance.translations.userIsNotAuthenticated);
    }
    await checkAndReplaceCredentialCache();

    String url = Constants.tilerDomain;
    final queryParameters =
        buildCalendarSearchQueryParameters(query, sources: sources);
    Uri uri = Uri.https(url, 'api/CalendarEvent/Search', queryParameters);
    var header = this.getHeaders();
    if (header == null) {
      return CalendarSearchResult.error('Issues with authentication');
    }

    try {
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
      return parseCalendarSearchResponse(response.statusCode, response.body);
    } on TilerError catch (e) {
      // A timeout / network failure is a real error, NOT a flag-off fallback.
      return CalendarSearchResult.error(e.Message ?? 'Network error');
    }
  }
}
