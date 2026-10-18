import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/services/calendarSearchController.dart';

class PendingSearch {
  PendingSearch(this.query, this.sources, this.batchSize, this.index,
      this.start, this.end);
  final String query;
  final List<String>? sources;
  final int? batchSize, index, start, end;
  final response = Completer<CalendarSearchResult>();
}

class SearchHarness {
  final requests = <PendingSearch>[];
  Future<CalendarSearchResult> load(String query,
      {List<String>? sources,
      int? batchSize,
      int? index,
      int? start,
      int? end}) {
    final request = PendingSearch(query, sources, batchSize, index, start, end);
    requests.add(request);
    return request.response.future;
  }
}

CalendarSearchItem item(String id,
        {String source = 'tiler',
        String? providerId,
        String? account,
        int start = 0}) =>
    CalendarSearchItem(
      id: id,
      name: id,
      start: start,
      end: start + 1,
      source: source,
      sourceKind: parseCalendarSearchSource(source),
      isReadOnly: false,
      capabilities: const CalendarSearchCapabilities(),
      thirdPartyEventId: providerId,
      thirdPartyUserId: account,
    );

CalendarSearchResult page(List<CalendarSearchItem> items,
        {int? nextIndex,
        int? totalCount,
        List<CalendarSearchSourceStatus> sources = const []}) =>
    CalendarSearchResult.success(CalendarSearchEnvelope(
        items: items,
        sources: sources,
        correlationId: 'test',
        hasMore: nextIndex != null,
        nextIndex: nextIndex,
        totalCount: totalCount));

