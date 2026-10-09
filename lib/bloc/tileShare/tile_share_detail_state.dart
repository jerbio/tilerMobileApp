import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

enum DetailPhase { idle, loading, ready, notFound, error }

/// An owner's change to the share (Step 9.16b).
enum DetailEdit { share, addTask, editTask, deleteTask, deleteShare }

/// Which detail a cluster opens as (T10): the owner's view of its mode, or the
/// recipient's commitment whatever the mode.
enum DetailVariant { broadcast, classMode, project, commitment }

/// Where a detail is opened from: a cluster id, one of the cluster's
/// designated tile templates (a shared tile on the schedule), or a cluster
/// already in hand.
class TileShareDetailTarget {
  final String? clusterId;
  final String? designatedTileId;
  final TileShareClusterData? data;

  const TileShareDetailTarget.cluster(String this.clusterId)
      : designatedTileId = null,
        data = null;

  const TileShareDetailTarget.designatedTile(String this.designatedTileId)
      : clusterId = null,
        data = null;

  TileShareDetailTarget.data(TileShareClusterData this.data)
      : clusterId = data.id,
        designatedTileId = null;
}

class TileShareDetailState extends Equatable {
  final DetailPhase phase;
  final TileShareClusterData? cluster;

  /// The cluster's tilettes (its tasks), each with its assignments.
  final List<TileShareTemplate> tilettes;

  /// The signed-in user's own designated tile templates in the cluster.
  final List<DesignatedTile> mine;

  /// What the signed-in user has answered here; `null` when they hold nothing.
  final MyClusterStatus? myStatus;
  final bool isOwner;

  /// A reload is running while the content stays on screen.
  final bool isRefreshing;

  /// The last reload failed; what is shown is what was loaded before.
  final bool refreshFailed;

  /// The tilettes could not be loaded; the cluster itself is shown.
  final bool tilettesFailed;

  /// An owner's change is going out.
  final bool isSaving;

  /// The last change the owner made was refused; nothing of it was applied.
  final DetailEdit? editFailed;

  /// The owner deleted the share; the detail closes.
  final bool deleted;

  const TileShareDetailState({
    this.phase = DetailPhase.idle,
    this.cluster,
    this.tilettes = const <TileShareTemplate>[],
    this.mine = const <DesignatedTile>[],
    this.myStatus,
    this.isOwner = false,
    this.isRefreshing = false,
    this.refreshFailed = false,
    this.tilettesFailed = false,
    this.isSaving = false,
    this.editFailed,
    this.deleted = false,
  });

  /// The cluster's mode; a cluster that predates modes falls back to the
  /// legacy mapping.
  TileShareMode? get mode {
    final TileShareClusterData? c = cluster;
    if (c == null) return null;
    return c.mode ?? TileShareMode.fromCluster(c);
  }

  DetailVariant get variant {
    if (!isOwner) return DetailVariant.commitment;
    switch (mode) {
      case TileShareMode.broadcast:
      case null:
        return DetailVariant.broadcast;
      case TileShareMode.class_:
        return DetailVariant.classMode;
      case TileShareMode.project:
        return DetailVariant.project;
    }
  }

  TileShareDetailState copyWith({
    DetailPhase? phase,
    TileShareClusterData? cluster,
    List<TileShareTemplate>? tilettes,
    List<DesignatedTile>? mine,
    MyClusterStatus? myStatus,
    bool clearMyStatus = false,
    bool? isOwner,
    bool? isRefreshing,
    bool? refreshFailed,
    bool? tilettesFailed,
    bool? isSaving,
    DetailEdit? editFailed,
    bool clearEditFailed = false,
    bool? deleted,
  }) =>
      TileShareDetailState(
        phase: phase ?? this.phase,
        cluster: cluster ?? this.cluster,
        tilettes: tilettes ?? this.tilettes,
        mine: mine ?? this.mine,
        myStatus: clearMyStatus ? null : (myStatus ?? this.myStatus),
        isOwner: isOwner ?? this.isOwner,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        refreshFailed: refreshFailed ?? this.refreshFailed,
        tilettesFailed: tilettesFailed ?? this.tilettesFailed,
        isSaving: isSaving ?? this.isSaving,
        editFailed: clearEditFailed ? null : (editFailed ?? this.editFailed),
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props => [
        phase,
        cluster,
        tilettes,
        mine,
        myStatus,
        isOwner,
        isRefreshing,
        refreshFailed,
        tilettesFailed,
        isSaving,
        editFailed,
        deleted,
      ];
}
