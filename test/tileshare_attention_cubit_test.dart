// TileShare redesign Step 9.4 (T7, T9): the Attention cubit.
//   * loads Invitations, the activity feed and my received tiles IN PARALLEL
//     and derives the inbox; one source failing never hides the others;
//   * a refresh keeps the list on screen (no empty flash) and keeps a failed
//     source's last-known data;
//   * dismissing an activity item is OPTIMISTIC, sent to the server per event,
//     rolled back on failure and undoable; a dismissal is remembered by the
//     server, so a reload / a new session still hides it;
//   * an invitation the user answered disappears locally (the response itself
//     is Step 9.6);
//   * each cluster's mode is resolved once and cached (the Invitations
//     endpoint does not carry it).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareMode.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final FakeTileShareAttentionSources attention;
  final FakeTileShareAssignmentsSource assignments;
  final FakeTileShareClustersSource clusters;
  String? userId = 'me';
  late final TileShareAttentionCubit cubit;

  _Rig({
    FakeTileShareAttentionSources? attention,
    FakeTileShareAssignmentsSource? assignments,
    FakeTileShareClustersSource? clusters,
  })  : attention = attention ?? _standardAttention(),
        assignments = assignments ?? _standardAssignments(),
        clusters = clusters ?? _standardClusters() {
    cubit = TileShareAttentionCubit(
      attention: this.attention,
      assignments: this.assignments,
      clusters: this.clusters,
      currentUserId: () => userId,
      clock: () => kTileShareNow,
    );
  }

  Future<void> close() => cubit.close();
}

FakeTileShareAttentionSources _standardAttention() =>
    FakeTileShareAttentionSources(
      invitations: [
        tsInvitation('a1', 'c-class',
            deadlineMs: tileShareMsFromNow(const Duration(days: 5)))
      ],
      activity: [
        tsActivity('e1', 'assignment_declined', cluster: 'c-own', atMsFromNow: -1000),
      ],
    );

FakeTileShareAssignmentsSource _standardAssignments() =>
    FakeTileShareAssignmentsSource([
      tsDesignatedTile('d1',
          clusterId: 'c-risk', status: InvitationStatus.accepted, viable: false),
    ]);

FakeTileShareClustersSource _standardClusters() => FakeTileShareClustersSource(
      inbox: [
        tsCluster('c-class', mode: TileShareMode.class_),
        tsCluster('c-risk', mode: TileShareMode.project),
      ],
      outbox: [tsCluster('c-own', mode: TileShareMode.broadcast)],
    );

Iterable<String> _ids(TileShareAttentionState s) => s.items.map((i) => i.id);

