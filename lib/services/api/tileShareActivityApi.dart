import 'dart:convert';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/services/api/appApi.dart';

class TileShareActivityAccessException implements Exception {}

class TileShareActivityApi extends AppApi {
  TileShareActivityApi({required super.getContextCallBack});

  Future<TileShareActivityPage> getActivity(
      {String? clusterId, String? tiletteId, String? cursor}) async {
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
            }),
            headers: headers)
        .timeout(AppApi.requestTimeout);
    if ([401, 403, 404].contains(response.statusCode))
      throw TileShareActivityAccessException();
    if (response.statusCode != 200) throw StateError('Activity unavailable');
    return TileShareActivityPage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
