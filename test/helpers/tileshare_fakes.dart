// In-memory doubles for the TileShare data seams (redesign Step 9.3), used by
// the cubit and widget tests in later steps. They behave like the real thing —
// paged lists, ids, in-memory state — and can be told to fail or to stall:
//   * `failNext(error)` makes the next call throw once;
//   * `failNextOn(prefix, error)` makes the next call whose description starts
//     with `prefix` throw once (for sources loaded in parallel);
//   * `hold()` / `release()` stall every call until released, so a test can
//     observe a loading state mid-flight;
//   * `calls` records every call, in order, for assertions.
import 'dart:async';

import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// Shared "misbehave on demand" behaviour.
mixin FakeSourceControls {
  final List<String> calls = <String>[];
  Object? _failNext;
  final Map<String, Object> _failOn = <String, Object>{};
  Completer<void>? _gate;

  /// The next call throws [error] (once), after any hold is released.
  void failNext(Object error) => _failNext = error;

  /// The next call whose description starts with [prefix] throws [error]
  /// (once), e.g. `failNextOn('setDismissed', error)`.
  void failNextOn(String prefix, Object error) => _failOn[prefix] = error;

  /// Every call waits until [release].
  void hold() => _gate ??= Completer<void>();

  void release() {
    final Completer<void>? gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<T> run<T>(String call, T Function() body) async {
    calls.add(call);
    final Completer<void>? gate = _gate;
    if (gate != null) await gate.future;
    for (final String prefix in _failOn.keys.toList()) {
      if (call.startsWith(prefix)) {
        throw _failOn.remove(prefix)!;
      }
    }
    final Object? failure = _failNext;
    if (failure != null) {
      _failNext = null;
      throw failure;
    }
    return body();
  }
}

class FakeTileShareClustersSource
    with FakeSourceControls
    implements TileShareClustersSource {
  /// Clusters I created (the Outbox) and clusters shared with me (the Inbox).
  final List<TileShareClusterData> outbox;
  final List<TileShareClusterData> inbox;
  final Map<String, List<TileShareTemplate>> tilettesByCluster;

  FakeTileShareClustersSource({
    List<TileShareClusterData>? outbox,
    List<TileShareClusterData>? inbox,
    Map<String, List<TileShareTemplate>>? tilettesByCluster,
  })  : outbox = outbox ?? <TileShareClusterData>[],
        inbox = inbox ?? <TileShareClusterData>[],
        tilettesByCluster = tilettesByCluster ?? <String, List<TileShareTemplate>>{};

  @override
  Future<List<TileShareClusterData>> clusters(
          {required bool isOutbox, int index = 0, int pageSize = 50}) =>
      run('clusters(isOutbox: $isOutbox, index: $index, pageSize: $pageSize)',
          () {
        final List<TileShareClusterData> all = isOutbox ? outbox : inbox;
        if (index >= all.length) return <TileShareClusterData>[];
        final int end = (index + pageSize).clamp(0, all.length);
        return all.sublist(index, end);
      });

  @override
  Future<TileShareClusterData?> cluster(String clusterId) =>
      run('cluster($clusterId)', () {
        for (final TileShareClusterData c in [...outbox, ...inbox]) {
          if (c.id == clusterId) return c;
        }
        return null;
      });

  @override
  Future<List<TileShareTemplate>> tilettes(String clusterId) =>
      run('tilettes($clusterId)',
          () => tilettesByCluster[clusterId] ?? <TileShareTemplate>[]);

  @override
  Future<void> deleteCluster(String clusterId) =>
      run('deleteCluster($clusterId)', () {
        outbox.removeWhere((c) => c.id == clusterId);
      });
}

class FakeTileShareAssignmentsSource
    with FakeSourceControls
    implements TileShareAssignmentsSource {
  /// The signed-in user's own assignments, by designated-tile id.
  final List<DesignatedTile> tiles;

  FakeTileShareAssignmentsSource([List<DesignatedTile>? tiles])
      : tiles = tiles ?? <DesignatedTile>[];

  @override
  Future<List<DesignatedTile>> designatedTiles(
          {String? clusterId, int index = 0, int pageSize = 50}) =>
      run('designatedTiles(clusterId: $clusterId, index: $index, '
          'pageSize: $pageSize)', () {
        final List<DesignatedTile> scoped = clusterId == null
            ? tiles
            : tiles.where((t) => t.tileTemplate?.clusterId == clusterId).toList();
        if (index >= scoped.length) return <DesignatedTile>[];
        return scoped.sublist(index, (index + pageSize).clamp(0, scoped.length));
      });

  @override
  Future<DesignatedTile?> respond(
          String designatedTileId, InvitationStatus status) =>
      run('respond($designatedTileId, ${status.name})', () {
        final int i = tiles.indexWhere((t) => t.id == designatedTileId);
        if (i < 0) return null;
        tiles[i].invitationStatus = status.name;
        return tiles[i];
      });

  @override
  Future<void> afterAccept() => run('afterAccept()', () {});
}

class FakeTileShareFitSource
    with FakeSourceControls
    implements TileShareFitSource {
  ForecastResponse response;

  FakeTileShareFitSource(this.response);

  @override
  Future<ForecastResponse> forecast(Map<String, Object> params) =>
      run('forecast(${(params.keys.toList()..sort()).join(',')})', () => response);
}

/// Invitations, the activity feed and dismissal, in memory. The activity list
/// is newest first; dismissed events are left out of [activity], like the
/// server does, so a reload proves the dismissal is remembered.
class FakeTileShareAttentionSources
    with FakeSourceControls
    implements TileShareAttentionSources {
  final List<TileShareInvitation> invitationList;
  final List<TileShareActivity> activityList;
  final Set<String> dismissed = <String>{};

  FakeTileShareAttentionSources({
    List<TileShareInvitation>? invitations,
    List<TileShareActivity>? activity,
  })  : invitationList = invitations ?? <TileShareInvitation>[],
        activityList = activity ?? <TileShareActivity>[];

  @override
  Future<TileShareInvitationPage> invitations(
          {String? afterId, int pageSize = 50}) =>
      run('invitations(afterId: $afterId, pageSize: $pageSize)', () {
        final int start = afterId == null
            ? 0
            : invitationList.indexWhere((i) => i.assignmentId == afterId) + 1;
        final int end = (start + pageSize).clamp(0, invitationList.length);
        final List<TileShareInvitation> slice =
            start >= invitationList.length
                ? <TileShareInvitation>[]
                : invitationList.sublist(start, end);
        return TileShareInvitationPage(
            slice, end < invitationList.length ? slice.last.assignmentId : null);
      });

  @override
  Future<TileShareActivityPage> activity(
          {String? cursor, int pageSize = 50}) =>
      run('activity(cursor: $cursor, pageSize: $pageSize)', () {
        final List<TileShareActivity> visible =
            activityList.where((e) => !dismissed.contains(e.eventId)).toList();
        final int start = cursor == null ? 0 : int.parse(cursor);
        final int end = (start + pageSize).clamp(0, visible.length);
        final List<TileShareActivity> slice =
            start >= visible.length ? <TileShareActivity>[] : visible.sublist(start, end);
        return TileShareActivityPage(
            items: slice,
            nextCursor: end < visible.length ? '$end' : null,
            historyAvailableFrom: 1);
      });

  @override
  Future<void> setDismissed(String eventId, bool isDismissed) =>
      run('setDismissed($eventId, $isDismissed)', () {
        if (isDismissed) {
          dismissed.add(eventId);
        } else {
          dismissed.remove(eventId);
        }
      });
}
