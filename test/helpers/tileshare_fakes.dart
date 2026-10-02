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

import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
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

/// What a [FakeTileSharePreviewSource] was asked to accept.
class FakeAcceptedPreview {
  final String assignmentId;
  final String previewToken;
  final String operationId;
  final TileShareAcceptanceMode mode;
  final String? sessionKey;
  final TileShareLockedTimeLine? lockedTimeLine;

  const FakeAcceptedPreview({
    required this.assignmentId,
    required this.previewToken,
    required this.operationId,
    required this.mode,
    this.sessionKey,
    this.lockedTimeLine,
  });
}

/// The accept preview in memory. Behaves like the server: alternatives come a
/// page at a time (the page whose start offset matches the request), each
/// option revises to its own scripted preview, and an accepted operation moves
/// through [operationScript] as it is polled (by default queued -> applied ->
/// completed, then stays completed).
class FakeTileSharePreviewSource
    with FakeSourceControls
    implements TileSharePreviewSource {
  TileSharePreview previewResult;
  final List<PreviewOptionsPage> optionPages;

  /// Previews to revise to, by option id.
  final Map<String, TileSharePreview> revisions;
  final List<OperationState> operationScript;
  final TileShareAssignmentResponse? responseResult;

  /// The calendar event a completed operation names.
  final String calendarId;

  /// Every accept it was asked for, in order.
  final List<FakeAcceptedPreview> accepted = <FakeAcceptedPreview>[];

  final Map<String, int> _polls = <String, int>{};
  final Map<String, String> _assignmentOfOperation = <String, String>{};
  int _ids = 0;

  FakeTileSharePreviewSource(
    this.previewResult, {
    List<PreviewOptionsPage>? optionPages,
    Map<String, TileSharePreview>? revisions,
    List<OperationState>? operationScript,
    TileShareAssignmentResponse? response,
    this.calendarId = 'CalendarEvent+fake',
  })  : optionPages = optionPages ?? <PreviewOptionsPage>[],
        revisions = revisions ?? <String, TileSharePreview>{},
        operationScript = operationScript ??
            const <OperationState>[
              OperationState.applied,
              OperationState.completed
            ],
        responseResult = response;

  @override
  Future<TileSharePreview> preview(String assignmentId) =>
      run('preview($assignmentId)', () => previewResult);

  @override
  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  }) =>
      run('options($assignmentId, offset: $offset)', () {
        int start = 0;
        for (final PreviewOptionsPage page in optionPages) {
          if (start == offset) return page;
          final int? next = page.nextOffset;
          if (next == null) break;
          start = next;
        }
        return const PreviewOptionsPage(options: <PreviewOption>[]);
      });

  @override
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  }) =>
      run('revise($assignmentId, option: $optionId, fixed: $fixed)', () {
        final TileSharePreview? revised = revisions[optionId];
        if (revised == null) {
          throw const TileSharePreviewFailure(PreviewFailureKind.notFound,
              statusCode: 404);
        }
        return revised;
      });

  @override
  Future<TileShareOperation> accept({
    required String assignmentId,
    required String previewToken,
    required String operationId,
    required TileShareAcceptanceMode mode,
    String? sessionKey,
    TileShareLockedTimeLine? lockedTimeLine,
  }) =>
      run('accept($assignmentId, $operationId, ${mode.name}, $sessionKey)', () {
        accepted.add(FakeAcceptedPreview(
            assignmentId: assignmentId,
            previewToken: previewToken,
            operationId: operationId,
            mode: mode,
            sessionKey: sessionKey,
            lockedTimeLine: lockedTimeLine));
        _assignmentOfOperation[operationId] = assignmentId;
        return TileShareOperation(
            operationId: operationId,
            assignmentId: assignmentId,
            state: OperationState.queued);
      });

  @override
  Future<TileShareOperation> operation(String operationId) =>
      run('operation($operationId)', () {
        final int polls = _polls[operationId] = (_polls[operationId] ?? 0) + 1;
        final OperationState state = operationScript.isEmpty
            ? OperationState.completed
            : operationScript[
                (polls - 1).clamp(0, operationScript.length - 1).toInt()];
        return TileShareOperation(
          operationId: operationId,
          assignmentId: _assignmentOfOperation[operationId] ?? '',
          state: state,
          calendarId: state == OperationState.completed ? calendarId : null,
          reason: state == OperationState.needsReview ? 'scheduleChanged' : null,
        );
      });

  @override
  Future<TileShareAssignmentResponse> response(String assignmentId) =>
      run('response($assignmentId)', () {
        final TileShareAssignmentResponse? r = responseResult;
        if (r == null) {
          throw const TileSharePreviewFailure(PreviewFailureKind.notFound,
              statusCode: 404);
        }
        return r;
      });

  @override
  String newOperationId() => (++_ids).toRadixString(16).padLeft(32, '0');
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
