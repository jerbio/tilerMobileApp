import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// The Attention inbox (redesign T7): what needs the user's attention across
/// TileShare — invitations to answer, accepted work that no longer fits, and
/// other people's edits, completions, declines and delivery problems.
///
/// * The three sources (invitations, activity feed, received tiles) load **in
///   parallel**; one failing never hides the others, and a source that fails
///   on a refresh keeps its last-known data.
/// * A refresh keeps the list on screen — the UI animates changes instead of
///   flashing empty.
/// * Dismissing an activity item is **optimistic**: it disappears at once, the
///   server is told per event, and a failure puts back exactly the events that
///   failed. The dismissal is stored server-side, so it also hides the item on
///   the next reload and on the user's other devices.
/// * An invitation is answered **inline** ([respond]): the card disappears at
///   once, the request is only sent after an undo window ([undoResponse]
///   inside it sends nothing), a failure puts back exactly what failed, and
///   leaving the screen ([flushPending], [close]) sends a pending answer
///   straight away. Only Broadcast and Class invitations can be answered
///   inline — a Class answers every task the user holds, a Project is reviewed
///   task by task instead.
/// * Each cluster's mode and name are resolved once and cached — the
///   Invitations endpoint does not carry the mode (the buttons on an
///   invitation depend on it) and an at-risk item knows no cluster title.
class TileShareAttentionCubit extends Cubit<TileShareAttentionState> {
  /// Page size for every source, and how many pages each may read. Attention
  /// is about what is recent, so the reads are bounded.
  static const int pageSize = 50;
  static const int maxInvitationPages = 5;
  static const int maxActivityPages = 3;
  static const int maxReceivedPages = 2;

  static const String _tag = 'TileShareAttention';

  /// How long an inline answer can still be undone before it is sent.
  static const Duration defaultUndoWindow = Duration(seconds: 5);

  /// The undo window in use; the UI keeps its "Undo" message up this long.
  final Duration undoWindow;

  final TileShareAttentionSources _attention;
  final TileShareAssignmentsSource _assignments;
  final TileShareClustersSource _clusters;
  final String? Function() _currentUserId;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _timerFactory;
  final void Function(String tag, Map<String, Object?> info) _analytics;

  List<TileShareInvitation> _invitations = const <TileShareInvitation>[];
  List<TileShareActivity> _activity = const <TileShareActivity>[];
  List<DesignatedTile> _received = const <DesignatedTile>[];
  final Map<String, TileShareMode> _modes = <String, TileShareMode>{};
  final Map<String, String> _titles = <String, String>{};

  /// Events the user dismissed (kept until the server confirms nothing else).
  final Set<String> _dismissedEvents = <String>{};

  /// Assignments the user answered.
  final Set<String> _answeredAssignments = <String>{};

  /// The events each dismissed item stood for — what an undo restores.
  final Map<String, List<String>> _dismissedByItem = <String, List<String>>{};

  /// Inline answers still inside their undo window (or being sent).
  final Map<String, _PendingResponse> _pending = <String, _PendingResponse>{};

  bool _hasLoaded = false;

  /// Bumped by every fetch; a slower, older fetch never overwrites a newer one.
  int _generation = 0;

  TileShareAttentionCubit({
    required TileShareAttentionSources attention,
    required TileShareAssignmentsSource assignments,
    required TileShareClustersSource clusters,
    String? Function()? currentUserId,
    DateTime Function()? clock,
    this.undoWindow = defaultUndoWindow,
    Timer Function(Duration, void Function())? timerFactory,
    void Function(String tag, Map<String, Object?> info)? analytics,
  })  : _attention = attention,
        _assignments = assignments,
        _clusters = clusters,
        _currentUserId = currentUserId ?? (() => null),
        _clock = clock ?? DateTime.now,
        _timerFactory = timerFactory ?? Timer.new,
        _analytics = analytics ??
            ((tag, info) {
              AnalysticsSignal.send(tag, additionalInfo: info);
            }),
        super(const TileShareAttentionState());

  // ---- loading -----------------------------------------------------------

  /// The first load shows a loading state; once something has loaded this is
  /// just a [refresh].
  Future<void> load() async {
    if (_hasLoaded) return refresh();
    _emit(state.copyWith(load: AttentionLoad.loading));
    await _fetch();
  }

