import 'dart:convert';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/services/api/appApi.dart';

class TileShareActivityAccessException implements Exception {}

class TileShareActivityApi extends AppApi {
  TileShareActivityApi({required super.getContextCallBack});

  /// One page of the activity feed (`GET api/TileShare/Activity`), newest
  /// first. By default only events the user has **not** dismissed;
  /// [dismissedOnly] asks for the dismissed ones instead. [eventType] filters
  /// to a single event type and [pageSize] (1..100) bounds the page — both are
  /// omitted from the request unless given, so existing callers are unchanged.
  Future<TileShareActivityPage> getActivity(
      {String? clusterId,
      String? tiletteId,
      String? cursor,
      int? pageSize,
      String? eventType,
      bool dismissedOnly = false}) async {
    if (!(await authentication.isUserAuthenticated()).item1)
      throw TileShareActivityAccessException();
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) throw TileShareActivityAccessException();
    final response = await httpClient
        .get(
            Uri.https(constants.tilerDomain, 'api/TileShare/Activity', {
              if (clusterId != null) 'ClusterId': clusterId,
              if (tiletteId != null) 'TiletteId': tiletteId,
              if (cursor != null) 'Cursor': cursor,
              if (pageSize != null) 'PageSize': pageSize.toString(),
              if (eventType != null) 'EventType': eventType,
              if (dismissedOnly) 'DismissedOnly': 'true',
            }),
            headers: headers)
        .timeout(AppApi.requestTimeout);
    if ([401, 403, 404].contains(response.statusCode))
      throw TileShareActivityAccessException();
    if (response.statusCode != 200) throw StateError('Activity unavailable');
    return TileShareActivityPage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Dismisses ([isDismissed] `true`) or restores one activity event for the
  /// signed-in user (`POST api/TileShare/Activity/Dismissal`). The preference
  /// is stored server-side, so it follows the user across devices.
  Future<void> setDismissed(String eventId, bool isDismissed) async {
    if (!(await authentication.isUserAuthenticated()).item1)
      throw TileShareActivityAccessException();
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) throw TileShareActivityAccessException();
    final response = await httpClient
        .post(
            Uri.https(
                constants.tilerDomain, 'api/TileShare/Activity/Dismissal'),
            headers: headers,
            body:
                jsonEncode({'EventId': eventId, 'IsDismissed': isDismissed}))
        .timeout(AppApi.requestTimeout);
    if ([401, 403, 404].contains(response.statusCode))
      throw TileShareActivityAccessException();
    if (response.statusCode != 200) {
      throw StateError('Activity preference could not be saved');
    }
  }
}
