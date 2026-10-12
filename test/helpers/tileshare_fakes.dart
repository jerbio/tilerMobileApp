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

import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplateMiscData.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/tileSharePendingAccept.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

import 'tileshare_fixtures.dart';

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
        tilettesByCluster =
            tilettesByCluster ?? <String, List<TileShareTemplate>>{};

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
  Future<List<TileShareTemplate>> tilettes(String clusterId) => run(
      'tilettes($clusterId)',
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
      run(
          'designatedTiles(clusterId: $clusterId, index: $index, '
          'pageSize: $pageSize)', () {
        final List<DesignatedTile> scoped = clusterId == null
            ? tiles
            : tiles
                .where((t) => t.tileTemplate?.clusterId == clusterId)
                .toList();
        if (index >= scoped.length) return <DesignatedTile>[];
        return scoped.sublist(
            index, (index + pageSize).clamp(0, scoped.length));
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
  Future<DesignatedTile?> designatedTile(String designatedTileId) =>
      run('designatedTile($designatedTileId)', () {
        for (final DesignatedTile t in tiles) {
          if (t.id == designatedTileId) return t;
        }
        return null;
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

/// The accept preview in memory, behaving like the server:
///
/// * alternatives come a page at a time (the page whose start offset matches the
///   request) and each option revises to its own scripted preview;
/// * an **accept answers with the outcome** ([acceptState], completed unless
///   told otherwise; [acceptReason] for rejected / needs review) - the server
///   runs the whole acceptance inside the request;
/// * an operation is **idempotent**: the same id with the same command returns
///   the stored record without accepting twice, and a different command is a 409
///   `operationMismatch`;
/// * [commitButLoseResponse] makes the next accept commit and then fail like a
///   lost connection, so a retry can be shown to return the stored outcome;
/// * for a non-final [acceptState], later reads of the operation follow
///   [operationScript] (the last entry repeats).
class FakeTileSharePreviewSource
    with FakeSourceControls
    implements TileSharePreviewSource {
  TileSharePreview previewResult;
  final List<PreviewOptionsPage> optionPages;

  /// Previews to revise to, by option id.
  final Map<String, TileSharePreview> revisions;
  OperationState acceptState;
  String? acceptReason;
  final List<OperationState> operationScript;
  final TileShareAssignmentResponse? responseResult;

  /// The calendar event a completed operation names.
  final String calendarId;

  /// The next accept commits, then fails as if the response was lost.
  bool commitButLoseResponse = false;

  /// Every accept that reached the server and was new, in order.
  final List<FakeAcceptedPreview> accepted = <FakeAcceptedPreview>[];

  final Map<String, _StoredOperation> _stored = <String, _StoredOperation>{};
  int _ids = 0;

  FakeTileSharePreviewSource(
    this.previewResult, {
    List<PreviewOptionsPage>? optionPages,
    Map<String, TileSharePreview>? revisions,
    this.acceptState = OperationState.completed,
    this.acceptReason,
    List<OperationState>? operationScript,
    TileShareAssignmentResponse? response,
    this.calendarId = 'CalendarEvent+fake',
  })  : optionPages = optionPages ?? <PreviewOptionsPage>[],
        revisions = revisions ?? <String, TileSharePreview>{},
        operationScript = operationScript ?? <OperationState>[],
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
        final String command = '$assignmentId|$previewToken|${mode.name}|'
            '$sessionKey|${lockedTimeLine?.startMs}/${lockedTimeLine?.durationMs}';
        final _StoredOperation? existing = _stored[operationId];
        if (existing != null) {
          if (existing.command != command) {
            throw const TileSharePreviewFailure(PreviewFailureKind.conflict,
                statusCode: 409, reason: 'operationMismatch');
          }
          return existing.currentRecord();
        }
        accepted.add(FakeAcceptedPreview(
            assignmentId: assignmentId,
            previewToken: previewToken,
            operationId: operationId,
            mode: mode,
            sessionKey: sessionKey,
            lockedTimeLine: lockedTimeLine));
        final _StoredOperation stored = _StoredOperation(
            command,
            TileShareOperation(
              operationId: operationId,
              assignmentId: assignmentId,
              state: acceptState,
              calendarId:
                  acceptState == OperationState.completed ? calendarId : null,
              reason: acceptReason,
            ),
            operationScript);
        _stored[operationId] = stored;
        if (commitButLoseResponse) {
          commitButLoseResponse = false;
          throw const TileSharePreviewFailure(PreviewFailureKind.server,
              reason: 'timed out');
        }
        return stored.first;
      });

  @override
  Future<TileShareOperation> operation(String operationId) =>
      run('operation($operationId)', () {
        final _StoredOperation? stored = _stored[operationId];
        if (stored == null) {
          throw const TileSharePreviewFailure(PreviewFailureKind.notFound,
              statusCode: 404);
        }
        return stored.read();
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

class _StoredOperation {
  final String command;
  final TileShareOperation first;
  final List<OperationState> script;
  int _reads = 0;

  _StoredOperation(this.command, this.first, this.script);

  /// What the server holds now (a repeated accept returns this).
  TileShareOperation currentRecord() => _reads == 0 ? first : _at(_reads - 1);

  /// One read of the operation; follows the script, then stays where it ended.
  TileShareOperation read() {
    if (script.isEmpty) return first;
    final TileShareOperation next = _at(_reads);
    _reads++;
    return next;
  }

  TileShareOperation _at(int i) {
    final OperationState state = script[i.clamp(0, script.length - 1).toInt()];
    return TileShareOperation(
      operationId: first.operationId,
      assignmentId: first.assignmentId,
      state: state,
      calendarId: state == OperationState.completed
          ? first.calendarId ?? 'CalendarEvent+fake'
          : null,
      reason: state == OperationState.needsReview ||
              state == OperationState.rejected
          ? first.reason ?? 'scheduleChanged'
          : null,
    );
  }
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
        final List<TileShareInvitation> slice = start >= invitationList.length
            ? <TileShareInvitation>[]
            : invitationList.sublist(start, end);
        return TileShareInvitationPage(slice,
            end < invitationList.length ? slice.last.assignmentId : null);
      });

  @override
  Future<TileShareActivityPage> activity({String? cursor, int pageSize = 50}) =>
      run('activity(cursor: $cursor, pageSize: $pageSize)', () {
        final List<TileShareActivity> visible =
            activityList.where((e) => !dismissed.contains(e.eventId)).toList();
        final int start = cursor == null ? 0 : int.parse(cursor);
        final int end = (start + pageSize).clamp(0, visible.length);
        final List<TileShareActivity> slice = start >= visible.length
            ? <TileShareActivity>[]
            : visible.sublist(start, end);
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

/// The unconfirmed accept, kept in memory. Records what was saved and cleared,
/// in order, so a test can show a command was saved BEFORE it was sent.
class FakePendingAcceptStore implements TileSharePendingAcceptStore {
  final Map<String, PendingAccept> _byAssignment = <String, PendingAccept>{};
  final List<String> log = <String>[];

  FakePendingAcceptStore([PendingAccept? initial]) {
    if (initial != null) _byAssignment[initial.assignmentId] = initial;
  }

  PendingAccept? operator [](String assignmentId) =>
      _byAssignment[assignmentId];

  @override
  Future<PendingAccept?> read(String assignmentId) async {
    log.add('read($assignmentId)');
    return _byAssignment[assignmentId];
  }

  @override
  Future<void> save(PendingAccept pending) async {
    log.add('save(${pending.operationId})');
    _byAssignment[pending.assignmentId] = pending;
  }

  @override
  Future<void> clear(String assignmentId) async {
    log.add('clear($assignmentId)');
    _byAssignment.remove(assignmentId);
  }
}

/// A tilette's recipients in memory: an add appends a recipient (assignment
/// `asg-<email or phone>`) and answers with the tilette, a removal drops one.
class FakeTileShareRecipientsSource
    with FakeSourceControls
    implements TileShareRecipientsSource {
  final Map<String, TileShareTemplate> tilettes;
  final List<TileShareActivity> activity;

  FakeTileShareRecipientsSource({
    Map<String, TileShareTemplate>? tilettes,
    List<TileShareActivity>? activity,
  })  : tilettes = tilettes ?? <String, TileShareTemplate>{},
        activity = activity ?? <TileShareActivity>[];

  @override
  Future<TileShareTemplate> addRecipient(String tiletteId, Contact contact) {
    final String who = contact.email ?? contact.phoneNumber ?? '';
    return run('addRecipient($tiletteId, $who)', () {
      final TileShareTemplate tilette = tilettes[tiletteId]!;
      tilette.designatedUsers = <DesignatedUser>[
        ...tilette.designatedUsers ?? const <DesignatedUser>[],
        DesignatedUser.fromJson({
          'id': 'asg-$who',
          'designatedTileTemplateId': 'asg-$who',
          'displayedIdentifier': who,
          'rsvpStatus': 'none',
        }),
      ];
      return tilette;
    });
  }

  @override
  Future<void> removeRecipient(String tiletteId, String assignmentId) =>
      run('removeRecipient($tiletteId, $assignmentId)', () {
        tilettes[tiletteId]?.designatedUsers?.removeWhere(
            (u) => (u.designatedTileTemplateId ?? u.id) == assignmentId);
      });

  @override
  Future<List<TileShareActivity>> clusterActivity(String clusterId) =>
      run('clusterActivity($clusterId)', () => activity);
}

/// An owner's edits to a share in memory, applied to [clusters] so a reload
/// shows them: rename / re-date the share, add / rename / re-date / delete a
/// task. Each call is recorded with what it carried.
class FakeTileShareEditSource
    with FakeSourceControls
    implements TileShareEditSource {
  final FakeTileShareClustersSource clusters;
  int _added = 0;

  FakeTileShareEditSource(this.clusters);

  TileShareClusterData? _cluster(String id) => [
        ...clusters.outbox,
        ...clusters.inbox
      ].where((c) => c.id == id).firstOrNull;

  @override
  Future<void> updateShare(String clusterId,
          {String? name, int? endMs, int? startMs}) =>
      run(
          'updateShare($clusterId, name: $name, end: $endMs'
          '${startMs == null ? '' : ', start: $startMs'})', () {
        final TileShareClusterData? c = _cluster(clusterId);
        if (c == null) return;
        if (name != null) c.name = name;
        if (endMs != null) c.endTimeInMs = endMs;
      });

  @override
  Future<String?> addTask(String clusterId, ClusterTemplateTileModel task) =>
      run('addTask($clusterId, ${task.Name}, contacts: ${task.Contacts?.length ?? 0})',
          () {
        final String id = 'new-${++_added}';
        clusters.tilettesByCluster[clusterId] = <TileShareTemplate>[
          ...clusters.tilettesByCluster[clusterId] ??
              const <TileShareTemplate>[],
          tsTilette(id,
              clusterId: clusterId,
              name: task.Name,
              durationMs: task.DurationInMs,
              assignees: [
                for (final c in task.Contacts ?? const [])
                  if (c.Email != null) tsAssignee(c.Email!),
              ]),
        ];
        return id;
      });

  @override
  Future<void> updateTask(String tiletteId, {String? name, int? endMs}) =>
      run('updateTask($tiletteId, name: $name, end: $endMs)', () {
        for (final list in clusters.tilettesByCluster.values) {
          for (final t in list) {
            if (t.id == tiletteId) {
              if (name != null) t.name = name;
              if (endMs != null) t.end = endMs;
            }
          }
        }
      });

  @override
  Future<void> saveTaskNotes(String tiletteId, String notes) =>
      run('saveTaskNotes($tiletteId, $notes)', () => notes_.store(tiletteId, notes));

  /// The tilettes' notes endpoint, in memory.
  late final FakeTileShareNotesApi notes_ = FakeTileShareNotesApi(clusters);

  @override
  NotesApi get tiletteNotes => notes_;

  @override
  Future<void> deleteTask(String tiletteId) =>
      run('deleteTask($tiletteId)', () {
        for (final key in clusters.tilettesByCluster.keys.toList()) {
          clusters.tilettesByCluster[key] = clusters.tilettesByCluster[key]!
              .where((t) => t.id != tiletteId)
              .toList();
        }
      });
}

/// `api/TileshareTemplate/Notes` in memory: a tilette's note and an etag that
/// changes with it; a write with a stale etag is a conflict that carries the
/// stored note. Notes live on the tilettes in [clusters], so a reload shows
/// them.
class FakeTileShareNotesApi extends NotesApi {
  final FakeTileShareClustersSource clusters;
  final List<String> calls = <String>[];

  /// The next write is a conflict, as if someone else saved first.
  bool conflictNext = false;
  int _version = 0;
  final Map<String, String> _etags = <String, String>{};

  FakeTileShareNotesApi(this.clusters) : super(getContextCallBack: () => null);

  TileShareTemplate? _tilette(String id) {
    for (final list in clusters.tilettesByCluster.values) {
      for (final t in list) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  String _etagOf(String id) => _etags[id] ??= 'e0-$id';

  /// Stores [note] on tilette [id] as the server would.
  void store(String id, String note) {
    _tilette(id)?.miscData = TileShareTemplateMiscData.fromJson({'userNote': note});
    _etags[id] = 'e${++_version}-$id';
  }

  NotesPayload _payload(String id, {bool conflict = false}) => NotesPayload(
        eventId: id,
        userNote: _tilette(id)?.miscData?.userNote ?? '',
        etag: _etagOf(id),
        concurrencyConflict: conflict,
      );

  @override
  Future<NotesPayload> getNotes(String eventId,
      {NotesScope scope = NotesScope.auto}) async {
    calls.add('get($eventId)');
    return _payload(eventId);
  }

  @override
  Future<NotesPayload> updateNotes({
    required String eventId,
    required String userNote,
    required String etag,
    NotesScope scope = NotesScope.auto,
  }) async {
    calls.add('put($eventId, $userNote, $etag)');
    if (conflictNext || etag != _etagOf(eventId)) {
      conflictNext = false;
      return _payload(eventId, conflict: true);
    }
    store(eventId, userNote);
    return _payload(eventId);
  }
}

/// Creating a share (R6): records each request as the JSON the API would
/// send, and answers with a new share id.
class FakeTileShareCreateSource
    with FakeSourceControls
    implements TileShareCreateSource {
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  String nextId = 'new-share';

  @override
  Future<String> createShare(TileShareClusterData share) {
    final Map<String, dynamic> json = share.toTemplateClusterModel().toJson();
    return run('createShare(${share.name})', () {
      requests.add(json);
      return nextId;
    });
  }
}
