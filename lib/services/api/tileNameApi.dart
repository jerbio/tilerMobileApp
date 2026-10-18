import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';

import '../../constants.dart' as Constants;

class TileNameApi extends AppApi {
  TileNameApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  /// GA calendar search, paged after merging and ordering all available sources.
  /// A missing endpoint (404) is an error. Total source failure (502) remains
  /// distinct from a successful empty result. start/end are paired UTC epoch ms.
  Future<CalendarSearchResult> searchCalendarEvents(
    String query, {
    List<String>? sources,
    int? batchSize,
    int? index,
    int? start,
    int? end,
  }) async {
    try {
      if (!(await this.authentication.isUserAuthenticated()).item1) {
        return CalendarSearchResult.error(
            LocalizationService.instance.translations.userIsNotAuthenticated);
      }
      await checkAndReplaceCredentialCache();

      String url = Constants.tilerDomain;
      final queryParameters = buildCalendarSearchQueryParameters(query,
          sources: sources,
          batchSize: batchSize,
          index: index,
          start: start,
          end: end);
      Uri uri = Uri.https(url, 'api/CalendarEvent/Search', queryParameters);
      var header = this.getHeaders();
      if (header == null) {
        return CalendarSearchResult.error('Issues with authentication');
      }

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
      // Authentication, network and timeout failures never become empty matches.
      return CalendarSearchResult.error(e.Message ?? 'Network error');
    } on Exception {
      return CalendarSearchResult.error('Network error');
    }
  }
}
