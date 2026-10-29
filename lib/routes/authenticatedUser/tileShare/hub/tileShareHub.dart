import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clustersView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/undoSnackBar.dart';
import 'package:tiler_app/services/tileShare/tileShareHubPreferences.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// The TileShare hub (redesign T1, T6, T7): a slim bar — back, title, Activity,
/// create — over two segments, **Attention** and **Clusters**.
///
/// * The opening segment follows T7: Attention when it has something for the
///   user, otherwise the segment they were last on. It is decided once
///   Attention has loaded (meanwhile Attention shows its skeleton) and a choice
///   the user makes by hand is never overridden and is remembered.
/// * The Attention segment carries a badge with how many items need attention.
/// * Both segments stay alive, so each keeps its scroll offset; Clusters is only
///   built (and loaded) once visited. A segment change fades, it does not snap.
/// * A Clusters row answers through the Attention cubit — one answering engine,
///   one Undo — and the list reloads once the answer has been sent. If Attention
///   holds no matching invitation the row is opened for review instead.
/// * After a screen opened from here is closed, what it may have changed is
///   reloaded.
///
/// The cubits belong to the caller (which loads nothing for Clusters; the hub
/// does that on first visit) and are provided to both segments.
class TileShareHub extends StatefulWidget {
  final TileShareAttentionCubit attention;
  final TileShareClustersCubit clusters;
  final TileShareHubPreferences preferences;

  final Future<void> Function(AttentionItem item) onOpenAttention;
  final Future<void> Function(ClusterListItem item) onOpenCluster;

  /// The create flow; the hub reloads both lists when it closes.
  final Future<void> Function() onCreate;

  /// Opens the raw activity feed as its own screen.
  final VoidCallback onOpenActivity;

  /// Check fit: the accept preview of one assignment. The hub reloads both
  /// lists when it closes. Without it no card offers a preview.
  final Future<void> Function(String assignmentId)? onPreview;

  const TileShareHub({
    super.key,
    required this.attention,
    required this.clusters,
    this.preferences = const StoredTileShareHubPreferences(),
    required this.onOpenAttention,
    required this.onOpenCluster,
    required this.onCreate,
    required this.onOpenActivity,
    this.onPreview,
  });

  @override
  State<TileShareHub> createState() => _TileShareHubState();
}

