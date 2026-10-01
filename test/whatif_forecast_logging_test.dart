// The what-if forecast (`WhatIfApi.forecastNewTile`) used to fail silently: a
// 200 whose body was unusable returned an empty forecast, and a body that did
// not parse threw an error nothing displayed, so the old invitation screen just
// stopped its spinner and showed nothing. Behaviour is unchanged; the reason is
// now logged so it can be diagnosed.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

import 'helpers/recording_http_client.dart';

class _TestWhatIfApi extends WhatIfApi {
  _TestWhatIfApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    return {...Map<String, dynamic>.from(jsonMap), 'TimeZone': 'UTC'};
  }
}

void main() {
  late RecordingHttpClient client;
  late _TestWhatIfApi api;

  setUp(() {
    client = RecordingHttpClient();
    api = _TestWhatIfApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
  });
  tearDown(() => client.close());

  /// Runs [body] and returns what it printed.
  Future<List<String>> printed(Future<void> Function() body) async {
    final lines = <String>[];
    await runZoned(body,
        zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => lines.add(line)));
    return lines;
  }

  const params = <String, Object>{'DurationInMs': '3600000'};

  test('a usable answer logs no failure and is returned as before', () async {
    client.nextBody =
        '{"Error":{"Code":"0","Message":"SUCCESS"},"Content":{"isViable":true,"peekDays":[]}}';
    late ForecastResponse result;
    final lines = await printed(() async {
      result = await api.forecastNewTile(params);
    });
    expect(result.isViable, isTrue);
    expect(lines.where((l) => l.contains('WhatIfApi')), isEmpty);
  });

  test('a Tiler-level error inside a 200 still returns an empty forecast, '
      'and now says what the server said', () async {
    client.nextBody =
        '{"Error":{"Code":"7","Message":"cannot forecast that"},"Content":null}';
    late ForecastResponse result;
    final lines = await printed(() async {
      result = await api.forecastNewTile(params);
    });
    expect(result.peekDays, isNull, reason: 'behaviour unchanged');
    expect(
        lines.any((l) =>
            l.contains('WhatIfApi') &&
            l.contains('cannot forecast that') &&
            l.contains('200')),
        isTrue,
        reason: '$lines');
  });

  test('an answer with no content says so', () async {
    client.nextBody = '{"Error":{"Code":"0","Message":"SUCCESS"},"Content":null}';
    final lines = await printed(() async {
      await api.forecastNewTile(params);
    });
    expect(lines.any((l) => l.contains('WhatIfApi') && l.contains('no Content')),
        isTrue,
        reason: '$lines');
  });

  test('a body that cannot be read throws the same error as before and '
      'logs the real cause', () async {
    client.nextBody = '<html>Gateway timeout</html>';
    client.nextStatus = 504;
    Object? thrown;
    final lines = await printed(() async {
      try {
        await api.forecastNewTile(params);
      } catch (e) {
        thrown = e;
      }
    });
    expect(thrown, isA<TilerError>());
    expect((thrown as TilerError).Message, 'Failed to get preview',
        reason: 'the error callers already handle is unchanged');
    expect(
        lines.any((l) =>
            l.contains('WhatIfApi') && l.contains('504') && l.contains('forecast failed')),
        isTrue,
        reason: '$lines');
  });

  test('a forecast whose days do not parse logs why', () async {
    client.nextBody =
        '{"Error":{"Code":"0","Message":"SUCCESS"},"Content":{"peekDays":[{"unallocatedTime":"not a number"}]}}';
    Object? thrown;
    final lines = await printed(() async {
      try {
        await api.forecastNewTile(params);
      } catch (e) {
        thrown = e;
      }
    });
    expect(thrown, isNotNull);
    expect(lines.any((l) => l.contains('WhatIfApi') && l.contains('forecast failed')),
        isTrue,
        reason: '$lines');
  });
}
