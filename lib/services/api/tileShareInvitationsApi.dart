import 'dart:convert';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/services/api/appApi.dart';

/// The invitations endpoint answered 401 / 403 / 404 — the user may not read
/// them (or is no longer a valid account).
class TileShareInvitationsAccessException implements Exception {}

class TileShareInvitationsApi extends AppApi {
  TileShareInvitationsApi({required super.getContextCallBack});

  /// One page of the signed-in user's **pending** invitations
  /// (`GET api/TileShare/Invitations`), ordered by assignment id. Pass the
  /// previous page's `nextCursor` as [afterId] to continue. The server exposes
  /// only what is needed to respond — no roster and no cluster history.
  Future<TileShareInvitationPage> getInvitations(
      {String? clusterId, String? afterId, int pageSize = 50}) async {
    if (!(await authentication.isUserAuthenticated()).item1)
      throw TileShareInvitationsAccessException();
    await checkAndReplaceCredentialCache();
    final headers = getHeaders();
    if (headers == null) throw TileShareInvitationsAccessException();
    final response = await httpClient
        .get(
            Uri.https(constants.tilerDomain, 'api/TileShare/Invitations', {
              'PageSize': pageSize.toString(),
              if (clusterId != null) 'ClusterId': clusterId,
              if (afterId != null) 'AfterId': afterId,
            }),
            headers: headers)
        .timeout(AppApi.requestTimeout);
    if ([401, 403, 404].contains(response.statusCode))
      throw TileShareInvitationsAccessException();
    if (response.statusCode != 200) throw StateError('Invitations unavailable');
    return TileShareInvitationPage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
