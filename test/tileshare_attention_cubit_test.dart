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
//     endpoint does not carry it);
//   * an invitation is answered inline (T8, T20): the card disappears at once,
//     the request is sent only after an undo window, Undo inside it sends
//     nothing, a failure restores exactly what failed, and leaving the screen
//     sends a pending answer straight away. Only Broadcast and Class can be
//     answered inline; a Class answers every task it holds.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

/// Timers that only fire when the test says so, so the undo window is
/// deterministic.
class _ManualTimers {
  final List<_ManualTimer> timers = <_ManualTimer>[];

  Timer create(Duration duration, void Function() callback) {
    final timer = _ManualTimer(duration, callback);
    timers.add(timer);
    return timer;
  }

  void fireAll() {
    for (final timer in List<_ManualTimer>.of(timers)) {
      timer.fire();
    }
  }

  int get active => timers.where((t) => t.isActive).length;
}

class _ManualTimer implements Timer {
  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  _ManualTimer(this.duration, this._callback);

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

class _Rig {
  final _ManualTimers timers = _ManualTimers();
  final List<String> tags = <String>[];
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
      timerFactory: timers.create,
      analytics: (tag, info) => tags.add(tag),
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

  group('logging for diagnosis', () {
    late List<String> logs;
    late void Function(String) originalSink;

    setUp(() {
      logs = <String>[];
      originalSink = TileShareLog.sink;
      TileShareLog.sink = logs.add;
    });
    tearDown(() => TileShareLog.sink = originalSink);

    bool logged(bool Function(String) test) => logs.any(test);

    test('a failing source is logged with its name and its error', () async {
      final rig = _Rig();
      rig.attention.failNextOn('invitations', StateError('endpoint not deployed'));
      rig.assignments.failNext(StateError('tiles unavailable'));
      await rig.cubit.load();
      expect(
          logged((l) =>
              l.contains('invitations') && l.contains('endpoint not deployed')),
          isTrue,
          reason: '$logs');
      expect(
          logged((l) =>
              l.contains('received') && l.contains('tiles unavailable')),
          isTrue,
          reason: '$logs');
      await rig.close();
    });

    test('every load says how many things each source returned', () async {
      final rig = _Rig();
      await rig.cubit.load();
      final summary = logs.firstWhere((l) => l.contains('loaded'), orElse: () => '');
      expect(summary, contains('invitations=1'));
      expect(summary, contains('activity=1'));
      expect(summary, contains('received=1'));
      expect(summary, contains('3 items'));
      expect(summary, isNot(contains('failed')));
      await rig.close();
    });

    test('the summary counts the activity by event type, so events that '
        'produce no card can be recognised', () async {
      final rig = _Rig();
      await rig.cubit.load();
      final summary = logs.firstWhere((l) => l.contains('loaded'), orElse: () => '');
      expect(summary, matches(RegExp(r'types=\{[a-z_]+:\d+')),
          reason: summary);
      await rig.close();
    });

    test('the summary names the sources that failed', () async {
      final rig = _Rig();
      rig.attention.failNextOn('invitations', StateError('x'));
      await rig.cubit.load();
      final summary = logs.firstWhere((l) => l.contains('loaded'), orElse: () => '');
      expect(summary, contains('invitations=0'));
      expect(summary, contains('failed: invitations'));
      await rig.close();
    });

    test('nothing that looks like a failure is logged when all is well',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(logged((l) => l.contains('failed')), isFalse, reason: '$logs');
      await rig.close();
    });

    test('an inline answer is logged from start to finish', () async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(
              invitations: [tsInvitation('b1', 'c-bc')]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource(
              inbox: [tsCluster('c-bc', mode: TileShareMode.broadcast)]));
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      expect(logged((l) => l.contains('accepted') && l.contains('invitation:c-bc')),
          isTrue,
          reason: 'taking the answer: $logs');
      rig.timers.fireAll();
      await pumpEventQueue();
      expect(logged((l) => l.contains('b1') && l.contains('ok')), isTrue,
          reason: 'the request outcome: $logs');
      await rig.close();
    });

    test('a refused answer and a failed schedule refresh are logged with '
        'their errors', () async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(invitations: [
            tsInvitation('b1', 'c-bc'),
          ]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource(
              inbox: [tsCluster('c-bc', mode: TileShareMode.broadcast)]));
      await rig.cubit.load();
      rig.assignments.failNextOn('respond', StateError('server said no'));
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      rig.timers.fireAll();
      await pumpEventQueue();
      expect(logged((l) => l.contains('b1') && l.contains('server said no')),
          isTrue,
          reason: '$logs');

      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      rig.assignments.failNextOn('afterAccept', StateError('refresh broke'));
      rig.timers.fireAll();
      await pumpEventQueue();
      expect(logged((l) => l.contains('schedule') && l.contains('refresh broke')),
          isTrue,
          reason: '$logs');
      await rig.close();
    });

