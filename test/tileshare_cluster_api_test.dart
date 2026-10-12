// Creating a share and deleting a tilette, tested at the HTTP level against
// a recording client - no network.
//   POST   api/TileShareCluster   -> the new share (its JSON, with its id)
//   DELETE api/TileshareTemplate  {Id}
// The server confirms with code 0 and no content (found on-device:
// {"Error":{"Code":"0","Message":"Tilette deleted"},"Content":null}), which
// is a success - the tilette is gone.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';

import 'helpers/recording_http_client.dart';

class _TestApi extends TileShareClusterApi {
  _TestApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
          {bool includeLocationParams = false}) async =>
      {...Map<String, dynamic>.from(jsonMap), 'TimeZone': 'UTC'};
}

void main() {
  late RecordingHttpClient client;
  late _TestApi api;

  setUp(() {
    client = RecordingHttpClient();
    api = _TestApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
  });
  tearDown(() => client.close());

  group('creating a share', () {
    test('POSTs the share and answers with the new share', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': '0', 'Message': 'SUCCESS'},
        'Content': {
          'id': 'TileShareCluster+u+new',
          'name': 'Weekly reading',
          'mode': 'broadcast',
        },
      });
      final share = TileShareClusterData()
        ..name = 'Weekly reading'
        ..mode = TileShareMode.broadcast
        ..isMultiTilette = false;
      final created = await api.createCluster(share);
      expect(client.last.method, 'POST');
      expect(client.last.url.path, '/api/TileShareCluster');
      expect(jsonDecode(client.last.body)['Mode'], 'broadcast');
      expect(created.id, 'TileShareCluster+u+new');
      expect(created.mode, TileShareMode.broadcast);
    });

    test('an error code is a failure', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': '500', 'Message': 'No'},
        'Content': null,
      });
      await expectLater(
          api.createCluster(TileShareClusterData()..name = 'X'),
          throwsA(anything));
    });
  });

  group('deleting a tilette', () {
    test('code 0 with no content is a success', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': '0', 'Message': 'Tilette deleted'},
        'Content': null,
        'ServerStatus': null,
      });
      await api.deleteTileShareTemplate('tpl-1');
      expect(client.last.method, 'DELETE');
      expect(client.last.url.path, '/api/TileshareTemplate');
      expect(jsonDecode(client.last.body)['Id'], 'tpl-1');
    });

    test('an error code is still a failure', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': '500', 'Message': 'No such tilette'},
        'Content': null,
      });
      await expectLater(
          api.deleteTileShareTemplate('tpl-1'), throwsA(anything));
    });

    test('a reply without the envelope is still a failure', () async {
      client.nextStatus = 400;
      client.nextBody =
          jsonEncode({'Message': 'Invalid TileShare template id provided'});
      await expectLater(
          api.deleteTileShareTemplate('tpl-1'), throwsA(anything));
    });
  });
}