  /// Reloads every source while the current items stay on screen.
  Future<void> refresh() async {
    if (!_hasLoaded) return load();
    _emit(state.copyWith(isRefreshing: true));
    await _fetch();
  }

  Future<void> _fetch() async {
    final int generation = ++_generation;
    // Start all three before awaiting any, so they run together.
    final invitations = _guard(_loadInvitations, 'invitations');
    final activity = _guard(_loadActivity, 'activity');
    final received = _guard(_loadReceived, 'received');
    final List<TileShareInvitation>? newInvitations = await invitations;
    final List<TileShareActivity>? newActivity = await activity;
    final List<DesignatedTile>? newReceived = await received;
    if (isClosed || generation != _generation) return;

    final Set<AttentionSource> failed = <AttentionSource>{};
    if (newInvitations == null) {
      failed.add(AttentionSource.invitations);
    } else {
      _invitations = newInvitations;
    }
    if (newActivity == null) {
      failed.add(AttentionSource.activity);
    } else {
      _activity = newActivity;
    }
    if (newReceived == null) {
      failed.add(AttentionSource.received);
    } else {
      _received = newReceived;
    }
    _hasLoaded = true;
    final List<AttentionItem> items = _derive();
    TileShareLog.d(
        _tag,
        'loaded invitations=${_invitations.length} '
        'activity=${_activity.length} received=${_received.length} '
        'types={${_activityTypes()}} -> ${items.length} items'
        '${failed.isEmpty ? '' : ' (failed: ${failed.map((s) => s.name).join(', ')})'}');
    _emit(state.copyWith(
      load: AttentionLoad.ready,
      isRefreshing: false,
      items: items,
      failedSources: failed,
    ));

    if (await _resolveModes()) {
      if (isClosed || generation != _generation) return;
      _emit(state.copyWith(items: _derive()));
    }
  }