    test('a refused dismissal is logged with the event id and the error',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.attention.failNextOn('setDismissed', StateError('dismiss refused'));
      await rig.cubit.resolve('declined:c-own');
      expect(logged((l) => l.contains('e1') && l.contains('dismiss refused')),
          isTrue,
          reason: '$logs');
      await rig.close();
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
  group('answer an invitation inline (T8, T20)', () {
    _Rig answerRig() => _Rig(
          attention: FakeTileShareAttentionSources(invitations: [
            tsInvitation('b1', 'c-bc'),
            tsInvitation('k1', 'c-class'),
            tsInvitation('k2', 'c-class'),
            tsInvitation('k3', 'c-class'),
            tsInvitation('p1', 'c-proj'),
            tsInvitation('p2', 'c-proj'),
          ]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource(inbox: [
            tsCluster('c-bc', mode: TileShareMode.broadcast),
            tsCluster('c-class', mode: TileShareMode.class_),
            tsCluster('c-proj', mode: TileShareMode.project),
          ]),
        );

    List<String> sent(_Rig r) =>
        r.assignments.calls.where((c) => c.startsWith('respond')).toList();
    List<String> refreshed(_Rig r) =>
        r.assignments.calls.where((c) => c.startsWith('afterAccept')).toList();
    Future<void> elapse(_Rig r) async {
      r.timers.fireAll();
      await pumpEventQueue();
    }

    test('accepting hides the invitation at once and sends nothing yet',
        () async {
      final rig = answerRig();
      await rig.cubit.load();
      expect(rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted),
          isTrue);
      expect(_ids(rig.cubit.state), isNot(contains('invitation:c-bc')));
      expect(sent(rig), isEmpty, reason: 'the request waits for the undo window');
      expect(rig.timers.active, 1);
      await rig.close();
    });

    test('undo inside the window restores the card and never sends a request',
        () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      expect(rig.cubit.undoResponse('invitation:c-bc'), isTrue);
      expect(_ids(rig.cubit.state), contains('invitation:c-bc'));
      await elapse(rig);
      expect(sent(rig), isEmpty);
      expect(refreshed(rig), isEmpty);
      await rig.close();
    });

    test('finishing an answer bumps answerRevision, so other screens know to '
        'refresh; an undone one does not', () async {
      final rig = answerRig();
      await rig.cubit.load();
      expect(rig.cubit.state.answerRevision, 0);

      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      expect(rig.cubit.state.answerRevision, 0, reason: 'not sent yet');
      rig.cubit.undoResponse('invitation:c-bc');
      await elapse(rig);
      expect(rig.cubit.state.answerRevision, 0, reason: 'nothing was sent');

      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      await elapse(rig);
      expect(rig.cubit.state.answerRevision, 1);
      await rig.close();
    });

    test('a refused answer also bumps answerRevision (the row must come '
        'back everywhere)', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.assignments.failNextOn('respond', StateError('no'));
      rig.cubit.respond('invitation:c-bc', InvitationStatus.declined);
      await elapse(rig);
      expect(rig.cubit.state.answerRevision, 1);
      expect(rig.cubit.state.respondFailure, isNotNull);
      await rig.close();
    });

    test('after the window the answer is sent once, then the schedule is '
        'refreshed', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      await elapse(rig);
      expect(sent(rig), ['respond(b1, accepted)']);
      expect(refreshed(rig).length, 1);
      final order = rig.assignments.calls
          .where((c) => c.startsWith('respond') || c.startsWith('afterAccept'))
          .toList();
      expect(order, ['respond(b1, accepted)', 'afterAccept()']);
      expect(_ids(rig.cubit.state), isNot(contains('invitation:c-bc')));
      expect(rig.cubit.state.respondFailure, isNull);
      await rig.close();
    });

