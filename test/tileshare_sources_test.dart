// TileShare redesign Step 9.3 (T9): the data seams the cubits will depend on.
//   * the LIVE adapters delegate 1:1 to the existing APIs (same arguments,
//     same results, errors pass through untouched), and the post-accept
//     follow-up runs analyze THEN buzz;
//   * the test FAKES behave like the real thing (paging, ids, state) and can
//     be told to fail once or to stall, so later tests can observe loading and
//     error states.

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

/// Records what the adapters pass down and returns canned results.
class _FakeClusterApi extends TileShareClusterApi {
  _FakeClusterApi(this.log) : super(getContextCallBack: () => null);

  final List<String> log;
  Object? failWith;
  List<TileShareClusterData> clusterResult = [];
  List<TileShareTemplate> templateResult = [];
  List<DesignatedTile> tileResult = [];
  DesignatedTile? statusResult;

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<TileShareClusterData>> getTileShareClusters(
      {int index = 0, int pageSize = 50, String? clusterId, bool? isOutbox}) async {
    log.add('getTileShareClusters(index: $index, pageSize: $pageSize, '
        'clusterId: $clusterId, isOutbox: $isOutbox)');
    _maybeFail();
    return clusterResult;
  }

  @override
  Future<List<TileShareTemplate>> getTileShareTemplates(
      {String? tileShareTemplateId, String? clusterId, String? Format}) async {
    log.add('getTileShareTemplates(clusterId: $clusterId, '
        'templateId: $tileShareTemplateId)');
    _maybeFail();
    return templateResult;
  }

  @override
  Future deleteCluster(String clusterId) async {
    log.add('deleteCluster($clusterId)');
    _maybeFail();
  }

  @override
  Future<List<DesignatedTile>> getDesignatedTiles(
      {int index = 0, int pageSize = 50, String? clusterId}) async {
    log.add('getDesignatedTiles(index: $index, pageSize: $pageSize, '
        'clusterId: $clusterId)');
    _maybeFail();
    return tileResult;
  }

  @override
  Future<DesignatedTile?> statusUpdate(
      String designatedTileId, InvitationStatus invitationStatus) async {
    log.add('statusUpdate($designatedTileId, ${invitationStatus.name})');
    _maybeFail();
    return statusResult;
  }

  @override
  Future analyzeSchedule({bool injectLocation = false}) async {
    log.add('analyzeSchedule()');
    _maybeFail();
  }
}

class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi(this.log) : super(getContextCallBack: () => null);

  final List<String> log;

  @override
  Future buzzSchedule({bool includeLocationParams = true}) async {
    log.add('buzzSchedule()');
  }
}

class _FakeWhatIfApi extends WhatIfApi {
  _FakeWhatIfApi(this.result) : super(getContextCallBack: () => null);

  final ForecastResponse result;
  Map<String, Object>? received;

  @override
  Future<ForecastResponse> forecastNewTile(Map<String, Object> externalParams) async {
    received = externalParams;
    return result;
  }
}

class _FakeInvitationsApi extends TileShareInvitationsApi {
  _FakeInvitationsApi(this.log) : super(getContextCallBack: () => null);

  final List<String> log;
  Object? failWith;
  TileShareInvitationPage result = const TileShareInvitationPage([]);

  @override
  Future<TileShareInvitationPage> getInvitations(
      {String? clusterId, String? afterId, int pageSize = 50}) async {
    log.add('getInvitations(afterId: $afterId, pageSize: $pageSize, '
        'clusterId: $clusterId)');
    if (failWith != null) throw failWith!;
    return result;
  }
}

class _FakeActivityApi extends TileShareActivityApi {
  _FakeActivityApi(this.log) : super(getContextCallBack: () => null);

  final List<String> log;
  Object? failWith;
  TileShareActivityPage result =
      const TileShareActivityPage(items: [], historyAvailableFrom: 1);

  @override
  Future<TileShareActivityPage> getActivity(
      {String? clusterId,
      String? tiletteId,
      String? cursor,
      int? pageSize,
      String? eventType,
      bool dismissedOnly = false}) async {
    log.add('getActivity(cursor: $cursor, pageSize: $pageSize, '
        'clusterId: $clusterId, eventType: $eventType, '
        'dismissedOnly: $dismissedOnly)');
    if (failWith != null) throw failWith!;
    return result;
  }

  @override
  Future<void> setDismissed(String eventId, bool isDismissed) async {
    log.add('setDismissed($eventId, $isDismissed)');
    if (failWith != null) throw failWith!;
  }
}

