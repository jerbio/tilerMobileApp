import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The invitations endpoint answered 401 / 403 / 404 — the user may not read
/// them (or is no longer a valid account) — or there were no credentials to
/// ask with. A 404 is also what a backend without this endpoint answers, which
/// is why the status is carried and printed.
class TileShareInvitationsAccessException implements Exception {
  /// The HTTP status; `null` when the request was never sent (not signed in).
  final int? statusCode;

  const TileShareInvitationsAccessException([this.statusCode]);

  @override
  String toString() => 'TileShareInvitationsAccessException('
      '${statusCode == null ? 'not signed in' : 'HTTP $statusCode'})';
}

class TileShareInvitationsApi extends AppApi {
  static const String _tag = 'TileShareInvitationsApi';
  static const String _route = 'api/TileShare/Invitations';

  TileShareInvitationsApi({required super.getContextCallBack});

  /// One page of the signed-in user's **pending** invitations
  /// (`GET api/TileShare/Invitations`), ordered by assignment id. Pass the
  /// previous page's `nextCursor` as [afterId] to continue. The server exposes
  /// only what is needed to respond — no roster and no cluster history.
  Future<TileShareInvitationPage> getInvitations(
      {required String clusterId, String? afterId, int pageSize = 50}) async {
    return TileShareInvitationPage.fromJson(await _read(
        listKey: 'invitations',
        clusterId: clusterId,
        afterId: afterId,
        pageSize: pageSize));
  }

  /// One page of the projects the user has pending invitations in, with a count
  /// each. This is what the server answers when the call is not scoped to a
  /// cluster; the per-task invitations of a project come from [getInvitations].
  Future<TileShareInvitationProjectPage> getInvitationProjects(
      {String? afterId, int pageSize = 50}) async {
    return TileShareInvitationProjectPage.fromJson(await _read(
        listKey: 'projects', afterId: afterId, pageSize: pageSize));
  }

  Future<Map<String, dynamic>> _read(
      {required String listKey,
      String? clusterId,
      String? afterId,
      required int pageSize}) async {
    if (!(await authentication.isUserAuthenticated()).item1) {
      TileShareLog.d(_tag, 'GET $_route not sent: not signed in');
      throw const TileShareInvitationsAccessException();
    }
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) {
      TileShareLog.d(_tag, 'GET $_route not sent: no credentials');
      throw const TileShareInvitationsAccessException();
    }
    final response = await httpClient
        .get(
            Uri.https(constants.tilerDomain, _route, {
              'PageSize': pageSize.toString(),
              if (clusterId != null) 'ClusterId': clusterId,
              if (afterId != null) 'AfterId': afterId,
            }),
            headers: headers)
        .timeout(AppApi.requestTimeout);
    if (response.statusCode != 200) {
      TileShareLog.d(_tag, 'GET $_route -> HTTP ${response.statusCode}');
      if ([401, 403, 404].contains(response.statusCode)) {
        throw TileShareInvitationsAccessException(response.statusCode);
      }
      throw StateError('Invitations unavailable (HTTP ${response.statusCode})');
    }
    return readTileShareContent(response.body,
        tag: _tag, what: 'Invitations', listKey: listKey);
  }
}