  /// "assignment_declined:2, cluster_invitation:1" - what the feed held, so a
  /// feed that yields no cards can be told from one that failed.
  String _activityTypes() {
    final Map<String, int> counts = <String, int>{};
    for (final TileShareActivity event in _activity) {
      counts[event.eventType] = (counts[event.eventType] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}:${e.value}').join(', ');
  }

  /// Runs [body]; a failure becomes `null` (the caller keeps its last-known
  /// data) but is logged with its [label], so a source that keeps failing —
  /// say an endpoint that is not deployed yet — can be told apart and diagnosed
  /// instead of failing silently.
  static Future<T?> _guard<T>(Future<T> Function() body, String label) async {
    try {
      return await body();
    } catch (error) {
      TileShareLog.d(_tag, '$label failed: $error');
      return null;
    }
  }

  Future<List<TileShareInvitation>> _loadInvitations() async {
    final List<TileShareInvitation> all = <TileShareInvitation>[];
    String? afterId;
    for (int page = 0; page < maxInvitationPages; page++) {
      final TileShareInvitationPage result =
          await _attention.invitations(afterId: afterId, pageSize: pageSize);
      all.addAll(result.items);
      afterId = result.nextCursor;
      if (afterId == null) break;
    }
    return all;
  }

  Future<List<TileShareActivity>> _loadActivity() async {
    final List<TileShareActivity> all = <TileShareActivity>[];
    String? cursor;
    for (int page = 0; page < maxActivityPages; page++) {
      final TileShareActivityPage result =
          await _attention.activity(cursor: cursor, pageSize: pageSize);
      all.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return all;
  }

  Future<List<DesignatedTile>> _loadReceived() async {
    final List<DesignatedTile> all = <DesignatedTile>[];
    for (int page = 0; page < maxReceivedPages; page++) {
      final List<DesignatedTile> result = await _assignments.designatedTiles(
          index: page * pageSize, pageSize: pageSize);
      all.addAll(result);
      if (result.length < pageSize) break;
    }
    return all;
  }

  /// Looks up the mode and name of every cluster the inbox mentions and does
  /// not know yet. A failed lookup leaves them unknown (retried on the next
  /// load) and never blocks the item. Returns whether anything new was
  /// learned.
  Future<bool> _resolveModes() async {
    final Set<String> unknown = <String>{
      for (final AttentionItem item in state.items)
        if (!_modes.containsKey(item.clusterId)) item.clusterId,
    };
    if (unknown.isEmpty) return false;
    final List<TileShareClusterData?> found = await Future.wait(unknown.map(
        (String id) => _guard<TileShareClusterData?>(
            () => _clusters.cluster(id), 'cluster lookup $id')));
    bool learned = false;
    final List<String> ids = unknown.toList();
    for (int i = 0; i < ids.length; i++) {
      final TileShareClusterData? cluster = found[i];
      if (cluster != null) {
        _modes[ids[i]] = TileShareMode.fromCluster(cluster);
        final String? name = cluster.name?.trim();
        if (name != null && name.isNotEmpty) _titles[ids[i]] = name;
        learned = true;
      }
    }
    return learned;
  }

  List<AttentionItem> _derive() => AttentionItems.derive(
        now: _clock(),
        currentUserId: _currentUserId(),
        invitations: _invitations
            .where((i) => !_answeredAssignments.contains(i.assignmentId)),
        activity: _activity,
        received: _received,
        dismissedEventIds: _dismissedEvents,
        modes: _modes,
        clusterTitles: _titles,
      );

  // ---- acting on items ---------------------------------------------------

  /// Takes an item off the inbox. An invitation is hidden locally (answering
  /// it is a separate call); an activity-derived item is dismissed on the
  /// server, optimistically. Returns whether it worked — an at-risk item, or
  /// an unknown id, cannot be resolved.
  Future<bool> resolve(String itemId) async {
    final AttentionItem? item = _find(itemId);
    if (item == null) return false;

    if (item.type == AttentionType.invitation) {
      _answeredAssignments.addAll(item.assignmentIds);
      _emit(state.copyWith(items: _derive(), clearDismissFailure: true));
      return true;
    }
    if (item.eventIds.isEmpty) return false;

    final List<String> ids = List<String>.of(item.eventIds);
    _dismissedByItem[itemId] = ids;
    _dismissedEvents.addAll(ids);
    _emit(state.copyWith(items: _derive(), clearDismissFailure: true));

    final List<String> failed = await _send(ids, true);
    if (failed.isNotEmpty) {
      // Only what the server refused comes back; the rest stays dismissed.
      _dismissedEvents.removeAll(failed);
      final List<String> kept = ids.where((id) => !failed.contains(id)).toList();
      if (kept.isEmpty) {
        _dismissedByItem.remove(itemId);
      } else {
        _dismissedByItem[itemId] = kept;
      }
      _emit(state.copyWith(
          items: _derive(), dismissFailure: AttentionDismissFailure(itemId)));
    }
    return failed.isEmpty;
  }

  /// Restores an item that [resolve] dismissed. Returns whether the server
  /// accepted it; on failure the item is hidden again.
  Future<bool> undo(String itemId) async {
    final List<String>? ids = _dismissedByItem[itemId];
    if (ids == null || ids.isEmpty) return false;

    _dismissedEvents.removeAll(ids);
    _emit(state.copyWith(items: _derive(), clearDismissFailure: true));

    final List<String> failed = await _send(ids, false);
    if (failed.isEmpty) {
      _dismissedByItem.remove(itemId);
    } else {
      _dismissedEvents.addAll(failed);
      _dismissedByItem[itemId] = failed;
      _emit(state.copyWith(
          items: _derive(),
          dismissFailure: AttentionDismissFailure(itemId, wasUndo: true)));
    }
    return failed.isEmpty;
  }

  // ---- answering an invitation ------------------------------------------

  /// Accepts or declines an invitation card inline. The card disappears now;
  /// the request is sent once the undo window has passed. Returns whether it
  /// was taken: only a Broadcast or Class invitation (whose mode is known) that
  /// is not already being answered can be.
  bool respond(String itemId, InvitationStatus status) {
    if (status != InvitationStatus.accepted &&
        status != InvitationStatus.declined) {
      return false;
    }
    final AttentionItem? item = _find(itemId);
    if (item == null || item.type != AttentionType.invitation) return false;
    if (item.mode != TileShareMode.broadcast &&
        item.mode != TileShareMode.class_) {
      return false;
    }
    if (item.assignmentIds.isEmpty || _pending.containsKey(itemId)) {
      return false;
    }

    final _PendingResponse pending = _PendingResponse(
        itemId, status, List<String>.of(item.assignmentIds));
    _pending[itemId] = pending;
    _answeredAssignments.addAll(pending.assignmentIds);
    pending.timer = _timerFactory(undoWindow, () => _commit(pending));
    _emit(state.copyWith(
        items: _derive(),
        clearDismissFailure: true,
        clearRespondFailure: true));
    _analytics(
        status == InvitationStatus.accepted
            ? 'tileshare_accept'
            : 'tileshare_decline',
        {'mode': item.mode!.wire, 'tasks': pending.assignmentIds.length});
    TileShareLog.d(
        _tag,
        'answer ${status.name} $itemId (${item.mode!.wire}, '
        '${pending.assignmentIds.length} task(s)); sent in '
        '${undoWindow.inSeconds}s unless undone');
    return true;
  }

  /// Takes back an inline answer while it is still inside the undo window: the
  /// card returns and nothing is ever sent. `false` once the send has started
  /// (or if there was nothing pending).
  bool undoResponse(String itemId) {
    final _PendingResponse? pending = _pending[itemId];
    if (pending == null || pending.committing) return false;
    pending.timer?.cancel();
    _pending.remove(itemId);
    _answeredAssignments.removeAll(pending.assignmentIds);
    _emit(state.copyWith(items: _derive()));
    _analytics('tileshare_undo', {'tasks': pending.assignmentIds.length});
    TileShareLog.d(_tag, 'undo answer $itemId');
    return true;
  }

  /// Sends every pending answer now instead of waiting out its undo window —
  /// for when the user leaves the screen.
  Future<void> flushPending() => Future.wait(
      _pending.values.where((p) => !p.committing).toList().map(_commit));

  /// Sends the answers one after another, then (for an accept that saved at
  /// least one) refreshes the schedule once. Whatever the server refused comes
  /// back on the list; whatever it saved stays answered.
  Future<void> _commit(_PendingResponse pending) async {
    if (pending.committing) return;
    pending.committing = true;
    pending.timer?.cancel();

    final List<String> saved = <String>[];
    final List<String> refused = <String>[];
    for (final String assignmentId in pending.assignmentIds) {
      try {
        await _assignments.respond(assignmentId, pending.status);
        saved.add(assignmentId);
        TileShareLog.d(
            _tag, 'answer $assignmentId ${pending.status.name}: ok');
      } catch (error) {
        refused.add(assignmentId);
        TileShareLog.d(_tag,
            'answer $assignmentId ${pending.status.name} failed: $error');
      }
    }
    _pending.remove(pending.itemId);

    AttentionRespondFailure? failure;
    if (refused.isNotEmpty) {
      _answeredAssignments.removeAll(refused);
      failure = AttentionRespondFailure(pending.itemId, pending.status,
          AttentionRespondFailureKind.answer);
    }
    if (pending.status == InvitationStatus.accepted && saved.isNotEmpty) {
      try {
        await _assignments.afterAccept();
        TileShareLog.d(_tag, 'schedule refreshed after accepting');
      } catch (error) {
        TileShareLog.d(_tag, 'schedule refresh failed: $error');
        failure ??= AttentionRespondFailure(pending.itemId, pending.status,
            AttentionRespondFailureKind.scheduleRefresh);
      }
    }
    _emit(state.copyWith(
        items: _derive(),
        respondFailure: failure,
        answerRevision: state.answerRevision + 1));
  }

  /// The UI has shown the failure message.
  void acknowledgeFailure() {
    if (state.dismissFailure != null || state.respondFailure != null) {
      _emit(state.copyWith(
          clearDismissFailure: true, clearRespondFailure: true));
    }
  }

  @override
  Future<void> close() async {
    // A pending answer must not be lost because the screen was left.
    await flushPending();
    return super.close();
  }

  AttentionItem? _find(String itemId) {
    for (final AttentionItem item in state.items) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// Sends the dismissal for every event and returns the ids that failed.
  Future<List<String>> _send(List<String> ids, bool dismissed) async {
    final List<String?> results = await Future.wait(ids.map((String id) async {
      try {
        await _attention.setDismissed(id, dismissed);
        return null;
      } catch (error) {
        TileShareLog.d(_tag, 'setDismissed $id ($dismissed) failed: $error');
        return id;
      }
    }));
    return results.whereType<String>().toList();
  }

  void _emit(TileShareAttentionState next) {
    if (!isClosed) emit(next);
  }
}

/// An inline answer waiting out its undo window (or being sent).
class _PendingResponse {
  final String itemId;
  final InvitationStatus status;
  final List<String> assignmentIds;
  Timer? timer;
  bool committing = false;

  _PendingResponse(this.itemId, this.status, this.assignmentIds);
}
