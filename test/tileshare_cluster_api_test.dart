// Deleting a tilette, tested at the HTTP level against a recording client -
// no network.
//   DELETE api/TileshareTemplate  {Id}
// The server confirms with code 0 and no content (found on-device:
// {"Error":{"Code":"0","Message":"Tilette deleted"},"Content":null}), which
// is a success - the tilette is gone.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
