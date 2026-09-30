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

  LiveTileShareAttentionSources(this._invitations, this._activity);

  @override
  Future<TileShareInvitationPage> invitations(
          {String? afterId, int pageSize = 50}) =>
      _invitations.getInvitations(afterId: afterId, pageSize: pageSize);

  @override
  Future<TileShareActivityPage> activity({String? cursor, int pageSize = 50}) =>
      _activity.getActivity(cursor: cursor, pageSize: pageSize);

  @override
  Future<void> setDismissed(String eventId, bool isDismissed) =>
      _activity.setDismissed(eventId, isDismissed);
}
