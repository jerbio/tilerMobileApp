// Creating a share and deleting a tilette, tested at the HTTP level against
// a recording client - no network.
//   POST   api/TileShareCluster   -> the new share (its JSON, with its id)
//   DELETE api/TileshareTemplate  {Id}
// The server confirms with code 0 and no content (found on-device:
// {"Error":{"Code":"0","Message":"Tilette deleted"},"Content":null}), which
// is a success - the tilette is gone.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

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

    test('a refused create dumps the whole reply - status, headers, body',
        () async {
      final List<String> logs = <String>[];
      final void Function(String) original = TileShareLog.sink;
      TileShareLog.sink = logs.add;
      addTearDown(() => TileShareLog.sink = original);
      client.nextStatus = 500;
      client.nextHeaders = {
        'content-type': 'application/json',
        'request-id': 'req-42',
      };
      client.nextBody = jsonEncode({
        'Message': 'An error has occurred.',
        'ExceptionMessage': 'Object reference not set to an instance',
        'StackTrace': '   at BuildCluster(...)',
      });
      await expectLater(
          api.createCluster(TileShareClusterData()..name = 'X'),
          throwsA(anything));
      final String dump = logs.singleWhere((l) => l.contains('create failed'));
      expect(dump, contains('500'));
      expect(dump, contains('request-id: req-42'));
      expect(dump, contains('Object reference not set to an instance'));
      expect(dump, contains('at BuildCluster(...)'));
    });

    test('a created share dumps nothing', () async {
      final List<String> logs = <String>[];
      final void Function(String) original = TileShareLog.sink;
      TileShareLog.sink = logs.add;
      addTearDown(() => TileShareLog.sink = original);
      client.nextBody = jsonEncode({
        'Error': {'Code': '0', 'Message': 'SUCCESS'},
        'Content': {'id': 'TileShareCluster+u+new'},
      });
      await api.createCluster(TileShareClusterData()..name = 'X');
      expect(logs.where((l) => l.contains('create failed')), isEmpty);
    });

    test("a plain bad request keeps the server's reason", () async {
      client.nextStatus = 400;
      client.nextBody = jsonEncode({'Message': 'A tilette is required.'});
      await expectLater(
          api.createCluster(TileShareClusterData()..name = 'X'),
          throwsA(isA<TilerError>().having(
              (e) => e.Message, 'Message', 'A tilette is required.')));
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
