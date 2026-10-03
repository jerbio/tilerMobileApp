// TileShare redesign Step 9.12 (T10): one detail scaffold, whatever the mode.
// The cubit behind it opens a cluster from any of the three entry points (its
// id, one of its designated tile templates, or data already in hand), loads
// its tilettes and the signed-in user's own templates in it, decides the
// variant by mode and role, and reloads without throwing away what is shown.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final FakeTileShareClustersSource clusters;
  final FakeTileShareAssignmentsSource assignments;
  late final TileShareDetailCubit cubit;
  final List<TileShareDetailState> states = [];
  late final StreamSubscription<TileShareDetailState> _sub;

  _Rig(
    TileShareDetailTarget target, {
    FakeTileShareClustersSource? clusters,
    List<DesignatedTile>? mine,
    String? me = 'me',
    bool? ownerHint,
  })  : clusters = clusters ?? _clusters(),
        assignments = FakeTileShareAssignmentsSource(mine ?? _mine()) {
    cubit = TileShareDetailCubit(
      clusters: this.clusters,
      assignments: assignments,
      target: target,
      currentUserId: () => me,
      ownerHint: ownerHint,
    );
    _sub = cubit.stream.listen(states.add);
  }

  TileShareDetailState get state => cubit.state;

  Future<void> close() async {
    await _sub.cancel();
    await cubit.close();
  }
}

FakeTileShareClustersSource _clusters() => FakeTileShareClustersSource(
      inbox: [
        tsCluster('shared', mode: TileShareMode.class_, creatorId: 'sarah'),
      ],
      outbox: [
        tsCluster('mine-b', mode: TileShareMode.broadcast, creatorId: 'me'),
        tsCluster('mine-p', mode: TileShareMode.project, creatorId: 'me'),
        tsCluster('legacy', multi: true, creatorId: 'me'),
      ],
      tilettesByCluster: {
        'shared': [
          tsTilette('t1', clusterId: 'shared'),
          tsTilette('t2', clusterId: 'shared'),
        ],
        'mine-b': [tsTilette('t3', clusterId: 'mine-b')],
      },
    );

List<DesignatedTile> _mine() => [
      tsDesignatedTile('d1', clusterId: 'shared'),
      tsDesignatedTile('d2', clusterId: 'shared'),
      tsDesignatedTile('d-other', clusterId: 'shared', ownerId: 'someone'),
    ];

