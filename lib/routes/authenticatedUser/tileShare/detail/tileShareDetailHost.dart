import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareActivityWidget.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/userApi.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The detail wired to the real backend: builds the live sources and the
/// cubit, learns who the signed-in user is (ownership and "mine" depend on it)
/// before anything loads, and shows [TileShareDetailScaffold].
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
  late final UserApi _userApi;
  late final TileShareDetailCubit _cubit;
  String? _userId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
    _designatedTileApi = DesignatedTileApi(getContextCallBack: () => context);
    _userApi = UserApi(getContextCallBack: () => context);
    _cubit = TileShareDetailCubit(
      clusters: LiveTileShareClustersSource(_clusterApi),
      assignments: LiveTileShareAssignmentsSource(_clusterApi, _scheduleApi,
          designatedTileApi: _designatedTileApi),
      target: widget.target,
      currentUserId: () => _userId,
      ownerHint: widget.ownerHint,
    );
    _start();
  }

  Future<void> _start() async {
    try {
      _userId = (await _userApi.getUserProfile())?.id;
    } catch (error) {
      // Without the id, the caller's hint decides ownership and nothing is
      // counted as mine.
      TileShareLog.d(_tag, 'signed-in user unknown (profile failed: $error)');
    }
    TileShareLog.d(
        _tag,
        'opened ${widget.target.clusterId ?? widget.target.designatedTileId} '
        '(signed-in user ${_userId == null ? 'unknown' : 'known'})');
    if (mounted) setState(() => _ready = true);
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
      _userApi.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 48, automaticallyImplyLeading: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider<TileShareDetailCubit>.value(
      value: _cubit,
      child: TileShareDetailScaffold(onOpenActivity: _openActivity),
    );
  }
}
