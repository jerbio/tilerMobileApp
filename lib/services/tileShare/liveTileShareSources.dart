import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
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

  /// Reads one designated tile template; only needed by [designatedTile].
  final DesignatedTileApi? _designatedTileApi;

  LiveTileShareAssignmentsSource(this._api, this._scheduleApi,
      {DesignatedTileApi? designatedTileApi})
      : _designatedTileApi = designatedTileApi;

  @override
  Future<DesignatedTile?> designatedTile(String designatedTileId) async {
    final DesignatedTileApi? api = _designatedTileApi;
    if (api == null) {
      throw StateError('designatedTile needs a DesignatedTileApi');
    }
    final List<DesignatedTile> found =
        await api.getDesignatedTiles(designatedTileId: designatedTileId);
    return found.isEmpty ? null : found.first;
  }

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

class LiveTileSharePreviewSource implements TileSharePreviewSource {
  final TileSharePreviewApi _api;

  LiveTileSharePreviewSource(this._api);

  @override
  Future<TileSharePreview> preview(String assignmentId) =>
      _api.preview(assignmentId);

  @override
  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  }) =>
      _api.options(
          assignmentId: assignmentId,
          previewToken: previewToken,
          sessionKey: sessionKey,
          offset: offset);

  @override
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  }) =>
      _api.revise(
          assignmentId: assignmentId,
          previewToken: previewToken,
          optionId: optionId,
          sessionKey: sessionKey,
          fixed: fixed);

  @override
  Future<TileShareOperation> accept({
    required String assignmentId,
    required String previewToken,
    required String operationId,
    required TileShareAcceptanceMode mode,
    String? sessionKey,
    TileShareLockedTimeLine? lockedTimeLine,
  }) =>
      _api.accept(
          assignmentId: assignmentId,
          previewToken: previewToken,
          operationId: operationId,
          mode: mode,
          sessionKey: sessionKey,
          lockedTimeLine: lockedTimeLine);

  @override
  Future<TileShareOperation> operation(String operationId) =>
      _api.operation(operationId);

  @override
  Future<TileShareAssignmentResponse> response(String assignmentId) =>
      _api.response(assignmentId);

  @override
  String newOperationId() => TileSharePreviewApi.newOperationId();
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

class LiveTileShareRecipientsSource implements TileShareRecipientsSource {
  final TileShareRecipientsApi _recipients;
  final TileShareActivityApi _activity;

  /// How much recent activity is read for delivery state.
  static const int activityPageSize = 100;

  LiveTileShareRecipientsSource(this._recipients, this._activity);

  @override
  Future<TileShareTemplate> addRecipient(String tiletteId, Contact contact) =>
      _recipients.addRecipient(tiletteId, contact);

  @override
  Future<void> removeRecipient(String tiletteId, String assignmentId) =>
      _recipients.removeRecipient(tiletteId, assignmentId);

  @override
  Future<List<TileShareActivity>> clusterActivity(String clusterId) async =>
      (await _activity.getActivity(
              clusterId: clusterId, pageSize: activityPageSize))
          .items;
}

/// Sends only what changed, as the old edit screens did: the server keeps
/// every field left out.
class LiveTileShareEditSource implements TileShareEditSource {
  final TileShareClusterApi _api;

  /// The tilettes' notes endpoint (`TileShareNotesApi`).
  final NotesApi _notes;

  LiveTileShareEditSource(this._api, this._notes);

  @override
  NotesApi get tiletteNotes => _notes;

  @override
  Future<void> saveTaskNotes(String tiletteId, String notes) async {
    final NotesPayload current = await _notes.getNotes(tiletteId);
    final NotesPayload saved = await _notes.updateNotes(
        eventId: tiletteId, userNote: notes, etag: current.etag);
    if (saved.concurrencyConflict) {
      throw StateError('the notes of $tiletteId changed while saving');
    }
  }

  @override
  Future<void> updateShare(String clusterId,
          {String? name, int? endMs, int? startMs}) =>
      _api.updateTileShareCluster(TileShareClusterModel()
        ..Id = clusterId
        ..Name = name
        ..StartTime = startMs
        ..EndTime = endMs);

  @override
  Future<String?> addTask(
          String clusterId, ClusterTemplateTileModel task) async =>
      // The response is the new tile share template (`tileTemplate`).
      (await _api.createDesignatedTileTemplate(task..ClusterId = clusterId)).id;

  @override
  Future<void> updateTask(String tiletteId, {String? name, int? endMs}) =>
      _api.updateTileShareTemplate(ClusterTemplateTileModel()
        ..Id = tiletteId
        ..Name = name
        ..EndTime = endMs);

  @override
  Future<void> deleteTask(String tiletteId) async {
    await _api.deleteTileShareTemplate(tiletteId);
  }
}
