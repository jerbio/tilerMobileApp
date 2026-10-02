import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clusterCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clusterCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedCardList.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/listScaffolding.dart';

/// The Clusters list (redesign T6): filter chips over an animated list of
/// [ClusterCard]s. Reads a [TileShareClustersCubit] from the tree; the host
/// loads it.
///
/// Changes never snap (T11): rows are keyed by cluster id, and a chip switch, a
/// refresh or a delete inserts and removes cards with a size + fade transition.
/// The responses line of a row I created is counted only once the row is built
/// (O2), so scrolling is what asks for more. A delete confirms first and comes
/// back with a message if the server refuses.
class TileShareClustersView extends StatelessWidget {
  /// A card was opened. The host decides where that goes.
  final void Function(ClusterListItem item)? onOpen;

  /// "Share a tile" on an empty list; hidden when `null`.
  final VoidCallback? onCreate;

  /// A pending Broadcast / Class invitation was answered from its card. The
  /// host owns the answering (and its undo); without it the buttons are hidden.
  final void Function(ClusterListItem item, InvitationStatus status)? onAnswer;

  /// Check fit: open the accept preview of this assignment. Without it the
  /// cards offer no preview.
  final void Function(String assignmentId)? onPreview;

  const TileShareClustersView({
    super.key,
    this.onOpen,
    this.onCreate,
    this.onAnswer,
    this.onPreview,
  });

  static Set<ClusterSource> _shownSources(ClusterFilter filter) {
    switch (filter) {
      case ClusterFilter.all:
        return ClusterSource.values.toSet();
      case ClusterFilter.sharedWithMe:
        return {ClusterSource.sharedWithMe};
      case ClusterFilter.createdByMe:
        return {ClusterSource.createdByMe};
    }
  }

