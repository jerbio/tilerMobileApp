import 'package:bloc/bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

export 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart'
    show TileShareDetailTarget, DetailEdit;

/// One cluster's detail (redesign T10), whatever its mode and whoever is
/// looking: the cluster, its tilettes, and the signed-in user's own designated
/// tile templates in it.
///
/// * Opens from a cluster id, from one of its designated tile templates (its
///   cluster is looked up first), or from a cluster already in hand (shown at
///   once, then brought up to date).
/// * The owner is the cluster's creator, matched by id; without a signed-in
///   user the caller's hint decides, and ownership is never assumed.
/// * "Mine" is only templates designated to the signed-in user.
/// * Reloading keeps what is shown: no spinner over content, a failure keeps
///   the content and says so. Tilettes that fail leave the cluster showing.
/// * A response that arrives after a newer load, or after closing, is dropped.
/// * The owner edits the share and its tasks (Step 9.16b), one change at a
///   time; each is reloaded once it went through, and a refused one keeps
///   what is shown and says which it was.
class TileShareDetailCubit extends Cubit<TileShareDetailState> {
  static const String _tag = 'TileShareDetail';

  final TileShareClustersSource _clusters;
  final TileShareAssignmentsSource? _assignments;
  final TileShareEditSource? _edits;
  final TileShareDetailTarget target;
  final String? Function() _currentUserId;
  final bool? _ownerHint;

  /// The last refused change, sent again by [retryEdit].
  Future<bool> Function()? _retry;

  /// The cluster the target resolved to.
  String? _clusterId;
  int _generation = 0;

  TileShareDetailCubit({
    required TileShareClustersSource clusters,
    TileShareAssignmentsSource? assignments,
    TileShareEditSource? edits,
    required this.target,
    required String? Function() currentUserId,
    bool? ownerHint,
  })  : _clusters = clusters,
        _assignments = assignments,
        _edits = edits,
        _currentUserId = currentUserId,
        _ownerHint = ownerHint,
        _clusterId = target.clusterId,
        super(target.data == null
            ? const TileShareDetailState()
            : TileShareDetailState(
                phase: DetailPhase.ready,
                cluster: target.data,
                isOwner: _owner(target.data!, currentUserId(), ownerHint),
              ));

  static bool _owner(
      TileShareClusterData cluster, String? me, bool? ownerHint) {
    final String? creator = cluster.creator?.id;
    if (me != null && me.isNotEmpty && creator != null && creator.isNotEmpty) {
      return creator == me;
    }
    return ownerHint ?? false;
  }

  bool get _hasContent =>
      state.phase == DetailPhase.ready && state.cluster != null;

  /// Loads the detail: a skeleton the first time, a refresh once something is
  /// shown.
  Future<void> load() => _fetch();

