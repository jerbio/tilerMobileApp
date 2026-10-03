// TileShare redesign Step 9.13: adding and removing a tilette's recipients,
// tested at the HTTP level against a recording client - no network.
//   PUT    api/TileshareTemplate/contact  {EntityId: tilette, Contact}
//          -> {tileTemplate} - the tilette with its recipients, so the roster
//             refreshes from the answer
//   DELETE api/TileshareTemplate/contact  {TiletteId, AssignmentId}
// A failure says which kind (by HTTP status) with the server's reason, and is
// logged; nothing that failed is reported as done (contact-input doc 3.3).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/recording_http_client.dart';

class _TestApi extends TileShareRecipientsApi {
  _TestApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
          {bool includeLocationParams = false}) async =>
      {...Map<String, dynamic>.from(jsonMap), 'TimeZone': 'UTC'};
}

String _ok(Object? content) => jsonEncode({
      'Error': {'Code': '0', 'Message': 'SUCCESS'},
      'Content': content,
    });

Map<String, dynamic> _tilette() => {
      'id': 'tpl-1',
      'name': 'Pack boxes',
      'clusterId': 'c1',
      'designatedUsers': [
        {
          'id': 'u-ann',
          'designatedTileTemplateId': 'asg-ann',
          'userId': 'u-ann',
          'displayedIdentifier': 'ann@x.com',
          'rsvpStatus': 'none',
        },
      ],
    };

Contact _email(String email) => Contact()..email = email;

void main() {
  late RecordingHttpClient client;
  late _TestApi api;
  late List<String> logs;
  late void Function(String) originalSink;

  setUp(() {
    client = RecordingHttpClient();
    api = _TestApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() {
    client.close();
    TileShareLog.sink = originalSink;
  });

  Map<String, dynamic> sentBody() =>
      jsonDecode(client.last.body) as Map<String, dynamic>;

  group('adding', () {
    test('PUTs the tilette and the contact, and returns the tilette with its '
        'recipients', () async {
      client.nextBody = _ok({'tileTemplate': _tilette()});
      final tilette = await api.addRecipient('tpl-1', _email('ann@x.com'));
      expect(client.last.method, 'PUT');
      expect(client.last.url.path, '/api/TileshareTemplate/contact');
      expect(client.last.headers['Authorization'], 'Bearer test-token');
      expect(sentBody()['EntityId'], 'tpl-1');
      expect(sentBody()['Contact'], {'Email': 'ann@x.com'});
      expect(tilette.id, 'tpl-1');
      expect(tilette.designatedUsers!.single.designatedTileTemplateId,
          'asg-ann');
      expect(logs.any((l) => l.contains('-> PUT')), isTrue);
      expect(logs.any((l) => l.contains('<- PUT')), isTrue);
    });

    test('a phone number is sent as one', () async {
      client.nextBody = _ok({'tileTemplate': _tilette()});
      await api.addRecipient('tpl-1', Contact()..phoneNumber = '+15555550100');
      expect(sentBody()['Contact'], {'PhoneNumber': '+15555550100'});
    });

    test('a refusal is a failure with the server\'s reason', () async {
      client.nextStatus = 400;
      client.nextBody = jsonEncode('An email or phone number is required.');
      await expectLater(
          api.addRecipient('tpl-1', _email('x')),
          throwsA(isA<TileShareRecipientFailure>()
              .having((f) => f.kind, 'kind', TileShareFailureKind.invalid)
              .having((f) => f.reason, 'reason', contains('email'))));
    });

    test('a 200 without the tilette is not success', () async {
      client.nextBody = _ok({'something': 'else'});
      await expectLater(api.addRecipient('tpl-1', _email('ann@x.com')),
          throwsA(isA<StateError>()));
    });
  });

  group('removing', () {
    test('DELETEs the tilette and the recipient\'s assignment', () async {
      client.nextBody = _ok('Recipient removed');
      await api.removeRecipient('tpl-1', 'asg-ann');
      expect(client.last.method, 'DELETE');
      expect(client.last.url.path, '/api/TileshareTemplate/contact');
      expect(sentBody()['TiletteId'], 'tpl-1');
      expect(sentBody()['AssignmentId'], 'asg-ann');
    });

    test('a recipient already gone is notFound; a concurrent change is a '
        'conflict', () async {
      client.nextStatus = 404;
      client.nextBody = '';
      await expectLater(
          api.removeRecipient('tpl-1', 'asg-ann'),
          throwsA(isA<TileShareRecipientFailure>()
              .having((f) => f.kind, 'kind', TileShareFailureKind.notFound)));
      client.nextStatus = 409;
      await expectLater(
          api.removeRecipient('tpl-1', 'asg-ann'),
          throwsA(isA<TileShareRecipientFailure>()
              .having((f) => f.kind, 'kind', TileShareFailureKind.conflict)));
    });

    test('a Tiler error inside a 200 is not success', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': '5', 'Message': 'nope'},
        'Content': null
      });
      await expectLater(api.removeRecipient('tpl-1', 'asg-ann'),
          throwsA(isA<StateError>()));
    });
  });
}