class _TileShareHubState extends State<TileShareHub>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  StreamSubscription<TileShareAttentionState>? _attentionSub;

  HubSegment _segment = HubSegment.attention;
  bool _clustersVisited = false;

  /// The user picked a segment; the opening rule no longer applies.
  bool _userChose = false;
  bool _ruleApplied = false;

  bool _prefsRead = false;
  HubSegment? _stored;
  bool _attentionSettled = false;
  bool _attentionHasItems = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200), value: 1);
    _attentionSub = widget.attention.stream.listen(_onAttention);
    _onAttention(widget.attention.state);
    widget.attention.load();
    _readPreferences();
  }

  @override
  void dispose() {
    _attentionSub?.cancel();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _readPreferences() async {
    HubSegment? stored;
    try {
      stored = await widget.preferences.lastSegment();
    } catch (_) {
      stored = null;
    }
    if (!mounted) return;
    _stored = stored;
    _prefsRead = true;
    _applyOpeningRule();
  }

  void _onAttention(TileShareAttentionState state) {
    if (_attentionSettled || state.load != AttentionLoad.ready) return;
    _attentionSettled = true;
    _attentionHasItems = state.items.isNotEmpty;
    _applyOpeningRule();
  }

  /// T7: Attention when it is non-empty, else the last-used segment (Attention
  /// when there is none). Needs both answers; never after a manual choice.
  void _applyOpeningRule() {
    if (_userChose || _ruleApplied || !_prefsRead || !_attentionSettled) return;
    _ruleApplied = true;
    _go(_attentionHasItems
        ? HubSegment.attention
        : (_stored ?? HubSegment.attention));
  }

  void _choose(HubSegment segment) {
    _userChose = true;
    _go(segment);
    widget.preferences.setLastSegment(segment).catchError((Object _) {});
  }

  void _go(HubSegment segment) {
    if (segment == _segment) return;
    setState(() {
      _segment = segment;
      if (segment == HubSegment.clusters && !_clustersVisited) {
        _clustersVisited = true;
        widget.clusters.load();
      }
    });
    _fade.forward(from: 0);
  }

  // ---- opening things ----------------------------------------------------------

  Future<void> _openAttention(AttentionItem item) async {
    await widget.onOpenAttention(item);
    if (mounted) widget.attention.refresh();
  }

  Future<void> _openCluster(ClusterListItem item) async {
    await widget.onOpenCluster(item);
    if (mounted) widget.clusters.refresh();
  }

  Future<void> _preview(String assignmentId) async {
    TileShareLog.d('TileShareHub', 'opening the preview of $assignmentId');
    await widget.onPreview!(assignmentId);
    TileShareLog.d(
        'TileShareHub', 'preview of $assignmentId closed; reloading the lists');
    if (!mounted) return;
    widget.attention.refresh();
    if (_clustersVisited) widget.clusters.refresh();
  }

  Future<void> _create() async {
    await widget.onCreate();
    if (!mounted) return;
    widget.attention.refresh();
    if (_clustersVisited) widget.clusters.refresh();
  }

  /// A Clusters row answered. The answering (and its Undo) belongs to the
  /// Attention cubit, whose invitation for the cluster has the id
  /// `invitation:<clusterId>`; with none, there is nothing to answer here.
  void _answer(ClusterListItem row, InvitationStatus status) {
    final String id = 'invitation:${row.id}';
    final AttentionItem? item = widget.attention.state.items
        .cast<AttentionItem?>()
        .firstWhere((i) => i!.id == id, orElse: () => null);
    if (item == null) {
      _openCluster(row);
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color undoColor = tileShareUndoColor(context);
    if (!widget.attention.respond(id, status)) {
      _openCluster(row);
      return;
    }
    showTileShareUndoSnackBar(
      messenger,
      undoColor,
      message: AttentionCopy.answered(l10n, status, item.count),
      undoLabel: l10n.attentionUndo,
      onUndo: () => widget.attention.undoResponse(id),
      duration: widget.attention.undoWindow,
    );
  }

  // ---- build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider<TileShareAttentionCubit>.value(value: widget.attention),
        BlocProvider<TileShareClustersCubit>.value(value: widget.clusters),
      ],
      child: BlocListener<TileShareAttentionCubit, TileShareAttentionState>(
        listenWhen: (previous, current) =>
            current.answerRevision != previous.answerRevision,
        listener: (context, state) {
          if (_clustersVisited) widget.clusters.refresh();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              key: const Key('hub_back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(l10n.tileShare),
            actions: [
              IconButton(
                key: const Key('hub_activity'),
                tooltip: l10n.tileShareActivityTitle,
                icon: const Icon(Icons.history),
                onPressed: widget.onOpenActivity,
              ),
              IconButton(
                key: const Key('hub_create'),
                tooltip: l10n.clusterEmptyAction,
                icon: const Icon(Icons.add),
                onPressed: _create,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SegmentedButton<HubSegment>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<HubSegment>(
                      value: HubSegment.attention,
                      label: KeyedSubtree(
                        key: const Key('hub_segment_attention'),
                        child: _AttentionLabel(
                            cubit: widget.attention,
                            title: l10n.attentionTabTitle),
                      ),
                    ),
                    ButtonSegment<HubSegment>(
                      value: HubSegment.clusters,
                      label: KeyedSubtree(
                        key: const Key('hub_segment_clusters'),
                        child: Text(l10n.clustersTabTitle),
                      ),
                    ),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (selection) => _choose(selection.first),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  key: const Key('hub_content_fade'),
                  opacity: _fade,
                  child: IndexedStack(
                    index: _segment.index,
                    children: [
                      KeyedSubtree(
                        key: const Key('hub_attention'),
                        child: TileShareAttentionView(
                          onOpen: _openAttention,
                          onPreview: widget.onPreview == null ? null : _preview,
                        ),
                      ),
                      KeyedSubtree(
                        key: const Key('hub_clusters'),
                        child: _clustersVisited
                            ? TileShareClustersView(
                                onOpen: _openCluster,
                                onCreate: _create,
                                onAnswer: _answer,
                                onPreview:
                                    widget.onPreview == null ? null : _preview,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Attention" with a badge of how many items are waiting.
class _AttentionLabel extends StatelessWidget {
  final TileShareAttentionCubit cubit;
  final String title;

  const _AttentionLabel({required this.cubit, required this.title});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BlocBuilder<TileShareAttentionCubit, TileShareAttentionState>(
      bloc: cubit,
      buildWhen: (a, b) => a.items.length != b.items.length,
      builder: (context, state) {
        final int count = state.items.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                key: const Key('hub_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
