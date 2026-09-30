// TileShare redesign Step 9.7: the Clusters list's cubit (T6, T13, O2).
//   * filter {all, sharedWithMe, createdByMe} over two independently paged
//     sources (created by me / shared with me), merged by deadline;
//   * paging appends and de-dupes; switching filter keeps the loaded pages;
//   * per-card RSVP summary derived from the cluster's tilettes, requested
//     lazily and once per cluster, only for clusters I created;
//   * delete is optimistic and comes back if the server refuses.
// No cluster progress figure exists anywhere in here (T13).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final FakeTileShareClustersSource source;
  final FakeTileShareAssignmentsSource? assignments;
  final TileShareClustersCubit cubit;
  final List<TileShareClustersState> states = <TileShareClustersState>[];
  late final StreamSubscription<TileShareClustersState> _sub;

  _Rig._(this.source, this.assignments, this.cubit) {
    _sub = cubit.stream.listen(states.add);
  }

  factory _Rig({
    List<TileShareClusterData>? outbox,
    List<TileShareClusterData>? inbox,
    Map<String, List<TileShareTemplate>>? tilettes,
    List<DesignatedTile>? mine,
    int pageSize = 50,
  }) {
    final source = FakeTileShareClustersSource(
        outbox: outbox, inbox: inbox, tilettesByCluster: tilettes);
    final assignments =
        mine == null ? null : FakeTileShareAssignmentsSource(mine);
    return _Rig._(
        source,
        assignments,
        TileShareClustersCubit(
            clusters: source, assignments: assignments, pageSize: pageSize));
  }

  TileShareClustersState get state => cubit.state;
  List<String> get ids => state.items.map((i) => i.id).toList();

  int callsStarting(String prefix) =>
      source.calls.where((c) => c.startsWith(prefix)).length;

  Future<void> close() async {
    await _sub.cancel();
    await cubit.close();
  }
}

TileShareClusterData _c(String id, {int? endMs, TileShareMode? mode}) =>
    tsCluster(id, endMs: endMs, mode: mode);

