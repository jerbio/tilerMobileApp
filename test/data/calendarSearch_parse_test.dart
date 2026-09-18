import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/tilerEvent.dart';

void main() {
  group('buildCalendarSearchQueryParameters', () {
    test('includes only query when no sources are provided', () {
      expect(buildCalendarSearchQueryParameters('gym'), {'query': 'gym'});
    });

    test('joins sources with commas when provided', () {
      final params =
          buildCalendarSearchQueryParameters('gym', sources: ['tiler', 'google']);

      expect(params['query'], 'gym');
      expect(params['sources'], 'tiler,google');
    });

    test('omits the sources key when the list is empty', () {
      final params = buildCalendarSearchQueryParameters('gym', sources: []);

      expect(params['query'], 'gym');
      expect(params.containsKey('sources'), isFalse);
    });
  });

  group('parseCalendarSearchResponse', () {
    test('200 with a PostBack envelope maps to a success envelope', () {
      final body =
          '{"Error":{"Code":"0","Message":""},"Content":{"items":[{"id":"e1","name":"Gym","start":1,"end":2,"source":"tiler","thirdPartyEventId":null,"thirdPartyUserId":null,"isReadOnly":false,"capabilities":{"canEdit":true,"canDelete":true,"canComplete":true,"canSetAsNow":true}}],"sources":[{"source":"tiler","status":"success","queryMode":"native-query"}],"correlationId":"abc"}}';
      final result = parseCalendarSearchResponse(200, body);

      expect(result.isSuccess, isTrue);
      expect(result.envelope!.items.length, 1);
      expect(result.envelope!.items.first.name, 'Gym');
      expect(result.envelope!.sources.first.status, CalendarSearchStatus.success);
      expect(result.envelope!.correlationId, 'abc');
    });

    test('200 with empty items is a success (a no-match, never an error)', () {
      final body =
          '{"Error":{"Code":"0","Message":""},"Content":{"items":[],"sources":[],"correlationId":"abc"}}';
      final result = parseCalendarSearchResponse(200, body);

      expect(result.isSuccess, isTrue);
      expect(result.envelope!.items, isEmpty);
    });

    test('plain 404 maps to flagOff (never an error, never unavailable)', () {
      final result = parseCalendarSearchResponse(404, '');

      expect(result.isFlagOff, isTrue);
      expect(result.isError, isFalse);
      expect(result.isUnavailable, isFalse);
      expect(result.isSuccess, isFalse);
    });

    test('502 maps to the typed unavailable error (never an empty result)', () {
      final body =
          '{"error":"search_unavailable","message":"boom","category":"authentication","correlationId":"xyz","sources":[{"provider":"google","email":"a@b.c","category":"authentication"}]}';
      final result = parseCalendarSearchResponse(502, body);

      expect(result.isUnavailable, isTrue);
      expect(result.isError, isFalse);
      expect(result.isSuccess, isFalse);
      expect(result.unavailable!.code, 'search_unavailable');
      expect(result.unavailable!.category, 'authentication');
      expect(result.unavailable!.correlationId, 'xyz');
      expect(result.unavailable!.sources.length, 1);
      expect(result.unavailable!.sources.first.provider, 'google');
    });

    test('502 with an empty body still yields a typed unavailable error', () {
      final result = parseCalendarSearchResponse(502, '');

      expect(result.isUnavailable, isTrue);
      expect(result.unavailable!.code, CalendarSearchUnavailableError.codeSearchUnavailable);
    });

    test('400 maps to an error (not a flag-off fallback)', () {
      final result =
          parseCalendarSearchResponse(400, 'Invalid search parameters');

      expect(result.isError, isTrue);
      expect(result.isFlagOff, isFalse);
      expect(result.isUnavailable, isFalse);
    });

    test('other statuses map to an error', () {
      final result = parseCalendarSearchResponse(500, '');

      expect(result.isError, isTrue);
    });
  });
  group('CalendarSearchItem.fromJson', () {
    test('parses a provider row with capabilities + identity', () {
      final item = CalendarSearchItem.fromJson({
        'id': 'ev-1',
        'name': 'Standalone',
        'start': 1000,
        'end': 2000,
        'source': 'microsoft',
        'thirdPartyEventId': 'graph-id',
        'thirdPartyUserId': 'user@outlook.com',
        'isReadOnly': true,
        'capabilities': {
          'canEdit': true,
          'canDelete': true,
          'canComplete': false,
          'canSetAsNow': false
        },
      });

      expect(item.id, 'ev-1');
      expect(item.sourceKind, CalendarSearchSource.microsoft);
      expect(item.isFromProvider, isTrue);
      expect(item.isFromTiler, isFalse);
      expect(item.thirdPartyEventId, 'graph-id');
      expect(item.thirdPartyUserId, 'user@outlook.com');
      expect(item.isReadOnly, isTrue);
      expect(item.capabilities.canEdit, isTrue);
      expect(item.capabilities.canDelete, isTrue);
      expect(item.capabilities.canComplete, isFalse);
      expect(item.capabilities.canSetAsNow, isFalse);
    });

    test('maps a microsoft provider row to TileSource.outlook via toTilerEvent', () {
      final item = CalendarSearchItem.fromJson({
        'id': 'ev-1',
        'name': 'Standalone',
        'start': 1000,
        'end': 2000,
        'source': 'microsoft',
        'thirdPartyEventId': 'graph-id',
        'thirdPartyUserId': 'user@outlook.com',
        'isReadOnly': false,
      });

      final event = item.toTilerEvent();
      expect(event.id, 'ev-1');
      expect(event.name, 'Standalone');
      expect(event.start, 1000);
      expect(event.end, 2000);
      expect(event.thirdpartyType, TileSource.outlook);
      expect(event.thirdpartyId, 'graph-id');
      expect(event.thirdPartyUserId, 'user@outlook.com');
    });

    test('a native tiler row has a null provider id and defaults off capabilities', () {
      final item = CalendarSearchItem.fromJson({
        'id': 'tiler-1',
        'name': 'Tiler tile',
        'start': 1,
        'end': 2,
        'source': 'tiler',
        'thirdPartyEventId': null,
        'thirdPartyUserId': null,
        'isReadOnly': false,
      });

      expect(item.sourceKind, CalendarSearchSource.tiler);
      expect(item.isFromTiler, isTrue);
      expect(item.thirdPartyEventId, isNull);
      // Absent capabilities default to all-off (read-only semantics).
      expect(item.capabilities.canEdit, isFalse);
      expect(item.toTilerEvent().thirdpartyType, TileSource.tiler);
    });
  });

  group('CalendarSearchSourceStatus.fromJson', () {
    test('partial carries failureCount + category + retryable', () {
      final status = CalendarSearchSourceStatus.fromJson({
        'source': 'google',
        'status': 'partial',
        'queryMode': 'native-query',
        'category': 'timeout',
        'retryable': true,
        'failureCount': 2,
      });

      expect(status.isPartial, isTrue);
      expect(status.isFailed, isFalse);
      expect(status.failureCount, 2);
      expect(status.category, 'timeout');
      expect(status.retryable, isTrue);
      expect(status.queryMode, CalendarSearchQueryMode.nativeQuery);
    });

    test('success omits category/retryable/failureCount', () {
      final status = CalendarSearchSourceStatus.fromJson({
        'source': 'tiler',
        'status': 'success',
        'queryMode': 'native-query',
      });

      expect(status.status, CalendarSearchStatus.success);
      expect(status.isPartial, isFalse);
      expect(status.isFailed, isFalse);
      expect(status.failureCount, isNull);
      expect(status.retryable, isNull);
      expect(status.category, isNull);
    });
  });

  group('CalendarSearchUnavailableError.fromJson', () {
    test('defaults the code when the body lacks one', () {
      final error = CalendarSearchUnavailableError.fromJson({});

      expect(error.code, CalendarSearchUnavailableError.codeSearchUnavailable);
    });

    test('parses the failed-source list', () {
      final error = CalendarSearchUnavailableError.fromJson({
        'error': 'search_unavailable',
        'sources': [
          {
            'provider': 'microsoft',
            'email': 'x@y.z',
            'category': 'provider'
          }
        ],
      });

      expect(error.sources.length, 1);
      expect(error.sources.first.provider, 'microsoft');
      expect(error.sources.first.email, 'x@y.z');
      expect(error.sources.first.category, 'provider');
    });
  });
}