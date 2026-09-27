// `GET api/SubCalendarEvent` for a provider sub-event names the provider
// with the server's vocabulary (2026-09-19).
//
// The app's enum says `outlook`; the server says `microsoft` (as the search
// API, the integrations API and the sign-in flow all do). Every caller of
// `getSubEvent` passed `TileSource.name`, so a Microsoft sub-event went out
// as `ThirdPartyType=outlook` and the server could not find it. The
// translation lives on the enum (`TileSource.wireName`) and the API applies
// it at the boundary, so a caller that still passes the enum name is fixed
// too.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';

const String _subEventBody =
    '{"Error":{"Code":"0"},"Content":{"id":"sub-1","name":"Standup","start":1000,"end":2000}}';

void main() {
  group('TileSource.wireName', () {
    test('spells the provider the way the server does', () {
      expect(TileSource.tiler.wireName, 'tiler');
      expect(TileSource.google.wireName, 'google');
      expect(TileSource.outlook.wireName, 'microsoft');
    });

    test('tileSourceWireName normalises any spelling a caller still passes',
        () {
      expect(tileSourceWireName('outlook'), 'microsoft');
      expect(tileSourceWireName('Outlook'), 'microsoft');
      expect(tileSourceWireName('microsoft'), 'microsoft');
      expect(tileSourceWireName('google'), 'google');
      expect(tileSourceWireName('tiler'), 'tiler');
      expect(tileSourceWireName(''), '');
    });
  });

  group('wire-name parse (server -> enum)', () {
    test('tileSourceFromWireName maps the server spelling back to the enum',
        () {
      expect(tileSourceFromWireName('microsoft'), TileSource.outlook);
      expect(tileSourceFromWireName('Microsoft'), TileSource.outlook);
      expect(tileSourceFromWireName('outlook'), TileSource.outlook);
      expect(tileSourceFromWireName('google'), TileSource.google);
      expect(tileSourceFromWireName('tiler'), TileSource.tiler);
      expect(tileSourceFromWireName(''), isNull);
      expect(tileSourceFromWireName('something-else'), isNull);
    });

    test('a Microsoft sub-event parses as outlook, not null', () {
      final SubCalendarEvent sub = SubCalendarEvent.fromJson(<String, dynamic>{
        'id': 'sub-1',
        'name': 'Standup',
        'start': 1000,
        'end': 2000,
        'thirdpartyType': 'microsoft',
        'thirdPartyId': 'ms-id',
        'thirdPartyUserId': 'ms-user',
      });
      expect(sub.thirdpartyType, TileSource.outlook);
      expect(sub.isFromTiler, isFalse);
    });

    test('tiler, google and outlook parse as before; unknown stays null', () {
      expect(TilerEvent.fromJson(<String, dynamic>{'thirdpartyType': 'tiler'})
          .thirdpartyType,
          TileSource.tiler);
      expect(TilerEvent.fromJson(<String, dynamic>{'thirdpartyType': 'google'})
          .thirdpartyType,
          TileSource.google);
      expect(
          TilerEvent.fromJson(
                  <String, dynamic>{'thirdpartyType': 'outlook'})
              .thirdpartyType,
          TileSource.outlook);
      expect(
          TilerEvent.fromJson(<String, dynamic>{'thirdpartyType': 'something'})
              .thirdpartyType,
          isNull);
    });
  });

  group('getSubEvent', () {
    late _MockHttpClient client;
    late _TestSubCalendarEventApi api;

    setUp(() {
      client = _MockHttpClient();
      api = _TestSubCalendarEventApi()
        ..authentication.cachedCredentials =
            AuthenticationData.initializedWithRestData(
                'test-token', 'Bearer', 3600, 'tiler')
        ..httpClient = client;
    });

    tearDown(() => client.close());

    Map<String, String> query() => client.lastRequest!.url.queryParameters;

    test('a Microsoft sub-event goes out as ThirdPartyType=microsoft',
        () async {
      client.nextResponseBody = _subEventBody;
      await api.getSubEvent('ms-sub-1',
          calendarSource: TileSource.outlook.name, thirdPartyUserId: 'ms-user');
      expect(query()['EventID'], 'ms-sub-1');
      expect(query()['ThirdPartyType'], 'microsoft');
      expect(query()['ThirdPartyUserID'], 'ms-user');
    });

    test('google and tiler are unchanged; an empty source stays empty',
        () async {
      client.nextResponseBody = _subEventBody;
      await api.getSubEvent('g-sub-1', calendarSource: 'google');
      expect(query()['ThirdPartyType'], 'google');
      await api.getSubEvent('t-sub-1', calendarSource: 'tiler');
      expect(query()['ThirdPartyType'], 'tiler');
      await api.getSubEvent('t-sub-2');
      expect(query()['ThirdPartyType'], '');
    });
  });
}

/// [SubCalendarEventApi] with [injectRequestParams] short-circuited so the
/// test never reaches the platform-channel timezone/location lookups.
class _TestSubCalendarEventApi extends SubCalendarEventApi {
  _TestSubCalendarEventApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    return Map<String, dynamic>.from(jsonMap);
  }
}

class _MockHttpClient extends RetryHttpClient {
  String nextResponseBody = '{"Error":{"Code":"0"}}';
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(nextResponseBody)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
