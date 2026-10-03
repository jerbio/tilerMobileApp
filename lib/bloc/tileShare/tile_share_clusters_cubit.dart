import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/data/tileShareRsvpSummary.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// The Clusters list (redesign T6): what I created and what is shared with me,
/// behind one filter — All · Shared with me · Created by me.
///
/// * The two sources are **paged independently** (`Index` is an offset) and
///   merged by deadline — soonest first, no deadline last — so a row from a page
///   that loads later can land above rows already shown. Every filter uses the
///   same order, and a cluster both sources list is shown once, as mine.
/// * Switching filter only changes the view: every loaded page stays loaded and
///   nothing is requested.
/// * A refresh keeps the rows on screen and restarts paging from the first page;
///   a source that fails keeps its last rows.
/// * For clusters shared with me the row also carries **my own answer** (status
///   and task count), read from my assignments in the same load; it is optional
///   — without an assignments source, or if reading them fails, rows simply
///   have no status.
/// * The RSVP summary ("3 of 5 accepted") is not on the cluster; it is counted
///   from the cluster's tilettes ([TileShareRsvpSummary.forCluster], O2) and so
///   is requested lazily — the UI asks for the rows it shows — once per cluster,
///   and only for clusters I created. A failure never blocks the row. No cluster
///   progress figure exists (T13).
/// * [delete] is optimistic: the row disappears at once (and stays hidden even
///   if a refresh lands meanwhile); a refusal puts it back.
class TileShareClustersCubit extends Cubit<TileShareClustersState> {
  static const int defaultPageSize = 50;
  static const String _tag = 'TileShareClusters';

  final TileShareClustersSource _clusters;
  final TileShareAssignmentsSource? _assignments;

  /// The signed-in user: only their own assignments are "mine".
  final String? Function() _currentUserId;
  final int pageSize;

  /// How many pages of my assignments are read (they only feed the status).
  static const int maxAssignmentPages = 2;

  Map<String, MyClusterStatus> _mine = const <String, MyClusterStatus>{};

  final _Feed _created = _Feed();
  final _Feed _shared = _Feed();

  final Map<String, TileShareRsvpSummary> _summaries =
      <String, TileShareRsvpSummary>{};
  final Set<String> _summaryRequested = <String>{};
  final Set<String> _summaryFailed = <String>{};
  final Map<String, Future<void>> _summaryInFlight = <String, Future<void>>{};

  /// Clusters being deleted: hidden from the list until the server answers.
  final Set<String> _deleting = <String>{};

  bool _hasLoaded = false;

  /// Bumped by every first-page fetch; a slower, older result never overwrites
  /// a newer one.
  int _generation = 0;
  Future<void>? _moreInFlight;

  TileShareClustersCubit({
    required TileShareClustersSource clusters,
    TileShareAssignmentsSource? assignments,
    required String? Function() currentUserId,
    this.pageSize = defaultPageSize,
  })  : _clusters = clusters,
        _assignments = assignments,
        _currentUserId = currentUserId,
        super(const TileShareClustersState());

  // ---- loading -----------------------------------------------------------

  /// The first load shows a loading state; once something has loaded this is
  /// just a [refresh].
  Future<void> load() async {
    if (_hasLoaded) return refresh();
    _emit(state.copyWith(load: ClustersLoad.loading));
    await _fetchFirstPages();
  }

  /// Reloads the first page of both sources while the rows stay on screen.
  Future<void> refresh() async {
    if (!_hasLoaded) return load();
    _emit(state.copyWith(isRefreshing: true));
    await _fetchFirstPages();
  }

  Future<void> _fetchFirstPages() async {
    final int generation = ++_generation;
    // Start both before awaiting either, so they run together.
    final created = _guard(
        () => _clusters.clusters(isOutbox: true, index: 0, pageSize: pageSize),
        'createdByMe');
    final shared = _guard(
        () => _clusters.clusters(isOutbox: false, index: 0, pageSize: pageSize),
        'sharedWithMe');
    final mine = _guard(_loadMine, 'mine');
    final List<TileShareClusterData>? createdPage = await created;
    final List<TileShareClusterData>? sharedPage = await shared;
    final Map<String, MyClusterStatus>? minePage = await mine;
    if (isClosed || generation != _generation) return;

    final Set<ClusterSource> failed = <ClusterSource>{};
    if (createdPage == null) {
      failed.add(ClusterSource.createdByMe);
    } else {
      _created.restart(createdPage, pageSize);
    }
    if (sharedPage == null) {
      failed.add(ClusterSource.sharedWithMe);
    } else {
      _shared.restart(sharedPage, pageSize);
    }
    if (minePage != null) _mine = minePage;
    _hasLoaded = true;
    // Counts already shown stay until the next request replaces them.
    _summaryRequested.clear();

    TileShareLog.d(
        _tag,
        'loaded created=${_created.items.length} '
        'shared=${_shared.items.length} '
        'mine=${_assignments == null ? 'off' : _mineTiles}'
        '${failed.isEmpty ? '' : ' (failed: ${failed.map((s) => s.name).join(', ')})'}');
    _emit(state.copyWith(
      load: ClustersLoad.ready,
      isRefreshing: false,
      isLoadingMore: false,
      loadMoreFailed: false,
      items: _view(state.filter),
      failedSources: failed,
      hasMore: _hasMore(state.filter),
    ));
  }