void main() {
  late List<String> logs;
  late void Function(String) originalSink;

  setUp(() {
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() => TileShareLog.sink = originalSink);

  group('loading', () {
    test('starts empty and idle', () async {
      final rig = _Rig();
      expect(rig.state.load, ClustersLoad.initial);
      expect(rig.state.items, isEmpty);
      expect(rig.state.filter, ClusterFilter.all);
      await rig.close();
    });

    test('load shows a loading state, then both sources\' first pages',
        () async {
      final rig = _Rig(
          outbox: [_c('o1', endMs: 100)], inbox: [_c('i1', endMs: 200)]);
      rig.source.hold();
      final loading = rig.cubit.load();
      await pumpEventQueue();
      expect(rig.state.load, ClustersLoad.loading);
      rig.source.release();
      await loading;
      expect(rig.state.load, ClustersLoad.ready);
      expect(rig.ids, ['o1', 'i1']);
      expect(rig.source.calls,
          contains('clusters(isOutbox: true, index: 0, pageSize: 50)'));
      expect(rig.source.calls,
          contains('clusters(isOutbox: false, index: 0, pageSize: 50)'));
      await rig.close();
    });

    test('All merges the two sources by deadline, no deadline last, ties by '
        'id', () async {
      final rig = _Rig(outbox: [
        _c('o-late', endMs: 500),
        _c('o-none'),
        _c('o-tie', endMs: 300),
      ], inbox: [
        _c('i-early', endMs: 100),
        _c('i-tie', endMs: 300),
        _c('i-none'),
      ]);
      await rig.cubit.load();
      expect(rig.ids,
          ['i-early', 'i-tie', 'o-tie', 'o-late', 'i-none', 'o-none']);
      await rig.close();
    });

    test('a cluster listed by both sources appears once, as created by me',
        () async {
      final rig = _Rig(outbox: [_c('same', endMs: 1)], inbox: [_c('same', endMs: 1)]);
      await rig.cubit.load();
      expect(rig.ids, ['same']);
      expect(rig.state.items.single.createdByMe, isTrue);
      await rig.close();
    });

    test('each row knows its mode and whether I created it', () async {
      final rig = _Rig(outbox: [
        _c('o-class', mode: TileShareMode.class_),
        tsCluster('o-legacy-multi', multi: true),
      ], inbox: [
        _c('i-bc', mode: TileShareMode.broadcast),
        tsCluster('i-legacy-single', multi: false),
      ]);
      await rig.cubit.load();
      TileShareMode modeOf(String id) =>
          rig.state.items.firstWhere((i) => i.id == id).mode;
      expect(modeOf('o-class'), TileShareMode.class_);
      expect(modeOf('o-legacy-multi'), TileShareMode.project);
      expect(modeOf('i-bc'), TileShareMode.broadcast);
      expect(modeOf('i-legacy-single'), TileShareMode.broadcast);
      expect(rig.state.items.firstWhere((i) => i.id == 'o-class').createdByMe,
          isTrue);
      expect(rig.state.items.firstWhere((i) => i.id == 'i-bc').createdByMe,
          isFalse);
      await rig.close();
    });

    test('one source failing shows the other and says which failed',
        () async {
      final rig = _Rig(outbox: [_c('o1')], inbox: [_c('i1')]);
      rig.source.failNextOn('clusters(isOutbox: false', StateError('down'));
      await rig.cubit.load();
      expect(rig.state.load, ClustersLoad.ready);
      expect(rig.ids, ['o1']);
      expect(rig.state.failedSources, {ClusterSource.sharedWithMe});
      await rig.cubit.refresh();
      expect(rig.ids, containsAll(['o1', 'i1']));
      expect(rig.state.failedSources, isEmpty);
      await rig.close();
    });

    test('both failing is a ready, empty, fully-failed state (not a crash)',
        () async {
      final rig = _Rig(outbox: [_c('o1')], inbox: [_c('i1')]);
      rig.source.failNextOn('clusters(isOutbox: true', StateError('a'));
      rig.source.failNextOn('clusters(isOutbox: false', StateError('b'));
      await rig.cubit.load();
      expect(rig.state.load, ClustersLoad.ready);
      expect(rig.state.items, isEmpty);
      expect(rig.state.failedSources, ClusterSource.values.toSet());
      await rig.close();
    });

    test('a refresh keeps the rows on screen while it runs, and a source that '
        'fails on it keeps its last rows', () async {
      final rig = _Rig(outbox: [_c('o1', endMs: 1)], inbox: [_c('i1', endMs: 2)]);
      await rig.cubit.load();
      rig.source.hold();
      final refreshing = rig.cubit.refresh();
      await pumpEventQueue();
      expect(rig.state.isRefreshing, isTrue);
      expect(rig.ids, ['o1', 'i1']);
      rig.source.release();
      await refreshing;
      expect(rig.state.isRefreshing, isFalse);

      rig.source.failNextOn('clusters(isOutbox: true', StateError('flaky'));
      await rig.cubit.refresh();
      expect(rig.ids, ['o1', 'i1'], reason: 'last-known rows are kept');
      expect(rig.state.failedSources, {ClusterSource.createdByMe});
      await rig.close();
    });

    test('load after the first load is a refresh', () async {
      final rig = _Rig(outbox: [_c('o1')]);
      await rig.cubit.load();
      await rig.cubit.load();
      expect(rig.state.load, ClustersLoad.ready);
      expect(rig.callsStarting('clusters(isOutbox: true'), 2);
      await rig.close();
    });
  });

  group('filters (T6)', () {
    Future<_Rig> loaded() async {
      final rig = _Rig(
        outbox: [_c('o1', endMs: 200), _c('o2', endMs: 400)],
        inbox: [_c('i1', endMs: 100), _c('i2', endMs: 300)],
      );
      await rig.cubit.load();
      return rig;
    }

    test('Shared with me shows only what others shared, Created by me only '
        'my own', () async {
      final rig = await loaded();
      rig.cubit.setFilter(ClusterFilter.sharedWithMe);
      expect(rig.ids, ['i1', 'i2']);
      rig.cubit.setFilter(ClusterFilter.createdByMe);
      expect(rig.ids, ['o1', 'o2']);
      rig.cubit.setFilter(ClusterFilter.all);
      expect(rig.ids, ['i1', 'o1', 'i2', 'o2']);
      expect(rig.state.filter, ClusterFilter.all);
      await rig.close();
    });

    test('switching filter asks the server for nothing', () async {
      final rig = await loaded();
      final before = rig.source.calls.length;
      rig.cubit.setFilter(ClusterFilter.sharedWithMe);
      rig.cubit.setFilter(ClusterFilter.createdByMe);
      await pumpEventQueue();
      expect(rig.source.calls.length, before);
      await rig.close();
    });

    test('setting the current filter emits nothing', () async {
      final rig = await loaded();
      final emitted = rig.states.length;
      rig.cubit.setFilter(ClusterFilter.all);
      expect(rig.states.length, emitted);
      await rig.close();
    });

    test('a refresh keeps the chosen filter', () async {
      final rig = await loaded();
      rig.cubit.setFilter(ClusterFilter.createdByMe);
      await rig.cubit.refresh();
      expect(rig.state.filter, ClusterFilter.createdByMe);
      expect(rig.ids, ['o1', 'o2']);
      await rig.close();
    });
  });

  group('paging', () {
    Future<_Rig> twoPagesEach() async {
      final rig = _Rig(pageSize: 2, outbox: [
        _c('o1', endMs: 10),
        _c('o2', endMs: 30),
        _c('o3', endMs: 50),
      ], inbox: [
        _c('i1', endMs: 20),
        _c('i2', endMs: 40),
        _c('i3', endMs: 60),
      ]);
      await rig.cubit.load();
      return rig;
    }

    test('a full first page means there may be more; a short one means not',
        () async {
      final rig = _Rig(pageSize: 2, outbox: [_c('o1'), _c('o2')], inbox: [_c('i1')]);
      await rig.cubit.load();
      expect(rig.state.hasMore, isTrue, reason: 'outbox filled its page');
      rig.cubit.setFilter(ClusterFilter.sharedWithMe);
      expect(rig.state.hasMore, isFalse, reason: 'inbox came up short');
      await rig.close();
    });

    test('loadMore reads the next page of each source that has more and '
        're-merges', () async {
      final rig = await twoPagesEach();
      expect(rig.ids, ['o1', 'i1', 'o2', 'i2']);
      await rig.cubit.loadMore();
      expect(rig.ids, ['o1', 'i1', 'o2', 'i2', 'o3', 'i3']);
      expect(rig.source.calls,
          contains('clusters(isOutbox: true, index: 2, pageSize: 2)'));
      expect(rig.source.calls,
          contains('clusters(isOutbox: false, index: 2, pageSize: 2)'));
      expect(rig.state.hasMore, isFalse);
      await rig.close();
    });

    test('under a filter only that source is paged', () async {
      final rig = await twoPagesEach();
      rig.cubit.setFilter(ClusterFilter.createdByMe);
      await rig.cubit.loadMore();
      expect(rig.callsStarting('clusters(isOutbox: true, index: 2'), 1);
      expect(rig.callsStarting('clusters(isOutbox: false, index: 2'), 0);
      expect(rig.ids, ['o1', 'o2', 'o3']);
      await rig.close();
    });

    test('a page that overlaps what is loaded adds nothing twice', () async {
      final rig = _Rig(pageSize: 2, outbox: [_c('o1'), _c('o2')]);
      await rig.cubit.load();
      // the list shifted on the server: next page repeats o2
      rig.source.outbox
        ..clear()
        ..addAll([_c('o0'), _c('o1'), _c('o2'), _c('o3')]);
      await rig.cubit.loadMore();
      expect(rig.ids.where((id) => id == 'o2'), hasLength(1));
      expect(rig.ids, containsAll(['o1', 'o2', 'o3']));
      await rig.close();
    });

    test('loadMore with nothing more asks for nothing', () async {
      final rig = _Rig(pageSize: 5, outbox: [_c('o1')], inbox: [_c('i1')]);
      await rig.cubit.load();
      final before = rig.source.calls.length;
      await rig.cubit.loadMore();
      expect(rig.source.calls.length, before);
      await rig.close();
    });

    test('overlapping loadMore calls make one request per source', () async {
      final rig = await twoPagesEach();
      rig.source.hold();
      final a = rig.cubit.loadMore();
      final b = rig.cubit.loadMore();
      await pumpEventQueue();
      expect(rig.state.isLoadingMore, isTrue);
      rig.source.release();
      await Future.wait([a, b]);
      expect(rig.callsStarting('clusters(isOutbox: true, index: 2'), 1);
      expect(rig.state.isLoadingMore, isFalse);
      await rig.close();
    });

    test('a failed page keeps the rows, says so, and can be retried',
        () async {
      final rig = await twoPagesEach();
      rig.source.failNextOn('clusters(isOutbox: true, index: 2', StateError('x'));
      await rig.cubit.loadMore();
      expect(rig.state.loadMoreFailed, isTrue);
      expect(rig.ids, containsAll(['o1', 'i1', 'o2', 'i2']));
      expect(rig.state.hasMore, isTrue, reason: 'still more to read');
      await rig.cubit.loadMore();
      expect(rig.state.loadMoreFailed, isFalse);
      expect(rig.ids, contains('o3'));
      await rig.close();
    });

    test('filter switching keeps every loaded page', () async {
      final rig = await twoPagesEach();
      await rig.cubit.loadMore();
      final before = rig.source.calls.length;
      rig.cubit.setFilter(ClusterFilter.createdByMe);
      expect(rig.ids, ['o1', 'o2', 'o3']);
      rig.cubit.setFilter(ClusterFilter.sharedWithMe);
      expect(rig.ids, ['i1', 'i2', 'i3']);
      expect(rig.source.calls.length, before);
      await rig.close();
    });

    test('a refresh restarts paging from the first page', () async {
      final rig = await twoPagesEach();
      await rig.cubit.loadMore();
      await rig.cubit.refresh();
      expect(rig.ids, ['o1', 'i1', 'o2', 'i2']);
      expect(rig.state.hasMore, isTrue);
      await rig.close();
    });
  });

  group('my own answer on clusters shared with me (9.8)', () {
    test('a cluster shared with me carries my status and task count; one I '
        'created does not', () async {
      final rig = _Rig(
        outbox: [_c('o1')],
        inbox: [_c('i1', mode: TileShareMode.class_)],
        mine: [
          tsDesignatedTile('a', clusterId: 'i1', status: InvitationStatus.accepted),
          tsDesignatedTile('b', clusterId: 'i1'),
          tsDesignatedTile('c', clusterId: 'i1'),
        ],
      );
      await rig.cubit.load();
      final shared = rig.state.items.firstWhere((i) => i.id == 'i1');
      expect(shared.mine!.taskCount, 3);
      expect(shared.mine!.pending, 2);
      expect(shared.mine!.needsAnswer, isTrue);
      expect(rig.state.items.firstWhere((i) => i.id == 'o1').mine, isNull);
      await rig.close();
    });

    test('a shared cluster I hold no task in has no status yet (not '
        'invented)', () async {
      final rig = _Rig(inbox: [_c('i1')], mine: []);
      await rig.cubit.load();
      expect(rig.state.items.single.mine, isNull);
      await rig.close();
    });

    test('without an assignments source nothing is asked and no status is '
        'shown', () async {
      final rig = _Rig(inbox: [_c('i1')]);
      await rig.cubit.load();
      expect(rig.state.items.single.mine, isNull);
      await rig.close();
    });

    test('my assignments are read in the same load, in pages', () async {
      final rig = _Rig(
        pageSize: 2,
        inbox: [_c('i1')],
        mine: [
          tsDesignatedTile('a', clusterId: 'i1'),
          tsDesignatedTile('b', clusterId: 'i1'),
          tsDesignatedTile('c', clusterId: 'i1'),
        ],
      );
      await rig.cubit.load();
      expect(rig.state.items.single.mine!.taskCount, 3);
      expect(rig.assignments!.calls, [
        'designatedTiles(clusterId: null, index: 0, pageSize: 2)',
        'designatedTiles(clusterId: null, index: 2, pageSize: 2)'
      ]);
      await rig.close();
    });

    test('failing to read them never blocks the rows, is logged, and a '
        'refresh keeps what was known', () async {
      final rig = _Rig(
        inbox: [_c('i1')],
        mine: [tsDesignatedTile('a', clusterId: 'i1')],
      );
      await rig.cubit.load();
      expect(rig.state.items.single.mine, isNotNull);

      rig.assignments!.failNext(StateError('tiles down'));
      await rig.cubit.refresh();
      expect(rig.ids, ['i1']);
      expect(rig.state.items.single.mine, isNotNull,
          reason: 'last-known status is kept');
      expect(logs.any((l) => l.contains('tiles down')), isTrue,
          reason: '$logs');
      await rig.close();
    });

    test('the first load failing leaves the rows without a status', () async {
      final rig = _Rig(
          inbox: [_c('i1')], mine: [tsDesignatedTile('a', clusterId: 'i1')]);
      rig.assignments!.failNext(StateError('tiles down'));
      await rig.cubit.load();
      expect(rig.ids, ['i1']);
      expect(rig.state.items.single.mine, isNull);
      await rig.close();
    });

    test('the load line counts my assignments', () async {
      final rig = _Rig(
          inbox: [_c('i1')], mine: [tsDesignatedTile('a', clusterId: 'i1')]);
      await rig.cubit.load();
      final line =
          logs.firstWhere((l) => l.contains('loaded'), orElse: () => '');
      expect(line, contains('mine=1'));
      await rig.close();
    });
  });

  group('RSVP summary (O2, T13)', () {
    TileShareClusterData mine(String id, TileShareMode mode) =>
        _c(id, mode: mode);

    test('is asked for once per cluster, derived from its tilettes, and '
        'shown on the row', () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.broadcast)], tilettes: {
        'o1': [
          tsTilette('t1', clusterId: 'o1', assignees: [
            tsAssignee('a@x.com', status: InvitationStatus.accepted),
            tsAssignee('b@x.com', status: InvitationStatus.declined),
            tsAssignee('c@x.com'),
          ]),
        ],
      });
      await rig.cubit.load();
      expect(rig.state.items.single.rsvp, isNull, reason: 'not asked yet');
      await rig.cubit.ensureSummary('o1');
      await rig.cubit.ensureSummary('o1');
      final rsvp = rig.state.items.single.rsvp!;
      expect([rsvp.total, rsvp.accepted, rsvp.declined, rsvp.pending],
          [3, 1, 1, 1]);
      expect(rig.callsStarting('tilettes(o1)'), 1);
      await rig.close();
    });

    test('overlapping requests for the same cluster share one fetch',
        () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.broadcast)]);
      await rig.cubit.load();
      rig.source.hold();
      final a = rig.cubit.ensureSummary('o1');
      final b = rig.cubit.ensureSummary('o1');
      await pumpEventQueue();
      rig.source.release();
      await Future.wait([a, b]);
      expect(rig.callsStarting('tilettes(o1)'), 1);
      await rig.close();
    });

    test('the counting rule follows the mode: a Class counts people, not '
        'assignments', () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.class_)], tilettes: {
        'o1': [
          tsTilette('t1', clusterId: 'o1', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
          ]),
          tsTilette('t2', clusterId: 'o1', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
          ]),
        ],
      });
      await rig.cubit.load();
      await rig.cubit.ensureSummary('o1');
      final rsvp = rig.state.items.single.rsvp!;
      expect([rsvp.total, rsvp.accepted], [1, 1]);
      await rig.close();
    });

    test('a Project counts tilettes', () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.project)], tilettes: {
        'o1': [
          tsTilette('t1', clusterId: 'o1', assignees: [
            tsAssignee('a@x.com', status: InvitationStatus.accepted),
          ]),
          tsTilette('t2', clusterId: 'o1', assignees: [
            tsAssignee('b@x.com'),
          ]),
        ],
      });
      await rig.cubit.load();
      await rig.cubit.ensureSummary('o1');
      final rsvp = rig.state.items.single.rsvp!;
      expect([rsvp.total, rsvp.accepted, rsvp.pending], [2, 1, 1]);
      await rig.close();
    });

    test('only clusters I created get a summary; a shared one is never '
        'asked', () async {
      final rig = _Rig(inbox: [_c('i1')]);
      await rig.cubit.load();
      await rig.cubit.ensureSummary('i1');
      await rig.cubit.ensureSummary('nope');
      expect(rig.callsStarting('tilettes('), 0);
      expect(rig.state.items.single.rsvp, isNull);
      expect(rig.state.items.single.rsvpFailed, isFalse);
      await rig.close();
    });

    test('a failed fetch leaves the row in place, marked, and is not retried '
        'on its own', () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.broadcast)], tilettes: {
        'o1': [
          tsTilette('t1', clusterId: 'o1', assignees: [
            tsAssignee('a@x.com', status: InvitationStatus.accepted),
          ]),
        ],
      });
      await rig.cubit.load();
      rig.source.failNextOn('tilettes(o1)', StateError('no roster'));
      await rig.cubit.ensureSummary('o1');
      expect(rig.ids, ['o1']);
      expect(rig.state.items.single.rsvp, isNull);
      expect(rig.state.items.single.rsvpFailed, isTrue);
      await rig.cubit.ensureSummary('o1');
      expect(rig.callsStarting('tilettes(o1)'), 1, reason: 'no hammering');

      await rig.cubit.retrySummary('o1');
      expect(rig.state.items.single.rsvpFailed, isFalse);
      expect(rig.state.items.single.rsvp!.accepted, 1);
      await rig.close();
    });

    test('a refresh keeps the shown counts, and the next request replaces '
        'them', () async {
      final rig = _Rig(outbox: [mine('o1', TileShareMode.broadcast)], tilettes: {
        'o1': [
          tsTilette('t1', clusterId: 'o1', assignees: [tsAssignee('a@x.com')]),
        ],
      });
      await rig.cubit.load();
      await rig.cubit.ensureSummary('o1');
      expect(rig.state.items.single.rsvp!.accepted, 0);

      rig.source.tilettesByCluster['o1'] = [
        tsTilette('t1', clusterId: 'o1', assignees: [
          tsAssignee('a@x.com', status: InvitationStatus.accepted),
        ]),
      ];
      await rig.cubit.refresh();
      expect(rig.state.items.single.rsvp!.accepted, 0,
          reason: 'old counts stay until replaced (no flash)');
      await rig.cubit.ensureSummary('o1');
      expect(rig.state.items.single.rsvp!.accepted, 1);
      expect(rig.callsStarting('tilettes(o1)'), 2);
      await rig.close();
    });

    test('there is no progress figure on a row', () async {
      // Structural guard for T13: the row exposes RSVP status only.
      final rig = _Rig(outbox: [_c('o1')]);
      await rig.cubit.load();
      final row = rig.state.items.single;
      expect(row.toString().toLowerCase(), isNot(contains('progress')));
      expect(row.toString().toLowerCase(), isNot(contains('percent')));
      await rig.close();
    });
  });

  group('delete', () {
    test('hides the row at once, asks the server once, and stays gone',
        () async {
      final rig = _Rig(outbox: [_c('o1', endMs: 1), _c('o2', endMs: 2)]);
      await rig.cubit.load();
      rig.source.hold();
      final deleting = rig.cubit.delete('o1');
      await pumpEventQueue();
      expect(rig.ids, ['o2'], reason: 'optimistic');
      rig.source.release();
      expect(await deleting, isTrue);
      expect(rig.ids, ['o2']);
      expect(rig.callsStarting('deleteCluster(o1)'), 1);
      await rig.cubit.refresh();
      expect(rig.ids, ['o2']);
      await rig.close();
    });

    test('a refusal puts the row back where it belongs and says so',
        () async {
      final rig = _Rig(outbox: [_c('o1', endMs: 1), _c('o2', endMs: 2)]);
      await rig.cubit.load();
      rig.source.failNextOn('deleteCluster', StateError('refused'));
      expect(await rig.cubit.delete('o1'), isFalse);
      expect(rig.ids, ['o1', 'o2']);
      expect(rig.state.deleteFailure?.clusterId, 'o1');
      expect(rig.state.deleteFailure?.name, 'Cluster o1',
          reason: 'so the message can say which one came back');
      rig.cubit.acknowledgeFailure();
      expect(rig.state.deleteFailure, isNull);
      await rig.close();
    });

    test('a refresh while the delete is in flight does not bring the row '
        'back; a refusal afterwards does', () async {
      final rig = _Rig(outbox: [_c('o1', endMs: 1), _c('o2', endMs: 2)]);
      await rig.cubit.load();
      rig.source.failNextOn('deleteCluster', StateError('refused'));
      rig.source.hold();
      final deleting = rig.cubit.delete('o1');
      await pumpEventQueue();
      final refreshing = rig.cubit.refresh();
      await pumpEventQueue();
      rig.source.release();
      await Future.wait([deleting, refreshing]);
      expect(rig.ids, ['o1', 'o2'], reason: 'the server refused');
      await rig.close();
    });

    test('only clusters I created can be deleted; others and unknown ids do '
        'nothing', () async {
      final rig = _Rig(outbox: [_c('o1')], inbox: [_c('i1')]);
      await rig.cubit.load();
      expect(await rig.cubit.delete('i1'), isFalse);
      expect(await rig.cubit.delete('ghost'), isFalse);
      expect(rig.callsStarting('deleteCluster'), 0);
      expect(rig.ids, containsAll(['o1', 'i1']));
      await rig.close();
    });

    test('deleting the same cluster twice sends one request', () async {
      final rig = _Rig(outbox: [_c('o1')]);
      await rig.cubit.load();
      rig.source.hold();
      final first = rig.cubit.delete('o1');
      final second = rig.cubit.delete('o1');
      await pumpEventQueue();
      rig.source.release();
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(rig.callsStarting('deleteCluster(o1)'), 1);
      await rig.close();
    });
  });

  group('logging for diagnosis', () {
    test('a load says how many clusters each source gave and which failed',
        () async {
      final rig = _Rig(outbox: [_c('o1')], inbox: [_c('i1'), _c('i2')]);
      rig.source.failNextOn('clusters(isOutbox: true', StateError('broken'));
      await rig.cubit.load();
      final line = logs.firstWhere((l) => l.contains('loaded'), orElse: () => '');
      expect(line, contains('TileShareClusters'));
      expect(line, contains('created=0'));
      expect(line, contains('shared=2'));
      expect(line, contains('failed: createdByMe'));
      expect(logs.any((l) => l.contains('broken')), isTrue, reason: '$logs');
      await rig.close();
    });

    test('a refused delete and a failed summary are logged with their ids '
        'and errors', () async {
      final rig = _Rig(outbox: [_c('o1', mode: TileShareMode.broadcast)]);
      await rig.cubit.load();
      rig.source.failNextOn('deleteCluster', StateError('nope'));
      await rig.cubit.delete('o1');
      expect(logs.any((l) => l.contains('o1') && l.contains('nope')), isTrue,
          reason: '$logs');
      rig.source.failNextOn('tilettes(o1)', StateError('no roster'));
      await rig.cubit.ensureSummary('o1');
      expect(logs.any((l) => l.contains('o1') && l.contains('no roster')),
          isTrue,
          reason: '$logs');
      await rig.close();
    });
  });
}
