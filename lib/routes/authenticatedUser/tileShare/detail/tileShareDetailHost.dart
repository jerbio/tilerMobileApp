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
        body: const TileShareActivityWidget(),
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
    if (mounted) _cubit.refresh();
  }

  void _openTile(DesignatedTile tile) {
    final String? id = tile.id;
    if (id == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TileDetailRoute.byDesignatedTileId(
            designatedTileTemplateId: id, loadSubEvents: true)));
  }

  void _comments(DesignatedTile tile) =>
      TiletteDetailScreen.byTilette(context: context, designatedTile: tile);

  /// The owner's way to a tilette's comments - the same thread.
  void _tiletteComments(TileShareTemplate tilette) =>
      TiletteDetailScreen.byTemplate(context: context, tilette: tilette);

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
            onComments: _tiletteComments);
      case DetailVariant.project:
        return ProjectDetail(
            detail: state,
            recipients: _recipients,
            onComments: _tiletteComments);
      case DetailVariant.commitment:
        return CommitmentDetail(
          detail: state,
          assignments: _assignments,
          onAnswered: _cubit.refresh,
          onPreview: _preview,
          onOpenTile: _openTile,
          onComments: _comments,
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
