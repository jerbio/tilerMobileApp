import 'dart:convert';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The activity endpoints answered 401 / 403 / 404 (the user may not read it,
/// or it is no longer there) or there were no credentials to ask with.
class TileShareActivityAccessException implements Exception {
  /// The HTTP status; `null` when the request was never sent (not signed in).
  final int? statusCode;

  const TileShareActivityAccessException([this.statusCode]);

  @override
  String toString() => 'TileShareActivityAccessException('
      '${statusCode == null ? 'not signed in' : 'HTTP $statusCode'})';
}

class TileShareActivityApi extends AppApi {
  static const String _tag = 'TileShareActivityApi';
  static const String _route = 'api/TileShare/Activity';
  static const String _dismissalRoute = 'api/TileShare/Activity/Dismissal';

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
    if (!(await authentication.isUserAuthenticated()).item1) {
      TileShareLog.d(_tag, 'GET $_route not sent: not signed in');
      throw const TileShareActivityAccessException();
    }
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) {
      TileShareLog.d(_tag, 'GET $_route not sent: no credentials');
      throw const TileShareActivityAccessException();
    }
    final response = await httpClient
        .get(
            Uri.https(constants.tilerDomain, _route, {
              if (clusterId != null) 'ClusterId': clusterId,
              if (tiletteId != null) 'TiletteId': tiletteId,
              if (cursor != null) 'Cursor': cursor,
              if (pageSize != null) 'PageSize': pageSize.toString(),
              if (eventType != null) 'EventType': eventType,
              if (dismissedOnly) 'DismissedOnly': 'true',
            }),
            headers: headers)
        .timeout(AppApi.requestTimeout);
    if (response.statusCode != 200) {
      TileShareLog.d(_tag, 'GET $_route -> HTTP ${response.statusCode}');
      if ([401, 403, 404].contains(response.statusCode)) {
        throw TileShareActivityAccessException(response.statusCode);
      }
      throw StateError('Activity unavailable (HTTP ${response.statusCode})');
    }
    return TileShareActivityPage.fromJson(readTileShareContent(response.body,
        tag: _tag, what: 'Activity', listKey: 'items'));
  }

  /// Dismisses ([isDismissed] `true`) or restores one activity event for the
  /// signed-in user (`POST api/TileShare/Activity/Dismissal`). The preference
  /// is stored server-side, so it follows the user across devices.
  Future<void> setDismissed(String eventId, bool isDismissed) async {
    if (!(await authentication.isUserAuthenticated()).item1) {
      TileShareLog.d(_tag, 'POST $_dismissalRoute not sent: not signed in');
      throw const TileShareActivityAccessException();
    }
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) {
      TileShareLog.d(_tag, 'POST $_dismissalRoute not sent: no credentials');
      throw const TileShareActivityAccessException();
    }
    final response = await httpClient
        .post(
            Uri.https(constants.tilerDomain, _dismissalRoute),
            headers: headers,
            body:
                jsonEncode({'EventId': eventId, 'IsDismissed': isDismissed}))
        .timeout(AppApi.requestTimeout);
    if (response.statusCode != 200) {
      TileShareLog.d(_tag,
          'POST $_dismissalRoute -> HTTP ${response.statusCode} (event $eventId)');
      if ([401, 403, 404].contains(response.statusCode)) {
        throw TileShareActivityAccessException(response.statusCode);
      }
      throw StateError(
          'Activity preference could not be saved (HTTP ${response.statusCode})');
    }
  }
}
