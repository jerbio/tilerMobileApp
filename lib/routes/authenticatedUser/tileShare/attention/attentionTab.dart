import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionFilter.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/api/userApi.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The Attention inbox wired to the real backend: builds the live sources and
/// the cubit, learns who the signed-in user is (so their own actions are left
/// out), loads, and opens a card's cluster when it is tapped.
///
/// Until the unified detail screens exist (Step 9.12) a card opens today's
/// detail screen for its cluster.
class TileShareAttentionTab extends StatefulWidget {
  const TileShareAttentionTab({super.key});

  @override
  State<TileShareAttentionTab> createState() => _TileShareAttentionTabState();
}

class _TileShareAttentionTabState extends State<TileShareAttentionTab> {
  late final TileShareInvitationsApi _invitationsApi;
  late final TileShareActivityApi _activityApi;
  late final TileShareClusterApi _clusterApi;
  late final ScheduleApi _scheduleApi;
  late final UserApi _userApi;
  late final TileShareAttentionCubit _cubit;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _invitationsApi =
        TileShareInvitationsApi(getContextCallBack: () => context);
    _activityApi = TileShareActivityApi(getContextCallBack: () => context);
    _clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
    _userApi = UserApi(getContextCallBack: () => context);
    _cubit = TileShareAttentionCubit(
      attention: LiveTileShareAttentionSources(_invitationsApi, _activityApi),
      assignments: LiveTileShareAssignmentsSource(_clusterApi, _scheduleApi),
      clusters: LiveTileShareClustersSource(_clusterApi),
      currentUserId: () => _userId,
    );
    _start();
  }

  Future<void> _start() async {
    try {
      _userId = (await _userApi.getUserProfile())?.id;
      TileShareLog.d('TileShareAttention',
          'signed-in user ${_userId == null ? 'unknown' : 'known'}');
    } catch (error) {
      // Without the id the user's own actions simply are not filtered out.
      TileShareLog.d('TileShareAttention',
          'signed-in user unknown (profile failed: $error)');
    }
    if (mounted) _cubit.load();
  }

  Future<void> _open(AttentionItem item) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TileShareDetailWidget.byId(
        tileShareId: item.clusterId,
        isOutBox: attentionOpensOutbox(item),
      ),
    ));
    if (mounted) _cubit.refresh();
  }

  @override
  void dispose() {
    // Closing the cubit sends an answer still inside its undo window; the API
    // clients must stay open until that has finished.
    _cubit.close().whenComplete(() {
      _invitationsApi.dispose();
      _activityApi.dispose();
      _clusterApi.dispose();
      _scheduleApi.dispose();
      _userApi.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TileShareAttentionCubit>.value(
      value: _cubit,
      child: TileShareAttentionView(onOpen: _open),
    );
  }
}