  int _mineTiles = 0;

  /// My assignments, grouped per cluster; `null` when there is no source.
  Future<Map<String, MyClusterStatus>?> _loadMine() async {
    final TileShareAssignmentsSource? source = _assignments;
    if (source == null) return const <String, MyClusterStatus>{};
    final List<DesignatedTile> all = <DesignatedTile>[];
    for (int page = 0; page < maxAssignmentPages; page++) {
      final List<DesignatedTile> result = await source.designatedTiles(
          index: page * pageSize, pageSize: pageSize);
      all.addAll(result);
      if (result.length < pageSize) break;
    }
    _mineTiles = all.length;
    final String? me = _currentUserId();
    final int others =
        all.where((t) => me == null || t.designatedUserId != me).length;
    if (others > 0) {
      TileShareLog.d(
          _tag,
          me == null
              ? 'signed-in user unknown: none of ${all.length} designated '
                  'tile templates counted as mine'
              : '$others of ${all.length} designated tile templates are '
                  'designated to someone else (or to no known user) and are '
                  'ignored; signed in as $me, e.g. ${all.where((t) => t.designatedUserId != me).take(3).map((t) => '${t.id} -> ${t.designatedUserId ?? 'no entry'}').join('; ')}');
    }
    return MyClusterStatus.byCluster(all, userId: me);
  }

  /// Runs [body]; a failure becomes `null` but is logged with its [label].
  static Future<T?> _guard<T>(Future<T> Function() body, String label) async {
    try {
      return await body();
    } catch (error) {
      TileShareLog.d(_tag, '$label failed: $error');
      return null;
    }
  }

  // ---- filter and paging -------------------------------------------------

  /// Shows another slice of what is already loaded; asks the server nothing.
  void setFilter(ClusterFilter filter) {
    if (filter == state.filter) return;
    _emit(state.copyWith(
      filter: filter,
      items: _view(filter),
      hasMore: _hasMore(filter),
      loadMoreFailed: false,
    ));
  }

  /// Reads the next page of every source the current filter shows that has
  /// one. Overlapping calls share one request per source.
  Future<void> loadMore() {
    final Future<void>? running = _moreInFlight;
    if (running != null) return running;
    final List<_Feed> feeds =
        _feedsFor(state.filter).where((f) => f.hasMore).toList();
    if (feeds.isEmpty) return Future<void>.value();
    final Future<void> started = _loadMore(feeds).whenComplete(() {
      _moreInFlight = null;
    });
    return _moreInFlight = started;
  }

  Future<void> _loadMore(List<_Feed> feeds) async {
    final int generation = _generation;
    _emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final List<List<TileShareClusterData>?> pages = await Future.wait(feeds.map(
        (feed) => _guard(
            () => _clusters.clusters(
                isOutbox: identical(feed, _created),
                index: feed.nextIndex,
                pageSize: pageSize),
            identical(feed, _created)
                ? 'createdByMe page'
                : 'sharedWithMe page')));
    if (isClosed || generation != _generation) return;

    bool anyFailed = false;
    for (int i = 0; i < feeds.length; i++) {
      final List<TileShareClusterData>? page = pages[i];
      if (page == null) {
        anyFailed = true;
      } else {
        feeds[i].append(page, pageSize);
      }
    }
    _emit(state.copyWith(
      isLoadingMore: false,
      loadMoreFailed: anyFailed,
      items: _view(state.filter),
      hasMore: _hasMore(state.filter),
    ));
  }

  List<_Feed> _feedsFor(ClusterFilter filter) {
    switch (filter) {
      case ClusterFilter.all:
        return [_created, _shared];
      case ClusterFilter.createdByMe:
        return [_created];
      case ClusterFilter.sharedWithMe:
        return [_shared];
    }
  }

  bool _hasMore(ClusterFilter filter) =>
      _feedsFor(filter).any((feed) => feed.hasMore);

  // ---- the rows ----------------------------------------------------------

  /// Both sources merged (mine win a duplicate), hidden deletes removed, in
  /// deadline order, then narrowed to [filter].
  List<ClusterListItem> _view(ClusterFilter filter) {
    final Map<String, ClusterListItem> byId = <String, ClusterListItem>{};
    void add(_Feed feed, bool createdByMe) {
      for (final TileShareClusterData cluster in feed.items) {
        final String id = cluster.id ?? '';
        if (id.isEmpty || _deleting.contains(id) || byId.containsKey(id)) {
          continue;
        }
        byId[id] = ClusterListItem(
          cluster: cluster,
          createdByMe: createdByMe,
          mode: TileShareMode.fromCluster(cluster),
          rsvp: createdByMe ? _summaries[id] : null,
          rsvpFailed: createdByMe && _summaryFailed.contains(id),
          mine: createdByMe ? null : _mine[id],
        );
      }
    }

    add(_created, true);
    add(_shared, false);

    final List<ClusterListItem> rows = byId.values.where((row) {
      switch (filter) {
        case ClusterFilter.all:
          return true;
        case ClusterFilter.createdByMe:
          return row.createdByMe;
        case ClusterFilter.sharedWithMe:
          return !row.createdByMe;
      }
    }).toList();
    rows.sort(_byDeadline);
    return rows;
  }

