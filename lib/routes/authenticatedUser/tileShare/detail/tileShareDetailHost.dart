import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/commitmentDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/tileSharePreviewHost.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareActivityWidget.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareNotesApi.dart';
import 'package:tiler_app/services/tileShare/tileShareSession.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The detail wired to the real backend: builds the live sources and the
/// cubit, uses the signed-in session for ownership and "mine", and shows
/// [TileShareDetailScaffold] immediately without another profile request.
class TileShareDetailHost extends StatefulWidget {
  final TileShareDetailTarget target;

  /// Whether the caller opened it as the owner's; used only when the signed-in
  /// user is not known.
  final bool? ownerHint;

  const TileShareDetailHost({super.key, required this.target, this.ownerHint});

  @override
  State<TileShareDetailHost> createState() => _TileShareDetailHostState();
}

class _TileShareDetailHostState extends State<TileShareDetailHost> {
  static const String _tag = 'TileShareDetail';

  late final TileShareClusterApi _clusterApi;
  late final ScheduleApi _scheduleApi;
  late final DesignatedTileApi _designatedTileApi;
  late final TileShareRecipientsApi _recipientsApi;
  late final TileShareActivityApi _activityApi;
  late final LiveTileShareRecipientsSource _recipients;
  late final LiveTileShareAssignmentsSource _assignments;
  late final TileShareDetailCubit _cubit;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
    _designatedTileApi = DesignatedTileApi(getContextCallBack: () => context);
    _userId = tileShareSessionUserId(context);
    TileShareLog.d(_tag,
        'opened from session (signed-in user ${_userId == null ? 'unknown' : 'known'})');
    _recipientsApi = TileShareRecipientsApi(getContextCallBack: () => context);
    _activityApi = TileShareActivityApi(getContextCallBack: () => context);
    _recipients = LiveTileShareRecipientsSource(_recipientsApi, _activityApi);
    _assignments = LiveTileShareAssignmentsSource(_clusterApi, _scheduleApi,
        designatedTileApi: _designatedTileApi);
    _cubit = TileShareDetailCubit(
      clusters: LiveTileShareClustersSource(_clusterApi),
      assignments: _assignments,
      edits: LiveTileShareEditSource(
          _clusterApi, TileShareNotesApi(getContextCallBack: () => context)),
      target: widget.target,
      currentUserId: () => _userId,
      ownerHint: widget.ownerHint,
    );
  }

  void _openActivity() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(l10n.tileShareActivityTitle)),
        body: TileShareActivityWidget(clusterId: _cubit.state.cluster?.id),
      ),
    ));
  }

  @override
  void dispose() {
    _cubit.close().whenComplete(() {
      _clusterApi.dispose();
      _scheduleApi.dispose();
      _designatedTileApi.dispose();
      _recipientsApi.dispose();
      _activityApi.dispose();
    });
    super.dispose();
  }

  Future<void> _preview(String assignmentId) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TileSharePreviewHost(
            assignmentId: assignmentId, accountKey: _userId)));
    if (mounted) await _cubit.refresh();
  }

  Future<DesignatedTile?> _previewAssignment(DesignatedTile tile) async {
    await _preview(tile.id!);
    if (!mounted) return null;
    for (final updated in _cubit.state.mine) {
      if (updated.id == tile.id) return updated;
    }
    return null;
  }

  void _openTile(DesignatedTile tile) {
    final String? id = tile.id;
    if (id == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TileDetailRoute.byDesignatedTileId(
            designatedTileTemplateId: id, loadSubEvents: true)));
  }

  TileShareTemplate? _fullTemplate(String? id) {
    for (final tilette in _cubit.state.tilettes) {
      if (tilette.id == id) return tilette;
    }
    return null;
  }

  TiletteDetailOptions _tiletteOptions(DesignatedTile tile) {
    final personal = _cubit.state.mine
        .any((t) => (tile.id ?? '').isNotEmpty && t.id == tile.id);
    return TiletteDetailOptions(
      shareName: _cubit.state.cluster?.name,
      mode: _cubit.state.mode,
      template: _fullTemplate(tile.tileTemplate?.id) ?? tile.tileTemplate,
      canRespond: personal,
      assignments: personal ? _assignments : null,
      onAnswered: _cubit.refresh,
      onOpenTile: personal ? () => _openTile(tile) : null,
      onPreview: personal ? () => _previewAssignment(tile) : null,
      notesApi: _cubit.canEdit ? _cubit.tiletteNotes : null,
      notesReadApi: _cubit.tiletteNotes,
      onNotesChanged: _cubit.refresh,
      ownerRecipients: _cubit.canEdit ? _recipients : null,
      ownerTilettes: _cubit.state.tilettes,
      onPeopleChanged: () {
        if (mounted) _cubit.refresh();
      },
    );
  }

  void _openTilette(DesignatedTile tile) => TiletteDetailScreen.byTilette(
      context: context, designatedTile: tile, options: _tiletteOptions(tile));

  void _comments(DesignatedTile tile) => TiletteDetailScreen.byTilette(
      context: context,
      designatedTile: tile,
      options: _tiletteOptions(tile),
      initialTab: TiletteDetailTab.comments);

  /// The owner's way to a tilette's comments - the same thread.
  void _tiletteComments(TileShareTemplate tilette) =>
      _openTemplate(tilette, TiletteDetailTab.comments);

  void _openTemplate(TileShareTemplate tilette,
      [TiletteDetailTab tab = TiletteDetailTab.overview]) {
    final tile = TiletteDetailScreen.tileFor(tilette);
    TiletteDetailScreen.byTilette(
        context: context,
        designatedTile: tile,
        initialTab: tab,
        options: _tiletteOptions(tile));
  }

  void _tiletteNotes(TileShareTemplate tilette) =>
      _openTemplate(tilette, TiletteDetailTab.notes);

  void _notes(DesignatedTile tile) => TiletteDetailScreen.byTilette(
      context: context,
      designatedTile: tile,
      options: _tiletteOptions(tile),
      initialTab: TiletteDetailTab.notes);

  Widget _activity(BuildContext context) => TileShareActivityWidget(
      clusterId: _cubit.state.cluster!.id, embedded: true);

  /// The mode's content under the header.
  Widget _content(BuildContext context, TileShareDetailState state) {
    switch (state.variant) {
      case DetailVariant.broadcast:
        return BroadcastDetail(
            detail: state,
            recipients: _recipients,
            onComments: _tiletteComments);
      case DetailVariant.classMode:
        return ClassDetail(
            detail: state,
            recipients: _recipients,
            activityBuilder: _activity,
            onNotes: _tiletteNotes,
            onOpen: _openTemplate,
            onComments: _tiletteComments);
      case DetailVariant.project:
        return ProjectDetail(
            detail: state,
            recipients: _recipients,
            activityBuilder: _activity,
            onNotes: _tiletteNotes,
            onOpen: _openTemplate,
            onComments: _tiletteComments);
      case DetailVariant.commitment:
        return CommitmentDetail(
          detail: state,
          assignments: _assignments,
          onAnswered: _cubit.refresh,
          onPreview: _preview,
          onOpenTile: _openTile,
          onOpenTilette: _openTilette,
          onComments: _comments,
          onNotes: _notes,
          activityBuilder: _activity,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TileShareDetailCubit>.value(
      value: _cubit,
      child: TileShareDetailScaffold(
        onOpenActivity: _openActivity,
        contentBuilder: _content,
      ),
    );
  }
}