  Future<void> _delete(BuildContext context, ClusterListItem item) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TileShareClustersCubit cubit = context.read<TileShareClustersCubit>();
    final String name = ClusterCopy.title(item) ?? l10n.clusterTitleFallback;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.clusterDeleteTitle),
        content: Text(l10n.clusterDeleteBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.clusterDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete(item.id);
  }

  void _onState(BuildContext context, TileShareClustersState state) {
    final ClusterDeleteFailure? failure = state.deleteFailure;
    if (failure == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String name = (failure.name ?? '').trim().isEmpty
        ? l10n.clusterTitleFallback
        : failure.name!.trim();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.clusterDeleteFailed(name))));
    context.read<TileShareClustersCubit>().acknowledgeFailure();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocConsumer<TileShareClustersCubit, TileShareClustersState>(
      listenWhen: (previous, current) =>
          current.deleteFailure != null &&
          current.deleteFailure != previous.deleteFailure,
      listener: _onState,
      builder: (context, state) {
        final TileShareClustersCubit cubit =
            context.read<TileShareClustersCubit>();
        final Set<ClusterSource> shown = _shownSources(state.filter);
        final bool failedHere =
            state.failedSources.any((source) => shown.contains(source));
        final bool allFailed =
            state.failedSources.length == ClusterSource.values.length;
        // With rows on screen a failure is a banner above them; with none it is
        // the whole story - an empty list after a failure is NOT "nothing
        // shared", it just means we could not check.
        final bool bannerFailure = failedHere && state.items.isNotEmpty;

        Widget body;
        if (state.load != ClustersLoad.ready && state.items.isEmpty) {
          body = const TileShareSkeleton(
              key: Key('clusters_skeleton'), cardHeight: 112);
        } else if (failedHere && state.items.isEmpty) {
          body = TileShareErrorState(
            message:
                allFailed ? l10n.clusterLoadFailedAll : l10n.clusterLoadFailed,
            retryLabel: l10n.attentionRetry,
            onRetry: cubit.refresh,
          );
        } else {
          body = RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: TileShareAnimatedCardList<ClusterListItem>(
                    items: state.items,
                    idOf: (item) => item.id,
                    itemBuilder: (item) => _ClusterRow(
                      key: ValueKey('cluster_card_${item.id}'),
                      item: item,
                      onOpen: () => onOpen?.call(item),
                      onDelete: () => _delete(context, item),
                      onAnswer: onAnswer,
                      onPreview: onPreview,
                    ),
                  ),
                ),
                if (state.items.isEmpty)
                  SliverToBoxAdapter(child: _empty(l10n, state.filter)),
                if (state.items.isNotEmpty)
                  SliverToBoxAdapter(child: _footer(context, l10n, state)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TileShareChipBar<ClusterFilter>(
              keyPrefix: 'clusters',
              values: ClusterFilter.values,
              selected: state.filter,
              labelOf: (filter) => ClusterCopy.filterLabel(l10n, filter),
              onSelected: cubit.setFilter,
            ),
            if (bannerFailure)
              TileShareErrorBanner(
                key: const Key('clusters_error_banner'),
                message: l10n.clusterLoadFailed,
                retryLabel: l10n.attentionRetry,
                onRetry: cubit.refresh,
              ),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  Widget _empty(AppLocalizations l10n, ClusterFilter filter) {
    final bool canShare = filter != ClusterFilter.sharedWithMe;
    final String title;
    final String text;
    switch (filter) {
      case ClusterFilter.all:
        title = l10n.clusterEmptyAllTitle;
        text = l10n.clusterEmptyAllBody;
      case ClusterFilter.sharedWithMe:
        title = l10n.clusterEmptySharedTitle;
        text = l10n.clusterEmptySharedBody;
      case ClusterFilter.createdByMe:
        title = l10n.clusterEmptyCreatedTitle;
        text = l10n.clusterEmptyCreatedBody;
    }
    return TileShareEmptyState(
      key: const Key('clusters_empty'),
      icon: Icons.share_outlined,
      title: title,
      body: text,
      actionLabel: canShare && onCreate != null ? l10n.clusterEmptyAction : null,
      onAction: canShare ? onCreate : null,
    );
  }

  /// Under the rows: another page to read, being read, or that failed.
  Widget _footer(
      BuildContext context, AppLocalizations l10n, TileShareClustersState state) {
    final TileShareClustersCubit cubit = context.read<TileShareClustersCubit>();
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.clusterLoadMoreFailed),
            TextButton(
                onPressed: cubit.loadMore, child: Text(l10n.attentionRetry)),
          ],
        ),
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton(
          key: const Key('clusters_load_more'),
          onPressed: cubit.loadMore,
          child: Text(l10n.clusterLoadMore),
        ),
      ),
    );
  }
}

/// A card that asks for its responses line when it is built (and again when a
/// refresh brings it new data), so only the rows on screen are counted.
class _ClusterRow extends StatefulWidget {
  final ClusterListItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final void Function(ClusterListItem item, InvitationStatus status)? onAnswer;
  final void Function(String assignmentId)? onPreview;

  const _ClusterRow({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onDelete,
    required this.onAnswer,
    required this.onPreview,
  });

  @override
  State<_ClusterRow> createState() => _ClusterRowState();
}

class _ClusterRowState extends State<_ClusterRow> {
  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(covariant _ClusterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.item.cluster, widget.item.cluster)) _ask();
  }

  void _ask() {
    if (widget.item.createdByMe) {
      context.read<TileShareClustersCubit>().ensureSummary(widget.item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onAnswer = widget.onAnswer;
    final onPreview = widget.onPreview;
    final List<String> pending =
        item.mine?.pendingAssignmentIds ?? const <String>[];
    return ClusterCard(
      item: item,
      onOpen: widget.onOpen,
      onDelete: item.createdByMe ? widget.onDelete : null,
      onAccept:
          onAnswer == null ? null : () => onAnswer(item, InvitationStatus.accepted),
      onDecline:
          onAnswer == null ? null : () => onAnswer(item, InvitationStatus.declined),
      onRetryRsvp: () =>
          context.read<TileShareClustersCubit>().retrySummary(item.id),
      onCheckFit: onPreview == null || pending.length != 1
          ? null
          : () => onPreview(pending.single),
    );
  }
}
