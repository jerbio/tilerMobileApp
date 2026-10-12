import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionFilter.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createBroadcast.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createClass.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createModeChooser.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/hub/tileShareHub.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/tileSharePreviewHost.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareActivityWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/tileShare/tileShareSession.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The hub wired to the real backend: builds the live sources and both cubits,
/// reads the signed-in session (so their own actions are left out of
/// Attention) without another profile request, and wires navigation.
///
/// Until the unified detail screens exist (Step 9.12) a card opens today's
/// detail screen for its cluster.
class TileShareHubHost extends StatefulWidget {
  const TileShareHubHost({super.key});

  @override
  State<TileShareHubHost> createState() => _TileShareHubHostState();
}

class _TileShareHubHostState extends State<TileShareHubHost> {
  late final TileShareInvitationsApi _invitationsApi;
  late final TileShareActivityApi _activityApi;
  late final TileShareClusterApi _clusterApi;
  late final ScheduleApi _scheduleApi;
  late final TileShareAttentionCubit _attention;
  late final TileShareClustersCubit _clusters;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _invitationsApi =
        TileShareInvitationsApi(getContextCallBack: () => context);
    _activityApi = TileShareActivityApi(getContextCallBack: () => context);
    _clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
    _userId = tileShareSessionUserId(context);
    TileShareLog.d('TileShareHub',
        'signed-in user ${_userId == null ? 'unknown' : 'known'} (session)');
    final assignments =
        LiveTileShareAssignmentsSource(_clusterApi, _scheduleApi);
    final clusters = LiveTileShareClustersSource(_clusterApi);
    _attention = TileShareAttentionCubit(
      attention: LiveTileShareAttentionSources(_invitationsApi, _activityApi),
      assignments: assignments,
      clusters: clusters,
      currentUserId: () => _userId,
    );
    _clusters = TileShareClustersCubit(
        clusters: clusters,
        assignments: assignments,
        currentUserId: () => _userId);
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _openAttention(AttentionItem item) =>
      _push(TileShareDetailWidget.byId(
          tileShareId: item.clusterId, isOutBox: attentionOpensOutbox(item)));

  Future<void> _openCluster(ClusterListItem item) =>
      _push(TileShareDetailWidget.byId(
          tileShareId: item.id, isOutBox: item.createdByMe));

  /// Create starts with the mode (T14); once sent, the new share's detail
  /// takes the create screen's place.
  Future<void> _create() async {
    final TileShareMode? mode = await showCreateModeChooser(context);
    if (!mounted || mode == null || mode == TileShareMode.project) return;
    final source = LiveTileShareCreateSource(_clusterApi);
    void onCreated(BuildContext context, String clusterId) =>
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
            builder: (_) => TileShareDetailWidget.byId(
                tileShareId: clusterId, isOutBox: true)));
    await _push(mode == TileShareMode.class_
        ? CreateClassScreen(source: source, onCreated: onCreated)
        : CreateBroadcastScreen(source: source, onCreated: onCreated));
  }

  Future<void> _preview(String assignmentId) => _push(
      TileSharePreviewHost(assignmentId: assignmentId, accountKey: _userId));

  void _openActivity() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    _push(Scaffold(
      appBar: AppBar(title: Text(l10n.tileShareActivityTitle)),
      body: const TileShareActivityWidget(),
    ));
  }

  @override
  void dispose() {
    // Closing the attention cubit sends an answer still inside its undo
    // window; the API clients must stay open until that has finished.
    _attention.close().whenComplete(() {
      _invitationsApi.dispose();
      _activityApi.dispose();
      _clusterApi.dispose();
      _scheduleApi.dispose();
    });
    _clusters.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TileShareHub(
      attention: _attention,
      clusters: _clusters,
      onOpenAttention: _openAttention,
      onOpenCluster: _openCluster,
      onCreate: _create,
      onOpenActivity: _openActivity,
      onPreview: _preview,
    );
  }
}
