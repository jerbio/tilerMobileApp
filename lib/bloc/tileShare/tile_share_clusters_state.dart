import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/data/tileShareRsvpSummary.dart';

/// Which clusters the Clusters list shows (redesign T6).
enum ClusterFilter { all, sharedWithMe, createdByMe }

/// Where the list is in its life.
enum ClustersLoad {
  /// Nothing requested yet.
  initial,

  /// The first load is in flight (there is nothing to show yet).
  loading,

  /// At least one load has finished; [TileShareClustersState.items] is what
  /// the sources gave (possibly stale for a source that failed).
  ready,
}

/// The two places the list reads from.
enum ClusterSource { createdByMe, sharedWithMe }

/// One row of the Clusters list.
class ClusterListItem extends Equatable {
  final TileShareClusterData cluster;

  /// I created it (it came from the Outbox) rather than it being shared with
  /// me.
  final bool createdByMe;
  final TileShareMode mode;

  /// "3 of 5 accepted" — RSVP status counted from the cluster's tilettes; only
  /// ever set for clusters I created, and only once it has been requested.
  /// This is status, never progress (T13).
  final TileShareRsvpSummary? rsvp;

  /// The last attempt to count it failed; the row is fine without it.
  final bool rsvpFailed;

  /// What I have answered, for a cluster shared with me in which I hold tasks;
  /// `null` for one I created, or when my assignments could not be read.
  final MyClusterStatus? mine;

  const ClusterListItem({
    required this.cluster,
    required this.createdByMe,
    required this.mode,
    this.rsvp,
    this.rsvpFailed = false,
    this.mine,
  });

  String get id => cluster.id ?? '';

  @override
  List<Object?> get props =>
      [cluster, createdByMe, mode, rsvp, rsvpFailed, mine];

  @override
  String toString() => 'ClusterListItem($id, ${mode.wire}, '
      '${createdByMe ? 'created by me' : 'shared with me'}, '
      'rsvp: ${rsvp == null ? 'none' : '${rsvp!.accepted}/${rsvp!.total}'}'
      '${rsvpFailed ? ', rsvp failed' : ''}'
      '${mine == null ? '' : ', mine: ${mine!.answer.name} of ${mine!.taskCount}'})';
}

/// A delete the server refused; the row was put back.
class ClusterDeleteFailure extends Equatable {
  final String clusterId;

  /// Its name, for a message that says which one came back.
  final String? name;

  const ClusterDeleteFailure(this.clusterId, {this.name});

  @override
  List<Object?> get props => [clusterId, name];
}

class TileShareClustersState extends Equatable {
  final ClustersLoad load;

  /// A reload is in flight while [items] stays on screen.
  final bool isRefreshing;
  final ClusterFilter filter;

  /// The rows for [filter], in deadline order.
  final List<ClusterListItem> items;

  /// Sources whose last load failed; their last-known rows are still shown.
  final Set<ClusterSource> failedSources;

  /// Another page exists for the sources [filter] shows.
  final bool hasMore;
  final bool isLoadingMore;

  /// The last attempt to read another page failed (the rows are unchanged).
  final bool loadMoreFailed;
  final ClusterDeleteFailure? deleteFailure;

  const TileShareClustersState({
    this.load = ClustersLoad.initial,
    this.isRefreshing = false,
    this.filter = ClusterFilter.all,
    this.items = const <ClusterListItem>[],
    this.failedSources = const <ClusterSource>{},
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.deleteFailure,
  });

  TileShareClustersState copyWith({
    ClustersLoad? load,
    bool? isRefreshing,
    ClusterFilter? filter,
    List<ClusterListItem>? items,
    Set<ClusterSource>? failedSources,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    ClusterDeleteFailure? deleteFailure,
    bool clearDeleteFailure = false,
  }) =>
      TileShareClustersState(
        load: load ?? this.load,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        filter: filter ?? this.filter,
        items: items ?? this.items,
        failedSources: failedSources ?? this.failedSources,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        deleteFailure:
            clearDeleteFailure ? null : (deleteFailure ?? this.deleteFailure),
      );

  @override
  List<Object?> get props => [
        load,
        isRefreshing,
        filter,
        items,
        failedSources,
        hasMore,
        isLoadingMore,
        loadMoreFailed,
        deleteFailure,
      ];
}