void main() {
  group('first load', () {
    test('derives the inbox from all three sources, in urgency order', () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(rig.cubit.state.load, AttentionLoad.ready);
      expect(_ids(rig.cubit.state),
          ['invitation:c-class', 'atRisk:c-risk', 'declined:c-own']);
      expect(rig.cubit.state.failedSources, isEmpty);
      await rig.close();
    });

    test('shows a loading state (no items) first, then ready', () async {
      final rig = _Rig();
      final states = <TileShareAttentionState>[];
      final sub = rig.cubit.stream.listen(states.add);
      await rig.cubit.load();
      await sub.cancel();
      expect(states.first.load, AttentionLoad.loading);
      expect(states.first.items, isEmpty);
      expect(states.last.load, AttentionLoad.ready);
      await rig.close();
    });

    test('the three sources are requested together, not one after another',
        () async {
      final rig = _Rig();
      rig.attention.hold();
      rig.assignments.hold();
      final future = rig.cubit.load();
      await pumpEventQueue();
      expect(rig.attention.calls.any((c) => c.startsWith('invitations')), isTrue);
      expect(rig.attention.calls.any((c) => c.startsWith('activity')), isTrue);
      expect(rig.assignments.calls.any((c) => c.startsWith('designatedTiles')),
          isTrue);
      rig.attention.release();
      rig.assignments.release();
      await future;
      await rig.close();
    });

    test('an empty account is ready with no items (not stuck loading)',
        () async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      expect(rig.cubit.state.load, AttentionLoad.ready);
      expect(rig.cubit.state.items, isEmpty);
      await rig.close();
    });

    test('events I performed myself are left out; unknown user → shown', () async {
      final attention = FakeTileShareAttentionSources(activity: [
        tsActivity('mine', 'assignment_declined', cluster: 'c1', actorId: 'me'),
      ]);
      final rig = _Rig(
          attention: attention,
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      expect(rig.cubit.state.items, isEmpty);
      rig.userId = null;
      await rig.cubit.refresh();
      expect(_ids(rig.cubit.state), ['declined:c1']);
      await rig.close();
    });
  });

  group('paging is bounded', () {
    test('invitations: follows the cursor up to the page cap', () async {
      final attention = FakeTileShareAttentionSources(invitations: [
        for (int i = 0; i < 300; i++) tsInvitation('a${i.toString().padLeft(3, '0')}', 'c$i'),
      ]);
      final rig = _Rig(
          attention: attention,
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      final pages = attention.calls.where((c) => c.startsWith('invitations')).length;
      expect(pages, TileShareAttentionCubit.maxInvitationPages);
      expect(rig.cubit.state.items.length,
          TileShareAttentionCubit.maxInvitationPages *
              TileShareAttentionCubit.pageSize);
      await rig.close();
    });

    test('activity: follows the cursor up to the page cap', () async {
      final attention = FakeTileShareAttentionSources(activity: [
        for (int i = 0; i < 260; i++)
          tsActivity('e$i', 'assignment_declined', cluster: 'c$i', atMsFromNow: -i),
      ]);
      final rig = _Rig(
          attention: attention,
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      final pages = attention.calls.where((c) => c.startsWith('activity')).length;
      expect(pages, TileShareAttentionCubit.maxActivityPages);
      expect(rig.cubit.state.items.length,
          TileShareAttentionCubit.maxActivityPages *
              TileShareAttentionCubit.pageSize);
      await rig.close();
    });

    test('received tiles: stops at the page cap, and on a short page',
        () async {
      final assignments = FakeTileShareAssignmentsSource([
        for (int i = 0; i < 120; i++)
          tsDesignatedTile('d$i',
              clusterId: 'c$i', status: InvitationStatus.accepted, viable: false),
      ]);
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(),
          assignments: assignments,
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      expect(assignments.calls.length, TileShareAttentionCubit.maxReceivedPages);
      expect(rig.cubit.state.items.length,
          TileShareAttentionCubit.maxReceivedPages *
              TileShareAttentionCubit.pageSize);
      await rig.close();

      final few = FakeTileShareAssignmentsSource([
        tsDesignatedTile('d0',
            clusterId: 'c0', status: InvitationStatus.accepted, viable: false),
      ]);
      final rig2 = _Rig(
          attention: FakeTileShareAttentionSources(),
          assignments: few,
          clusters: FakeTileShareClustersSource());
      await rig2.cubit.load();
      expect(few.calls.length, 1, reason: 'a short page ends the paging');
      await rig2.close();
    });
  });

  group('partial and total failures', () {
    test('one source failing keeps the others and reports which', () async {
      final rig = _Rig();
      rig.attention.failNextOn('activity', StateError('feed down'));
      await rig.cubit.load();
      expect(_ids(rig.cubit.state), ['invitation:c-class', 'atRisk:c-risk']);
      expect(rig.cubit.state.failedSources, {AttentionSource.activity});
      expect(rig.cubit.state.load, AttentionLoad.ready);
      await rig.close();
    });

    test('every source failing still ends ready, with all three reported',
        () async {
      final rig = _Rig();
      rig.attention.failNextOn('invitations', StateError('x'));
      rig.attention.failNextOn('activity', StateError('x'));
      rig.assignments.failNext(StateError('x'));
      await rig.cubit.load();
      expect(rig.cubit.state.load, AttentionLoad.ready);
      expect(rig.cubit.state.items, isEmpty);
      expect(rig.cubit.state.failedSources, AttentionSource.values.toSet());
      await rig.close();
    });
  });

  group('refresh', () {
    test('keeps the list visible while it reloads', () async {
      final rig = _Rig();
      await rig.cubit.load();
      final before = _ids(rig.cubit.state).toList();
      rig.attention.hold();
      rig.assignments.hold();
      final future = rig.cubit.refresh();
      await pumpEventQueue();
      expect(rig.cubit.state.isRefreshing, isTrue);
      expect(rig.cubit.state.load, AttentionLoad.ready);
      expect(_ids(rig.cubit.state), before, reason: 'never an empty flash');
      rig.attention.release();
      rig.assignments.release();
      await future;
      expect(rig.cubit.state.isRefreshing, isFalse);
      await rig.close();
    });

    test('load() on an already-loaded cubit behaves like a refresh (no loading '
        'flash)', () async {
      final rig = _Rig();
      await rig.cubit.load();
      final states = <TileShareAttentionState>[];
      final sub = rig.cubit.stream.listen(states.add);
      await rig.cubit.load();
      await sub.cancel();
      expect(states.where((s) => s.load == AttentionLoad.loading), isEmpty);
      await rig.close();
    });

    test('a failing source keeps its last-known data; the next refresh clears '
        'the failure', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.failNextOn('invitations', StateError('blip'));
      await rig.cubit.refresh();
      expect(_ids(rig.cubit.state), contains('invitation:c-class'),
          reason: 'stale data is kept, not dropped');
      expect(rig.cubit.state.failedSources, {AttentionSource.invitations});
      await rig.cubit.refresh();
      expect(rig.cubit.state.failedSources, isEmpty);
      await rig.close();
    });

    test('new server data replaces the old', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.activityList.add(
          tsActivity('e2', 'assignment_completed', cluster: 'c-done'));
      await rig.cubit.refresh();
      expect(_ids(rig.cubit.state), contains('completed:c-done'));
      await rig.close();
    });

    test('closing the cubit during a load does not throw', () async {
      final rig = _Rig();
      rig.attention.hold();
      final future = rig.cubit.load();
      await pumpEventQueue();
      await rig.close();
      rig.attention.release();
      await expectLater(future, completes);
    });
  });

  group('resolve an activity item (dismiss)', () {
    test('the item disappears immediately and the server is told per event',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.hold();
      final future = rig.cubit.resolve('declined:c-own');
      expect(_ids(rig.cubit.state), isNot(contains('declined:c-own')),
          reason: 'optimistic: gone before the server answers');
      await pumpEventQueue();
      expect(rig.attention.calls.last, 'setDismissed(e1, true)');
      rig.attention.release();
      expect(await future, isTrue);
      expect(rig.attention.dismissed, {'e1'});
      await rig.close();
    });

    test('a failed dismissal rolls back and reports it', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.failNextOn('setDismissed', StateError('offline'));
      expect(await rig.cubit.resolve('declined:c-own'), isFalse);
      expect(_ids(rig.cubit.state), contains('declined:c-own'));
      expect(rig.cubit.state.dismissFailure?.itemId, 'declined:c-own');
      expect(rig.cubit.state.dismissFailure?.wasUndo, isFalse);
      rig.cubit.acknowledgeFailure();
      expect(rig.cubit.state.dismissFailure, isNull);
      await rig.close();
    });

    test('a multi-event item: only the events that failed come back', () async {
      final attention = FakeTileShareAttentionSources(activity: [
        tsActivity('new', 'tilette_edited',
            cluster: 'c1', atMsFromNow: -1000, metadata: {'changedFields': ['name']}),
        tsActivity('old', 'tilette_edited',
            cluster: 'c1', atMsFromNow: -5000, metadata: {'changedFields': ['note']}),
      ]);
      final rig = _Rig(
          attention: attention,
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await rig.cubit.load();
      expect(rig.cubit.state.items.single.count, 2);
      attention.failNextOn('setDismissed', StateError('one fails'));
      expect(await rig.cubit.resolve('changed:c1'), isFalse);
      final item = rig.cubit.state.items.single;
      expect(item.count, 1, reason: 'the failed event returns, the other stays gone');
      expect(item.eventIds, ['new']);
      expect(attention.dismissed, {'old'});
      await rig.close();
    });

    test('undo restores the item and tells the server', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.resolve('declined:c-own');
      expect(await rig.cubit.undo('declined:c-own'), isTrue);
      expect(_ids(rig.cubit.state), contains('declined:c-own'));
      expect(rig.attention.dismissed, isEmpty);
      expect(rig.attention.calls.last, 'setDismissed(e1, false)');
      await rig.close();
    });

    test('a failed undo hides the item again and says it was an undo',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.resolve('declined:c-own');
      rig.attention.failNextOn('setDismissed', StateError('offline'));
      expect(await rig.cubit.undo('declined:c-own'), isFalse);
      expect(_ids(rig.cubit.state), isNot(contains('declined:c-own')));
      expect(rig.cubit.state.dismissFailure?.wasUndo, isTrue);
      await rig.close();
    });

    test('a dismissal is remembered by the server: it stays gone after a '
        'reload and in a brand-new session', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.resolve('declined:c-own');
      await rig.cubit.refresh();
      expect(_ids(rig.cubit.state), isNot(contains('declined:c-own')));

      final fresh = _Rig(
          attention: rig.attention,
          assignments: rig.assignments,
          clusters: rig.clusters);
      await fresh.cubit.load();
      expect(_ids(fresh.cubit.state), isNot(contains('declined:c-own')));
      await rig.close();
      await fresh.close();
    });

    test('an event dismissed while the request is in flight is not resurrected '
        'by a refresh', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.hold();
      final dismissing = rig.cubit.resolve('declined:c-own');
      final refreshing = rig.cubit.refresh();
      await pumpEventQueue();
      rig.attention.release();
      await dismissing;
      await refreshing;
      expect(_ids(rig.cubit.state), isNot(contains('declined:c-own')));
      await rig.close();
    });
  });

  group('resolve other items', () {
    test('an answered invitation disappears locally and makes no dismissal call',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(await rig.cubit.resolve('invitation:c-class'), isTrue);
      expect(_ids(rig.cubit.state), isNot(contains('invitation:c-class')));
      expect(rig.attention.calls.where((c) => c.startsWith('setDismissed')),
          isEmpty);
      await rig.close();
    });

    test('an at-risk item cannot be dismissed; an unknown id is a no-op',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      final before = _ids(rig.cubit.state).toList();
      expect(await rig.cubit.resolve('atRisk:c-risk'), isFalse);
      expect(await rig.cubit.resolve('nope:x'), isFalse);
      expect(_ids(rig.cubit.state), before);
      await rig.close();
    });

    test('undo of something that was never dismissed is false', () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(await rig.cubit.undo('declined:c-own'), isFalse);
      await rig.close();
    });
  });

  group('cluster titles', () {
    test('an at-risk item (which knows no title) gets its cluster name',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      final risk =
          rig.cubit.state.items.firstWhere((i) => i.type == AttentionType.atRisk);
      expect(risk.clusterTitle, 'Cluster c-risk');
      await rig.close();
    });

    test('a failed lookup leaves the title empty until the next load',
        () async {
      final rig = _Rig();
      rig.clusters.failNextOn('cluster(c-risk)', StateError('lookup failed'));
      await rig.cubit.load();
      AttentionItem risk() => rig.cubit.state.items
          .firstWhere((i) => i.type == AttentionType.atRisk);
      expect(risk().clusterTitle, isNull);
      await rig.cubit.refresh();
      expect(risk().clusterTitle, 'Cluster c-risk');
      await rig.close();
    });
  });

  group('cluster modes', () {
    test('resolved from the clusters source and exposed on the items',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      TileShareMode? modeOf(String id) =>
          rig.cubit.state.items.firstWhere((i) => i.clusterId == id).mode;
      expect(modeOf('c-class'), TileShareMode.class_);
      expect(modeOf('c-risk'), TileShareMode.project);
      expect(modeOf('c-own'), TileShareMode.broadcast);
      await rig.close();
    });

    test('a known mode is not fetched again', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.refresh();
      await rig.cubit.refresh();
      final fetches =
          rig.clusters.calls.where((c) => c == 'cluster(c-class)').length;
      expect(fetches, 1);
      await rig.close();
    });

    test('a failed lookup leaves the mode unknown, retries later, and never '
        'blocks the item', () async {
      final rig = _Rig();
      rig.clusters.failNextOn('cluster(c-class)', StateError('lookup failed'));
      await rig.cubit.load();
      AttentionItem item() => rig.cubit.state.items
          .firstWhere((i) => i.clusterId == 'c-class');
      expect(item().mode, isNull);
      await rig.cubit.refresh();
      expect(item().mode, TileShareMode.class_);
      await rig.close();
    });
  });
}