  /// Reloads, keeping what is shown; the first load when nothing is.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final int generation = ++_generation;
    final bool keep = _hasContent;
    _emit(keep
        ? state.copyWith(isRefreshing: true)
        : const TileShareDetailState(phase: DetailPhase.loading));
    try {
      String? id = _clusterId;
      if (id == null) {
        final String? designated = target.designatedTileId;
        final DesignatedTile? tile = designated == null
            ? null
            : await _assignments?.designatedTile(designated);
        if (_outdated(generation)) return;
        id = tile?.tileTemplate?.clusterId;
        if (id == null || id.isEmpty) {
          TileShareLog.d(_tag,
              'designated tile template $designated has no visible cluster');
          _emit(const TileShareDetailState(phase: DetailPhase.notFound));
          return;
        }
        _clusterId = id;
      }

      final String clusterId = id;
      final Future<List<TileShareTemplate>?> tilettes =
          _quietly(() => _clusters.tilettes(clusterId), 'tilettes');
      final Future<List<DesignatedTile>?> designated = _quietly(
          () async =>
              await _assignments?.designatedTiles(clusterId: clusterId) ??
              const <DesignatedTile>[],
          'my templates');
      final TileShareClusterData? cluster = await _clusters.cluster(clusterId);
      final List<TileShareTemplate>? loadedTilettes = await tilettes;
      final List<DesignatedTile>? loadedDesignated = await designated;
      if (_outdated(generation)) return;
      if (cluster == null) {
        TileShareLog.d(_tag, 'cluster $clusterId not found');
        _emit(const TileShareDetailState(phase: DetailPhase.notFound));
        return;
      }

      final String? me = _currentUserId();
      final List<DesignatedTile> mine = loadedDesignated == null
          ? state.mine
          : (me == null
              ? const <DesignatedTile>[]
              : loadedDesignated
                  .where((t) => t.designatedUserId == me)
                  .toList());
      final MyClusterStatus? myStatus =
          MyClusterStatus.byCluster(mine, userId: me)[clusterId];
      final bool isOwner = _owner(cluster, me, _ownerHint);
      TileShareLog.d(
          _tag,
          'loaded $clusterId: ${isOwner ? 'owner' : 'recipient'}, '
          'tilettes=${loadedTilettes?.length ?? 'failed'}, mine=${mine.length}');
      _emit(TileShareDetailState(
        phase: DetailPhase.ready,
        cluster: cluster,
        tilettes: loadedTilettes == null
            ? state.tilettes
            : List<TileShareTemplate>.unmodifiable(loadedTilettes),
        mine: mine,
        myStatus: myStatus,
        isOwner: isOwner,
        tilettesFailed: loadedTilettes == null,
        isSaving: state.isSaving,
        editFailed: state.editFailed,
      ));
    } catch (error) {
      if (_outdated(generation)) return;
      TileShareLog.d(_tag, 'loading ${_clusterId ?? target.designatedTileId} '
          'failed: $error');
      _emit(keep
          ? state.copyWith(isRefreshing: false, refreshFailed: true)
          : const TileShareDetailState(phase: DetailPhase.error));
    }
  }

  /// Whether the signed-in user can change this share now.
  bool get canEdit => _edits != null && _hasContent && state.isOwner;

  /// Renames the share or moves its deadline.
  Future<bool> updateShare({String? name, int? endMs}) =>
      _edit(DetailEdit.share, 'share: name=$name end=$endMs',
          (edits, id) => edits.updateShare(id, name: name, endMs: endMs));

  /// Adds [task] to the share.
  Future<bool> addTask(ClusterTemplateTileModel task) => _edit(
      DetailEdit.addTask,
      'add task "${task.Name}" for ${task.Contacts?.length ?? 0}',
      (edits, id) => edits.addTask(id, task..ClusterId = id));

  /// Renames a task or moves its deadline.
  Future<bool> updateTask(String tiletteId, {String? name, int? endMs}) =>
      _edit(DetailEdit.editTask, 'task $tiletteId: name=$name end=$endMs',
          (edits, _) => edits.updateTask(tiletteId, name: name, endMs: endMs));

  /// Deletes a task.
  Future<bool> deleteTask(String tiletteId) => _edit(DetailEdit.deleteTask,
      'delete task $tiletteId', (edits, _) => edits.deleteTask(tiletteId));

  /// Sends the last refused change again; `false` when there is none.
  Future<bool> retryEdit() {
    final Future<bool> Function()? retry = _retry;
    return retry == null ? Future<bool>.value(false) : retry();
  }

  /// Sends one change, then reloads. `false` when it was not sent (no edits,
  /// not the owner, another change going out) or was refused.
  Future<bool> _edit(DetailEdit kind, String what,
      Future<void> Function(TileShareEditSource edits, String clusterId) send) async {
    final TileShareEditSource? edits = _edits;
    final String? clusterId = _clusterId;
    if (!canEdit || edits == null || clusterId == null || state.isSaving) {
      return false;
    }
    _emit(state.copyWith(isSaving: true, clearEditFailed: true));
    try {
      await send(edits, clusterId);
    } catch (error) {
      TileShareLog.d(_tag, '$what failed: $error');
      _retry = () => _edit(kind, what, send);
      _emit(state.copyWith(isSaving: false, editFailed: kind));
      return false;
    }
    _retry = null;
    TileShareLog.d(_tag, '$what sent');
    _emit(state.copyWith(isSaving: false));
    await refresh();
    return true;
  }

  /// Runs [body]; a failure is logged under [what] and becomes `null`.
  Future<T?> _quietly<T>(Future<T> Function() body, String what) async {
    try {
      return await body();
    } catch (error) {
      TileShareLog.d(_tag, 'loading $what failed: $error');
      return null;
    }
  }

  bool _outdated(int generation) => isClosed || generation != _generation;

  void _emit(TileShareDetailState next) {
    if (!isClosed) emit(next);
  }
}
