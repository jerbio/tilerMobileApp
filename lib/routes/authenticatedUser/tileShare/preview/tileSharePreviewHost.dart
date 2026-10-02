import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_cubit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/tileSharePreviewPage.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileSharePendingAccept.dart';

/// The accept preview wired to the real backend: builds the live sources and
/// the cubit for one assignment, and shows [TileSharePreviewPage] (which pops
/// `true` when an answer was sent).
///
/// An accept whose outcome was never seen is remembered per signed-in account
/// ([accountKey]); without one it is not remembered across app restarts.
class TileSharePreviewHost extends StatefulWidget {
  final String assignmentId;
  final String? accountKey;

  const TileSharePreviewHost({
    super.key,
    required this.assignmentId,
    this.accountKey,
  });

  @override
  State<TileSharePreviewHost> createState() => _TileSharePreviewHostState();
}

class _TileSharePreviewHostState extends State<TileSharePreviewHost> {
  late final TileSharePreviewApi _previewApi;
  late final TileShareClusterApi _clusterApi;
  late final ScheduleApi _scheduleApi;
  late final TileSharePreviewCubit _cubit;

  @override
  void initState() {
    super.initState();
    _previewApi = TileSharePreviewApi(getContextCallBack: () => context);
    _clusterApi = TileShareClusterApi(getContextCallBack: () => context);
    _scheduleApi = ScheduleApi(getContextCallBack: () => context);
    final String? account = widget.accountKey;
    if (account == null) {
      TileShareLog.d('TileSharePreview',
          'signed-in user unknown: an unconfirmed accept is not remembered');
    }
    _cubit = TileSharePreviewCubit(
      source: LiveTileSharePreviewSource(_previewApi),
      assignments: LiveTileShareAssignmentsSource(_clusterApi, _scheduleApi),
      assignmentId: widget.assignmentId,
      pendingStore: account == null
          ? null
          : StoredTileSharePendingAcceptStore(accountKey: account),
    );
  }

  @override
  void dispose() {
    _cubit.close().whenComplete(() {
      _previewApi.dispose();
      _clusterApi.dispose();
      _scheduleApi.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<TileSharePreviewCubit>.value(
        value: _cubit,
        child: const TileSharePreviewPage(),
      );
}
