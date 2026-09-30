import 'package:bloc/bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareMode.dart';
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
/// * An invitation the user answered disappears locally; the response itself
///   is sent elsewhere.
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

  final TileShareAttentionSources _attention;
  final TileShareAssignmentsSource _assignments;
  final TileShareClustersSource _clusters;
  final String? Function() _currentUserId;
  final DateTime Function() _clock;

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

  bool _hasLoaded = false;

  /// Bumped by every fetch; a slower, older fetch never overwrites a newer one.
  int _generation = 0;

  TileShareAttentionCubit({
    required TileShareAttentionSources attention,
    required TileShareAssignmentsSource assignments,
    required TileShareClustersSource clusters,
    String? Function()? currentUserId,
    DateTime Function()? clock,
  })  : _attention = attention,
        _assignments = assignments,
        _clusters = clusters,
        _currentUserId = currentUserId ?? (() => null),
        _clock = clock ?? DateTime.now,
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
    final invitations = _guard(_loadInvitations);
    final activity = _guard(_loadActivity);
    final received = _guard(_loadReceived);
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
    _emit(state.copyWith(
      load: AttentionLoad.ready,
      isRefreshing: false,
      items: _derive(),
      failedSources: failed,
    ));

    if (await _resolveModes()) {
      if (isClosed || generation != _generation) return;
      _emit(state.copyWith(items: _derive()));
    }
  }

  static Future<T?> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (_) {
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
        (String id) => _guard<TileShareClusterData?>(() => _clusters.cluster(id))));
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

  /// The UI has shown the dismissal failure.
  void acknowledgeFailure() {
    if (state.dismissFailure != null) {
      _emit(state.copyWith(clearDismissFailure: true));
    }
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
      } catch (_) {
        return id;
      }
    }));
    return results.whereType<String>().toList();
  }

  void _emit(TileShareAttentionState next) {
    if (!isClosed) emit(next);
  }
}