    test('declining is sent but never re-analyses the schedule', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.declined);
      await elapse(rig);
      expect(sent(rig), ['respond(b1, declined)']);
      expect(refreshed(rig), isEmpty);
      await rig.close();
    });

    test('a Class answers every task it holds, one after another, then '
        'refreshes once', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-class', InvitationStatus.accepted);
      await elapse(rig);
      expect(sent(rig), [
        'respond(k1, accepted)',
        'respond(k2, accepted)',
        'respond(k3, accepted)',
      ]);
      expect(refreshed(rig).length, 1);
      await rig.close();
    });

    test('a Project cannot be answered inline, nor can an unknown mode',
        () async {
      final rig = answerRig();
      rig.clusters.failNextOn('cluster(c-bc)', StateError('lookup failed'));
      await rig.cubit.load();
      expect(rig.cubit.respond('invitation:c-proj', InvitationStatus.accepted),
          isFalse);
      expect(rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted),
          isFalse,
          reason: 'mode unknown → no inline answer');
      expect(_ids(rig.cubit.state),
          containsAll(['invitation:c-proj', 'invitation:c-bc']));
      expect(rig.timers.timers, isEmpty);
      await rig.close();
    });

    test('only an invitation can be answered, and only with accept or decline',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(rig.cubit.respond('declined:c-own', InvitationStatus.accepted),
          isFalse);
      expect(rig.cubit.respond('nope:x', InvitationStatus.accepted), isFalse);
      expect(rig.cubit.respond('invitation:c-class', InvitationStatus.none),
          isFalse);
      await rig.close();
    });

    test('a second tap while the first is pending is ignored', () async {
      final rig = answerRig();
      await rig.cubit.load();
      expect(rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted),
          isTrue);
      expect(rig.cubit.respond('invitation:c-bc', InvitationStatus.declined),
          isFalse);
      await elapse(rig);
      expect(sent(rig), ['respond(b1, accepted)']);
      await rig.close();
    });

    test('once the send has started it is too late to undo', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      rig.assignments.hold();
      rig.timers.fireAll();
      await pumpEventQueue();
      expect(rig.cubit.undoResponse('invitation:c-bc'), isFalse);
      rig.assignments.release();
      await pumpEventQueue();
      expect(sent(rig), ['respond(b1, accepted)']);
      await rig.close();
    });

    test('a failed answer puts the card back and says so', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.assignments.failNextOn('respond', StateError('offline'));
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      await elapse(rig);
      expect(_ids(rig.cubit.state), contains('invitation:c-bc'));
      final failure = rig.cubit.state.respondFailure!;
      expect(failure.itemId, 'invitation:c-bc');
      expect(failure.status, InvitationStatus.accepted);
      expect(failure.kind, AttentionRespondFailureKind.answer);
      expect(refreshed(rig), isEmpty, reason: 'nothing was accepted');
      rig.cubit.acknowledgeFailure();
      expect(rig.cubit.state.respondFailure, isNull);
      await rig.close();
    });

    test('a Class where one task fails: only that task comes back, the rest '
        'stay answered and the schedule still refreshes', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.assignments.failNextOn('respond(k2', StateError('one fails'));
      rig.cubit.respond('invitation:c-class', InvitationStatus.accepted);
      await elapse(rig);
      final item = rig.cubit.state.items
          .firstWhere((i) => i.id == 'invitation:c-class');
      expect(item.assignmentIds, ['k2']);
      expect(item.count, 1);
      expect(refreshed(rig).length, 1, reason: 'k1 and k3 were accepted');
      expect(rig.cubit.state.respondFailure?.kind,
          AttentionRespondFailureKind.answer);
      await rig.close();
    });

    test('the schedule refresh failing is reported, but the answer stands',
        () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.assignments.failNextOn('afterAccept', StateError('refresh failed'));
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      await elapse(rig);
      expect(_ids(rig.cubit.state), isNot(contains('invitation:c-bc')));
      expect(rig.cubit.state.respondFailure?.kind,
          AttentionRespondFailureKind.scheduleRefresh);
      await rig.close();
    });

    test('leaving the screen sends a pending answer straight away', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      expect(sent(rig), isEmpty);
      await rig.close();
      expect(sent(rig), ['respond(b1, accepted)']);
      expect(refreshed(rig).length, 1);
      expect(rig.timers.active, 0, reason: 'the undo timer is cancelled');
    });

    test('flushPending sends immediately and only once', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.declined);
      await rig.cubit.flushPending();
      await rig.cubit.flushPending();
      await elapse(rig);
      expect(sent(rig), ['respond(b1, declined)']);
      await rig.close();
    });

    test('a refresh while the answer is pending does not bring the card back',
        () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      await rig.cubit.refresh();
      expect(_ids(rig.cubit.state), isNot(contains('invitation:c-bc')));
      await rig.close();
    });

    test('accept, decline and undo are tagged for analytics', () async {
      final rig = answerRig();
      await rig.cubit.load();
      rig.cubit.respond('invitation:c-bc', InvitationStatus.accepted);
      rig.cubit.undoResponse('invitation:c-bc');
      rig.cubit.respond('invitation:c-class', InvitationStatus.declined);
      expect(rig.tags,
          ['tileshare_accept', 'tileshare_undo', 'tileshare_decline']);
      await rig.close();
    });

    test('the undo window is the documented five seconds by default', () {
      expect(TileShareAttentionCubit.defaultUndoWindow,
          const Duration(seconds: 5));
    });
  });
}