void main() {
  late SearchHarness harness;
  late CalendarSearchController controller;
  setUp(() {
    harness = SearchHarness();
    controller = CalendarSearchController(loader: harness.load);
  });
  tearDown(() => controller.dispose());

  test(
      'uses server continuation and forwards the same source/window on every batch',
      () async {
    final first =
        controller.search('coffee', sources: ['google'], start: 0, end: 2000);
    expect(controller.isLoading, isTrue);
    final request = harness.requests.single;
    expect([request.batchSize, request.index, request.start, request.end],
        [10, 0, 0, 2000]);
    request.response
        .complete(page([item('first')], nextIndex: 7, totalCount: 2));
    await first;
    final next = controller.loadMore();
    final batch = harness.requests.last;
    expect(batch.sources, ['google']);
    expect([batch.batchSize, batch.index, batch.start, batch.end],
        [10, 7, 0, 2000]);
    batch.response.complete(page([item('second')], totalCount: 2));
    await next;
    expect(controller.items.map((e) => e.id), ['first', 'second']);
    expect(controller.totalCount, 2);
    expect(controller.hasMore, isFalse);
    await controller.loadMore();
    expect(harness.requests, hasLength(2));
  });

  test(
      'deduplicates batches without collapsing provider accounts or occurrences',
      () async {
    final first = controller.search('coffee');
    final a =
        item('external', source: 'google', providerId: 'event', account: 'a');
    harness.requests.last.response
        .complete(page([item('native'), a], nextIndex: 2));
    await first;
    final next = controller.loadMore();
    harness.requests.last.response.complete(page([
      item('native'),
      a,
      item('external', source: 'google', providerId: 'event', account: 'b'),
      item('external',
          source: 'google', providerId: 'event', account: 'a', start: 1000)
    ]));
    await next;
    expect(controller.items, hasLength(4));
  });

  testWidgets('debounces typing and rejects an earlier response immediately',
      (tester) async {
    final first = controller.search('older');
    controller.scheduleSearch('newer');
    harness.requests.first.response.complete(page([item('stale')]));
    await first;
    expect(controller.items, isEmpty);
    await tester.pump(const Duration(milliseconds: 299));
    expect(harness.requests, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(harness.requests.last.query, 'newer');
    harness.requests.last.response.complete(page([item('current')]));
    await tester.pump();
    expect(controller.items.single.id, 'current');
  });

  test(
      'clearing or shortening a query invalidates pending requests and loading',
      () async {
    for (final text in ['', '   ', 'a']) {
      final first = controller.search('coffee');
      final pending = harness.requests.last;
      await controller.search(text);
      pending.response.complete(page([item('stale')]));
      await first;
      expect(controller.items, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.isLoadingMore, isFalse);
      expect(controller.showNoMatches, isFalse);
    }
  });

  test(
      'filter and timeline changes reset offset and discard the old pending batch',
      () async {
    final first =
        controller.search('coffee', sources: ['google'], start: 0, end: 1000);
    harness.requests.last.response
        .complete(page([item('first')], nextIndex: 1));
    await first;
    final oldBatch = controller.loadMore();
    final stale = harness.requests.last;
    final newQuery = controller.search('coffee',
        sources: ['microsoft'], start: 1000, end: 2000);
    final latest = harness.requests.last;
    expect(latest.index, 0);
    expect(latest.sources, ['microsoft']);
    expect([latest.start, latest.end], [1000, 2000]);
    latest.response.complete(page([item('new')]));
    await newQuery;
    stale.response.complete(page([item('old')]));
    await oldBatch;
    expect(controller.items.single.id, 'new');
  });

  test('a failed batch keeps existing results and retries the same offset',
      () async {
    final first = controller.search('coffee');
    harness.requests.last.response
        .complete(page([item('first')], nextIndex: 7));
    await first;
    final batch = controller.loadMore();
    await controller
        .loadMore(); // duplicate taps must not issue another request
    expect(harness.requests, hasLength(2));
    harness.requests.last.response.completeError(Exception('network'));
    await batch;
    expect(controller.hasError, isTrue);
    expect(controller.items.single.id, 'first');
    expect(controller.nextIndex, 7);
    final retry = controller.loadMore();
    expect(harness.requests.last.index, 7);
    harness.requests.last.response.complete(page([item('second')]));
    await retry;
    expect(controller.items, hasLength(2));
    expect(controller.hasError, isFalse);
  });

  test('404 and typed 502 failures never become no matches', () async {
    for (final result in [
      parseCalendarSearchResponse(404, ''),
      CalendarSearchResult.unavailable(const CalendarSearchUnavailableError())
    ]) {
      final search = controller.search('coffee');
      harness.requests.last.response.complete(result);
      await search;
      expect(controller.hasError, isTrue);
      expect(controller.showNoMatches, isFalse);
    }
  });

  test(
      'empty partial results keep source failures visible instead of no matches',
      () async {
    final search = controller.search('coffee');
    harness.requests.last.response.complete(page([], sources: [
      CalendarSearchSourceStatus.fromJson({
        'source': 'google',
        'status': 'failed',
        'category': 'timeout',
        'retryable': true,
      })
    ]));
    await search;
    expect(controller.hasPartialFailure, isTrue);
    expect(controller.showNoMatches, isFalse);
  });

  test(
      'a successful empty result is no matches and missing metadata cannot load more',
      () async {
    final search = controller.search('coffee');
    harness.requests.last.response.complete(page([]));
    await search;
    expect(controller.showNoMatches, isTrue);
    expect(controller.hasMore, isFalse);
  });

  test('dismissing a pending search ignores its eventual completion', () async {
    final search = controller.search('coffee');
    controller.cancelPending();
    harness.requests.last.response.complete(page([item('stale')]));
    await search;
    expect(controller.items, isEmpty);
    expect(controller.isLoading, isFalse);
  });

  test('disposing during a request never notifies the disposed listener',
      () async {
    final local = CalendarSearchController(loader: harness.load);
    int notifications = 0;
    local.addListener(() => notifications++);
    final search = local.search('coffee');
    local.dispose();
    harness.requests.last.response.complete(page([item('late')]));
    await search;
    expect(notifications, 1);
  });
}