void main() {
  group('LiveTileShareAttentionSources delegates 1:1', () {
    late List<String> log;
    late _FakeInvitationsApi invitationsApi;
    late _FakeActivityApi activityApi;
    late LiveTileShareAttentionSources source;

    setUp(() {
      log = <String>[];
      invitationsApi = _FakeInvitationsApi(log);
      activityApi = _FakeActivityApi(log);
      source = LiveTileShareAttentionSources(invitationsApi, activityApi);
    });

    test('invitations passes the cursor and page size through', () async {
      invitationsApi.result = TileShareInvitationPage([tsInvitation('a1', 'c1')], 'a1');
      final page = await source.invitations(afterId: 'a0', pageSize: 20);
      expect(page.items.single.assignmentId, 'a1');
      expect(page.nextCursor, 'a1');
      expect(log.single,
          'getInvitations(afterId: a0, pageSize: 20, clusterId: null)');
    });

    test('activity asks for the non-dismissed feed, with the cursor and size',
        () async {
      activityApi.result = TileShareActivityPage(
          items: [tsActivity('e1', 'assignment_declined')],
          nextCursor: 'n',
          historyAvailableFrom: 1);
      final page = await source.activity(cursor: 'c', pageSize: 30);
      expect(page.items.single.eventId, 'e1');
      expect(page.nextCursor, 'n');
      expect(log.single,
          'getActivity(cursor: c, pageSize: 30, clusterId: null, eventType: null, dismissedOnly: false)');
    });

    test('setDismissed sends the event id and the flag', () async {
      await source.setDismissed('evt-1', true);
      await source.setDismissed('evt-1', false);
      expect(log, ['setDismissed(evt-1, true)', 'setDismissed(evt-1, false)']);
    });

    test('errors pass through unchanged', () async {
      final error = StateError('boom');
      invitationsApi.failWith = error;
      activityApi.failWith = error;
      await expectLater(source.invitations(), throwsA(same(error)));
      await expectLater(source.activity(), throwsA(same(error)));
      await expectLater(source.setDismissed('e', true), throwsA(same(error)));
    });
  });

  group('LiveTileShareClustersSource delegates 1:1', () {
    late List<String> log;
    late _FakeClusterApi api;
    late LiveTileShareClustersSource source;

    setUp(() {
      log = <String>[];
      api = _FakeClusterApi(log);
      source = LiveTileShareClustersSource(api);
    });

    test('clusters passes the paging and the inbox/outbox flag through',
        () async {
      api.clusterResult = [tsCluster('a'), tsCluster('b')];
      final result = await source.clusters(isOutbox: true, index: 20, pageSize: 10);
      expect(result.map((c) => c.id), ['a', 'b']);
      expect(log, [
        'getTileShareClusters(index: 20, pageSize: 10, clusterId: null, isOutbox: true)'
      ]);
    });

    test('clusters defaults match the API defaults', () async {
      await source.clusters(isOutbox: false);
      expect(log.single,
          'getTileShareClusters(index: 0, pageSize: 50, clusterId: null, isOutbox: false)');
    });

    test('cluster(id) asks for that cluster and returns the first, or null',
        () async {
      api.clusterResult = [tsCluster('a')];
      expect((await source.cluster('a'))!.id, 'a');
      expect(log.single,
          'getTileShareClusters(index: 0, pageSize: 50, clusterId: a, isOutbox: null)');
      api.clusterResult = [];
      expect(await source.cluster('missing'), isNull);
    });

    test('tilettes(id) loads the cluster\'s templates', () async {
      api.templateResult = [tsTilette('t1'), tsTilette('t2')];
      final result = await source.tilettes('c1');
      expect(result.map((t) => t.id), ['t1', 't2']);
      expect(log.single, 'getTileShareTemplates(clusterId: c1, templateId: null)');
    });

    test('deleteCluster delegates', () async {
      await source.deleteCluster('c9');
      expect(log, ['deleteCluster(c9)']);
    });

    test('errors pass through unchanged', () async {
      final error = StateError('boom');
      api.failWith = error;
      await expectLater(source.clusters(isOutbox: true), throwsA(same(error)));
      await expectLater(source.tilettes('c1'), throwsA(same(error)));
      await expectLater(source.deleteCluster('c1'), throwsA(same(error)));
    });
  });

  group('LiveTileShareAssignmentsSource delegates 1:1', () {
    late List<String> log;
    late _FakeClusterApi api;
    late LiveTileShareAssignmentsSource source;

    setUp(() {
      log = <String>[];
      api = _FakeClusterApi(log);
      source = LiveTileShareAssignmentsSource(api, _FakeScheduleApi(log));
    });

    test('designatedTiles passes scope and paging through', () async {
      api.tileResult = [tsDesignatedTile('d1')];
      final result =
          await source.designatedTiles(clusterId: 'c1', index: 5, pageSize: 5);
      expect(result.single.id, 'd1');
      expect(log.single, 'getDesignatedTiles(index: 5, pageSize: 5, clusterId: c1)');
    });

    test('respond sends the status and returns the updated tile', () async {
      api.statusResult = tsDesignatedTile('d1', status: InvitationStatus.accepted);
      final updated = await source.respond('d1', InvitationStatus.accepted);
      expect(updated!.id, 'd1');
      expect(log.single, 'statusUpdate(d1, accepted)');
    });

    test('afterAccept re-analyzes the schedule and THEN buzzes it', () async {
      await source.afterAccept();
      expect(log, ['analyzeSchedule()', 'buzzSchedule()']);
    });

    test('afterAccept does not buzz when analysis fails, and rethrows',
        () async {
      final error = StateError('analysis failed');
      api.failWith = error;
      await expectLater(source.afterAccept(), throwsA(same(error)));
      expect(log, ['analyzeSchedule()']);
    });

    test('errors pass through unchanged', () async {
      final error = StateError('boom');
      api.failWith = error;
      await expectLater(
          source.respond('d1', InvitationStatus.declined), throwsA(same(error)));
      await expectLater(source.designatedTiles(), throwsA(same(error)));
    });
  });

  group('LiveTileShareFitSource delegates 1:1', () {
    test('forecast passes the parameters through and returns the response',
        () async {
      final response = tsForecast(viable: true);
      final api = _FakeWhatIfApi(response);
      final source = LiveTileShareFitSource(api);
      final params = <String, Object>{'DurationHours': '2', 'EndDay': '30'};
      expect(await source.forecast(params), same(response));
      expect(api.received, same(params));
    });
  });

  group('the fakes behave like the real sources', () {
    test('clusters pages the right list and keeps the two lists apart',
        () async {
      final fake = FakeTileShareClustersSource(
        outbox: [for (int i = 0; i < 5; i++) tsCluster('o$i')],
        inbox: [tsCluster('i0')],
      );
      expect((await fake.clusters(isOutbox: true, pageSize: 2)).map((c) => c.id),
          ['o0', 'o1']);
      expect(
          (await fake.clusters(isOutbox: true, index: 4, pageSize: 2))
              .map((c) => c.id),
          ['o4']);
      expect(await fake.clusters(isOutbox: true, index: 9), isEmpty);
      expect((await fake.clusters(isOutbox: false)).map((c) => c.id), ['i0']);
    });

    test('cluster / tilettes / deleteCluster act on in-memory state', () async {
      final fake = FakeTileShareClustersSource(
        outbox: [tsCluster('a'), tsCluster('b')],
        tilettesByCluster: {
          'a': [tsTilette('t1', clusterId: 'a')]
        },
      );
      expect((await fake.cluster('a'))!.id, 'a');
      expect(await fake.cluster('zzz'), isNull);
      expect((await fake.tilettes('a')).single.id, 't1');
      expect(await fake.tilettes('b'), isEmpty);
      await fake.deleteCluster('a');
      expect(await fake.cluster('a'), isNull);
      expect(fake.outbox.map((c) => c.id), ['b']);
    });

    test('assignments scope by cluster, page, and respond updates the tile',
        () async {
      final fake = FakeTileShareAssignmentsSource([
        tsDesignatedTile('d1', clusterId: 'c1'),
        tsDesignatedTile('d2', clusterId: 'c1'),
        tsDesignatedTile('d3', clusterId: 'c2'),
      ]);
      expect((await fake.designatedTiles(clusterId: 'c1')).map((t) => t.id),
          ['d1', 'd2']);
      expect((await fake.designatedTiles(pageSize: 2)).length, 2);
      expect((await fake.designatedTiles(index: 2)).map((t) => t.id), ['d3']);
      final updated = await fake.respond('d3', InvitationStatus.accepted);
      expect(updated!.invitationStatus, 'accepted');
      expect(await fake.respond('nope', InvitationStatus.declined), isNull);
      await fake.afterAccept();
      expect(fake.calls.last, 'afterAccept()');
    });

    test('fit returns the configured response and records the call', () async {
      final fake = FakeTileShareFitSource(tsForecast(viable: false, conflicts: 2));
      final r = await fake.forecast({'b': '1', 'a': '2'});
      expect(r.isViable, isFalse);
      expect(r.conflictingCount, 2);
      expect(fake.calls.single, 'forecast(a,b)');
    });

    test('failNext throws exactly once, then the fake recovers', () async {
      final fake = FakeTileShareClustersSource(outbox: [tsCluster('a')]);
      final error = StateError('offline');
      fake.failNext(error);
      await expectLater(fake.clusters(isOutbox: true), throwsA(same(error)));
      expect((await fake.clusters(isOutbox: true)).length, 1);
      expect(fake.calls.length, 2, reason: 'a failed call is still recorded');
    });

    test('hold stalls every call until release, so loading is observable',
        () async {
      final fake = FakeTileShareClustersSource(outbox: [tsCluster('a')]);
      fake.hold();
      bool done = false;
      final pending = fake.clusters(isOutbox: true).then((_) => done = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(done, isFalse, reason: 'still held');
      expect(fake.calls.length, 1, reason: 'the call has started');
      fake.release();
      await pending;
      expect(done, isTrue);
    });

    test('a held call that is then failed throws after the release', () async {
      final fake = FakeTileShareAssignmentsSource();
      final error = StateError('late');
      fake.hold();
      fake.failNext(error);
      final outcome = expectLater(fake.designatedTiles(), throwsA(same(error)));
      fake.release();
      await outcome;
    });
  });
}