  static int _byDeadline(ClusterListItem a, ClusterListItem b) {
    final int? x = a.cluster.endTimeInMs;
    final int? y = b.cluster.endTimeInMs;
    if (x != y) {
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    }
    return a.id.compareTo(b.id);
  }

  // ---- RSVP summary ------------------------------------------------------

  /// Counts who accepted / declined / has not answered for a cluster I created,
  /// from its tilettes. Asked once per cluster (until a refresh), so the UI can
  /// call this for every row it shows; a failure marks the row and is not
  /// retried until [retrySummary].
  Future<void> ensureSummary(String clusterId) {
    final Future<void>? inFlight = _summaryInFlight[clusterId];
    if (inFlight != null) return inFlight;
    if (_summaryRequested.contains(clusterId)) return Future<void>.value();
    final TileShareClusterData? cluster = _created.find(clusterId);
    if (cluster == null || _deleting.contains(clusterId)) {
      return Future<void>.value();
    }
    _summaryRequested.add(clusterId);
    final Future<void> started =
        _fetchSummary(clusterId, cluster).whenComplete(() {
      // A block body: returning the removed future would make it wait on itself.
      _summaryInFlight.remove(clusterId);
    });
    return _summaryInFlight[clusterId] = started;
  }

  /// Asks again after a failure; the failure marker stays until it answers.
  Future<void> retrySummary(String clusterId) {
    _summaryRequested.remove(clusterId);
    return ensureSummary(clusterId);
  }

  Future<void> _fetchSummary(
      String clusterId, TileShareClusterData cluster) async {
    try {
      final List<TileShareTemplate> tilettes =
          await _clusters.tilettes(clusterId);
      _summaries[clusterId] = TileShareRsvpSummary.forCluster(
          TileShareMode.fromCluster(cluster), tilettes);
      _summaryFailed.remove(clusterId);
    } catch (error) {
      _summaryFailed.add(clusterId);
      TileShareLog.d(_tag, 'rsvp summary $clusterId failed: $error');
    }
    _emit(state.copyWith(items: _view(state.filter)));
  }

  // ---- delete ------------------------------------------------------------

  /// Deletes a cluster I created. The row disappears now; `false` comes back
  /// (with [TileShareClustersState.deleteFailure]) and the row returns if the
  /// server refuses, or at once if it is not one of mine / already being
  /// deleted.
  Future<bool> delete(String clusterId) async {
    final TileShareClusterData? cluster = _created.find(clusterId);
    if (_deleting.contains(clusterId) || cluster == null) {
      return false;
    }
    _deleting.add(clusterId);
    _emit(state.copyWith(items: _view(state.filter), clearDeleteFailure: true));
    try {
      await _clusters.deleteCluster(clusterId);
    } catch (error) {
      TileShareLog.d(_tag, 'delete $clusterId failed: $error');
      _deleting.remove(clusterId);
      _emit(state.copyWith(
          items: _view(state.filter),
          deleteFailure: ClusterDeleteFailure(clusterId, name: cluster.name)));
      return false;
    }
    TileShareLog.d(_tag, 'delete $clusterId: ok');
    _created.remove(clusterId);
    _summaries.remove(clusterId);
    _summaryRequested.remove(clusterId);
    _summaryFailed.remove(clusterId);
    _deleting.remove(clusterId);
    _emit(state.copyWith(
        items: _view(state.filter), hasMore: _hasMore(state.filter)));
    return true;
  }

  /// The UI has shown the failure message.
  void acknowledgeFailure() {
    if (state.deleteFailure != null) {
      _emit(state.copyWith(clearDeleteFailure: true));
    }
  }

  void _emit(TileShareClustersState next) {
    if (!isClosed) emit(next);
  }
}

/// One source's loaded pages.
class _Feed {
  List<TileShareClusterData> items = <TileShareClusterData>[];

  /// The offset of the next page: how many rows the server has given so far.
  int nextIndex = 0;
  bool hasMore = false;

  void restart(List<TileShareClusterData> page, int pageSize) {
    items = <TileShareClusterData>[];
    nextIndex = 0;
    append(page, pageSize);
  }

  /// Adds the rows not already held; a full page means there may be more.
  void append(List<TileShareClusterData> page, int pageSize) {
    final Set<String?> known = items.map((c) => c.id).toSet();
    for (final TileShareClusterData cluster in page) {
      if (known.add(cluster.id)) items.add(cluster);
    }
    nextIndex += page.length;
    hasMore = page.length >= pageSize;
  }

  TileShareClusterData? find(String id) {
    for (final TileShareClusterData cluster in items) {
      if (cluster.id == id) return cluster;
    }
    return null;
  }

  void remove(String id) => items.removeWhere((c) => c.id == id);
}