void main() {
  late List<String> logs;
  late void Function(String) originalSink;
  setUp(() {
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() => TileShareLog.sink = originalSink);

  group('opening', () {
    test('by cluster id: loading, then the cluster, its tilettes and my own '
        'templates in it', () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      final done = rig.cubit.load();
      expect(rig.state.phase, DetailPhase.loading);
      await done;
      final s = rig.state;
      expect(s.phase, DetailPhase.ready);
      expect(s.cluster!.id, 'shared');
      expect(s.tilettes.map((t) => t.id), ['t1', 't2']);
      expect(s.mine.map((t) => t.id), ['d1', 'd2'],
          reason: 'a template designated to someone else is not mine');
      expect(rig.assignments.calls.single, contains('clusterId: shared'));
      await rig.close();
    });

    test('by designated tile template: its cluster is looked up first',
        () async {
      final rig = _Rig(const TileShareDetailTarget.designatedTile('d1'));
      await rig.cubit.load();
      expect(rig.assignments.calls.first, 'designatedTile(d1)');
      expect(rig.state.phase, DetailPhase.ready);
      expect(rig.state.cluster!.id, 'shared');
      await rig.close();
    });

    test('an unknown designated tile template is not found', () async {
      final rig = _Rig(const TileShareDetailTarget.designatedTile('nope'));
      await rig.cubit.load();
      expect(rig.state.phase, DetailPhase.notFound);
      expect(rig.clusters.calls, isEmpty);
      await rig.close();
    });

    test('with data in hand: shown at once, then brought up to date',
        () async {
      final rig = _Rig(TileShareDetailTarget.data(
          tsCluster('shared', name: 'Old name', creatorId: 'sarah')));
      expect(rig.state.phase, DetailPhase.ready,
          reason: 'nothing to wait for');
      expect(rig.state.cluster!.name, 'Old name');
      await rig.cubit.load();
      expect(rig.states.any((s) => s.phase == DetailPhase.loading), isFalse,
          reason: 'what is shown is never replaced by a spinner');
      expect(rig.state.cluster!.name, 'Cluster shared');
      expect(rig.state.tilettes, hasLength(2));
      await rig.close();
    });

    test('a cluster that is gone is not found', () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('gone'));
      await rig.cubit.load();
      expect(rig.state.phase, DetailPhase.notFound);
      await rig.close();
    });

    test('a failure is an error; Retry loads it', () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      rig.clusters.failNextOn('cluster', StateError('offline'));
      await rig.cubit.load();
      expect(rig.state.phase, DetailPhase.error);
      expect(logs.any((l) => l.contains('offline')), isTrue);
      await rig.cubit.load();
      expect(rig.state.phase, DetailPhase.ready);
      await rig.close();
    });

    test('tilettes that fail to load leave the cluster showing, flagged',
        () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      rig.clusters.failNextOn('tilettes', StateError('tilettes down'));
      await rig.cubit.load();
      expect(rig.state.phase, DetailPhase.ready);
      expect(rig.state.tilettesFailed, isTrue);
      await rig.cubit.refresh();
      expect(rig.state.tilettesFailed, isFalse);
      expect(rig.state.tilettes, hasLength(2));
      await rig.close();
    });
  });

  group('refreshing', () {
    test('keeps what is shown, says it is refreshing, never a spinner',
        () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      await rig.cubit.load();
      rig.states.clear();
      rig.clusters.hold();
      final done = rig.cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(rig.state.phase, DetailPhase.ready);
      expect(rig.state.isRefreshing, isTrue);
      expect(rig.state.cluster, isNotNull);
      rig.clusters.release();
      await done;
      expect(rig.state.isRefreshing, isFalse);
      expect(rig.states.any((s) => s.phase != DetailPhase.ready), isFalse);
      await rig.close();
    });

    test('a failed refresh keeps the content and says so', () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      await rig.cubit.load();
      rig.clusters.failNextOn('cluster', StateError('flaky'));
      await rig.cubit.refresh();
      expect(rig.state.phase, DetailPhase.ready);
      expect(rig.state.refreshFailed, isTrue);
      expect(rig.state.cluster!.id, 'shared');
      await rig.cubit.refresh();
      expect(rig.state.refreshFailed, isFalse);
      await rig.close();
    });

    test('a response after the cubit closed is dropped', () async {
      final rig = _Rig(const TileShareDetailTarget.cluster('shared'));
      rig.clusters.hold();
      final done = rig.cubit.load();
      await rig.close();
      rig.clusters.release();
      await done;
    });
  });

  group('which detail', () {
    Future<TileShareDetailState> open(String id,
        {String? me = 'me', bool? ownerHint}) async {
      final rig = _Rig(TileShareDetailTarget.cluster(id),
          me: me, ownerHint: ownerHint);
      await rig.cubit.load();
      final s = rig.state;
      await rig.close();
      return s;
    }

    test('the owner sees the detail of the mode', () async {
      expect((await open('mine-b')).variant, DetailVariant.broadcast);
      expect((await open('mine-p')).variant, DetailVariant.project);
      expect((await open('legacy')).variant, DetailVariant.project,
          reason: 'a cluster without a mode falls back to the legacy mapping');
    });

    test('a recipient sees the commitment, whatever the mode', () async {
      final s = await open('shared');
      expect(s.isOwner, isFalse);
      expect(s.variant, DetailVariant.commitment);
    });

    test('the owner is the cluster\'s creator, by id', () async {
      expect((await open('mine-b')).isOwner, isTrue);
      expect((await open('shared', me: 'sarah')).isOwner, isTrue);
    });

    test('without a signed-in user the caller\'s hint decides', () async {
      expect((await open('shared', me: null, ownerHint: true)).isOwner, isTrue);
      expect((await open('mine-b', me: null, ownerHint: false)).isOwner,
          isFalse);
      expect((await open('mine-b', me: null)).isOwner, isFalse,
          reason: 'with no hint, never assume ownership');
      expect((await open('shared', me: null)).mine, isEmpty,
          reason: 'nothing is mine without a signed-in user');
    });
  });
}
