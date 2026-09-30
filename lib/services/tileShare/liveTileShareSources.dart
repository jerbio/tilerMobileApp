import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

// Thin adapters from the seams to the existing API classes. They add no
// behaviour — arguments and results pass straight through and errors are not
// caught — so the cubits stay testable against fakes while the wire code stays
// where it is.

class LiveTileShareClustersSource implements TileShareClustersSource {
  final TileShareClusterApi _api;

  LiveTileShareClustersSource(this._api);

  @override
  Future<List<TileShareClusterData>> clusters({
    required bool isOutbox,
    int index = 0,
    int pageSize = 50,
  }) =>
      _api.getTileShareClusters(
          index: index, pageSize: pageSize, isOutbox: isOutbox);

  @override
  Future<TileShareClusterData?> cluster(String clusterId) async {
    final List<TileShareClusterData> found =
        await _api.getTileShareClusters(clusterId: clusterId);
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<List<TileShareTemplate>> tilettes(String clusterId) =>
      _api.getTileShareTemplates(clusterId: clusterId);

  @override
  Future<void> deleteCluster(String clusterId) async {
    await _api.deleteCluster(clusterId);
  }
}

class LiveTileShareAssignmentsSource implements TileShareAssignmentsSource {
  final TileShareClusterApi _api;
  final ScheduleApi _scheduleApi;

  LiveTileShareAssignmentsSource(this._api, this._scheduleApi);

  @override
  Future<List<DesignatedTile>> designatedTiles({
    String? clusterId,
    int index = 0,
    int pageSize = 50,
  }) =>
      _api.getDesignatedTiles(
          index: index, pageSize: pageSize, clusterId: clusterId);

  @override
  Future<DesignatedTile?> respond(
          String designatedTileId, InvitationStatus status) =>
      _api.statusUpdate(designatedTileId, status);

  @override
  Future<void> afterAccept() async {
    await _api.analyzeSchedule();
    await _scheduleApi.buzzSchedule();
  }
}

class LiveTileShareFitSource implements TileShareFitSource {
  final WhatIfApi _api;

  LiveTileShareFitSource(this._api);

  @override
  Future<ForecastResponse> forecast(Map<String, Object> params) =>
      _api.forecastNewTile(params);
}

class LiveTileShareAttentionSources implements TileShareAttentionSources {
  final TileShareInvitationsApi _invitations;
  final TileShareActivityApi _activity;

  /// The server answers an unscoped invitations call with a per-project
  /// summary only, so the flat list is built from one summary read plus one
  /// scoped read per project. These bound that work.
  static const int maxProjectPages = 5;
  static const int maxInvitationPagesPerProject = 10;
  static const int _projectsInFlight = 6;
  static const String _tag = 'TileShareInvitations';

  LiveTileShareAttentionSources(this._invitations, this._activity);

  /// The user's whole pending inbox as one flat list, returned as the first
  /// page (there is no next one). Any failure fails the whole read: a partial
  /// inbox must not be shown as the complete one.
  @override
  Future<TileShareInvitationPage> invitations(
      {String? afterId, int pageSize = 50}) async {
    if (afterId != null) return const TileShareInvitationPage([]);

    final List<TileShareInvitationProject> projects =
        <TileShareInvitationProject>[];
    String? cursor;
    for (int page = 0; page < maxProjectPages; page++) {
      final TileShareInvitationProjectPage read = await _invitations
          .getInvitationProjects(afterId: cursor, pageSize: pageSize);
      projects.addAll(read.items);
      cursor = read.nextCursor;
      if (cursor == null) break;
    }
    if (cursor != null) {
      TileShareLog.d(_tag,
          'project list cut after ${projects.length} projects (more exist)');
    }

    final List<TileShareInvitation> all = <TileShareInvitation>[];
    for (int i = 0; i < projects.length; i += _projectsInFlight) {
      final batch = projects.skip(i).take(_projectsInFlight);
      final results = await Future.wait(
          batch.map((p) => _readProject(p.clusterId, pageSize)));
      for (final r in results) {
        all.addAll(r);
      }
    }
    return TileShareInvitationPage(all);
  }

  Future<List<TileShareInvitation>> _readProject(
      String clusterId, int pageSize) async {
    final List<TileShareInvitation> all = <TileShareInvitation>[];
    String? cursor;
    for (int page = 0; page < maxInvitationPagesPerProject; page++) {
      final TileShareInvitationPage read = await _invitations.getInvitations(
          clusterId: clusterId, afterId: cursor, pageSize: pageSize);
      all.addAll(read.items);
      cursor = read.nextCursor;
      if (cursor == null) return all;
    }
    TileShareLog.d(_tag,
        'project $clusterId cut after ${all.length} invitations (more exist)');
    return all;
  }

  @override
  Future<TileShareActivityPage> activity({String? cursor, int pageSize = 50}) =>
      _activity.getActivity(cursor: cursor, pageSize: pageSize);

  @override
  Future<void> setDismissed(String eventId, bool isDismissed) =>
      _activity.setDismissed(eventId, isDismissed);
}
