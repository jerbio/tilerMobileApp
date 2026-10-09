import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clusterCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/editShareScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/ownerEdits.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/listScaffolding.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/util.dart';

/// The one detail frame (redesign T10, §5.4) for every mode and role: a slim
/// bar (back, the share's name, Activity), loading, error + Retry, not found,
/// the header summary, pull-to-refresh that never hides what is shown, and the
/// mode's content below the header. The owner's ⋯ in the bar edits the share
/// (Edit share) or deletes it (Steps 9.16b, 9.16e); a refused change says so
/// with Retry, and a deleted share closes the detail.
///
/// [contentBuilder] draws the mode's content (Broadcast / Class / Project for
/// the owner, the commitment for a recipient - Steps 9.13-9.16); without one
/// the tasks are listed. Reads [TileShareDetailCubit] and loads it.
class TileShareDetailScaffold extends StatefulWidget {
  final Widget Function(BuildContext context, TileShareDetailState state)?
      contentBuilder;

  /// Opens the activity feed; no Activity action without it.
  final VoidCallback? onOpenActivity;

  /// "Now" for the deadline; the clock unless a test says otherwise.
  final DateTime? now;

  const TileShareDetailScaffold({
    super.key,
    this.contentBuilder,
    this.onOpenActivity,
    this.now,
  });

  @override
  State<TileShareDetailScaffold> createState() =>
      _TileShareDetailScaffoldState();
}

class _TileShareDetailScaffoldState extends State<TileShareDetailScaffold> {
  @override
  void initState() {
    super.initState();
    final TileShareDetailCubit cubit = context.read<TileShareDetailCubit>();
    if (cubit.state.phase != DetailPhase.loading) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return BlocConsumer<TileShareDetailCubit, TileShareDetailState>(
      // The share was deleted: there is nothing left to show.
      listenWhen: (before, now) => !before.deleted && now.deleted,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final TileShareDetailCubit cubit = context.read<TileShareDetailCubit>();
        final String name = (state.cluster?.name ?? '').trim();
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            automaticallyImplyLeading: false,
            foregroundColor: scheme.onPrimary,
            leading: IconButton(
              key: const Key('detail_back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(name.isEmpty ? l10n.clusterTitleFallback : name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (cubit.canEdit)
                PopupMenuButton<_ShareAction>(
                  key: const Key('detail_menu'),
                  tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                  icon: const Icon(Icons.more_horiz),
                  enabled: !state.isSaving,
                  onSelected: (action) => switch (action) {
                    _ShareAction.edit => showEditShare(context, cubit),
                    _ShareAction.delete => _deleteShare(context, state, cubit),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<_ShareAction>(
                      key: const Key('detail_menu_edit'),
                      value: _ShareAction.edit,
                      child: Text(l10n.detailEditDetails),
                    ),
                    PopupMenuItem<_ShareAction>(
                      key: const Key('detail_menu_delete'),
                      value: _ShareAction.delete,
                      child: Text(l10n.detailDeleteShare,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              if (widget.onOpenActivity != null)
                IconButton(
                  key: const Key('detail_activity'),
                  tooltip: l10n.tileShareActivityTitle,
                  icon: const Icon(Icons.history),
                  onPressed: widget.onOpenActivity,
                ),
            ],
            bottom: state.isRefreshing || state.isSaving
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2))
                : null,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey<DetailPhase>(state.phase),
              child: _body(context, state, cubit),
            ),
          ),
        );
      },
    );
  }

  /// Deletes the share after asking; once it is gone the detail closes
  /// (the listener above), a refusal shows on the detail with Retry.
  Future<void> _deleteShare(BuildContext context, TileShareDetailState state,
      TileShareDetailCubit cubit) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String name = (state.cluster?.name ?? '').trim();
    final bool ok = await confirmDestructive(context,
        title: l10n.detailDeleteTaskTitle(
            name.isEmpty ? l10n.clusterTitleFallback : name),
        body: l10n.detailDeleteShareBody,
        confirmLabel: l10n.delete,
        confirmKey: const Key('share_delete_confirm'));
    if (ok) await cubit.deleteShare();
  }

  Widget _body(BuildContext context, TileShareDetailState state,
      TileShareDetailCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (state.phase) {
      case DetailPhase.idle:
      case DetailPhase.loading:
        return const TileShareSkeleton(key: Key('detail_loading'));
      case DetailPhase.error:
        return TileShareErrorState(
          key: const Key('detail_error'),
          message: l10n.detailLoadFailed,
          retryLabel: l10n.attentionRetry,
          onRetry: cubit.load,
        );
      case DetailPhase.notFound:
        return Center(
          key: const Key('detail_not_found'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.detailNotFound, textAlign: TextAlign.center),
          ),
        );
      case DetailPhase.ready:
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (state.refreshFailed)
                SliverToBoxAdapter(
                  child: TileShareErrorBanner(
                    key: const Key('detail_refresh_failed'),
                    message: l10n.detailRefreshFailed,
                    retryLabel: l10n.attentionRetry,
                    onRetry: cubit.refresh,
                  ),
                ),
              if (state.editFailed != null)
                SliverToBoxAdapter(
                  child: TileShareErrorBanner(
                    key: const Key('detail_edit_failed'),
                    message: state.editFailed == DetailEdit.deleteShare
                        ? l10n.detailDeleteShareFailed
                        : l10n.detailEditFailed,
                    retryLabel: l10n.attentionRetry,
                    onRetry: cubit.retryEdit,
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: TileShareDetailHeader(
                      state: state, now: widget.now ?? DateTime.now()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: widget.contentBuilder?.call(context, state) ??
                      TileShareDetailTasks(
                          state: state, onRetry: cubit.refresh),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// The header summary (§5.4): the mode, whose it is, what I answered (a
/// recipient), when it is due and - for more than one task - how many. The
/// words are the cluster card's ([ClusterCopy]), so a share reads the same in
/// the list and in its detail.
class TileShareDetailHeader extends StatelessWidget {
  final TileShareDetailState state;
  final DateTime now;

  const TileShareDetailHeader(
      {super.key, required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String locale = Localizations.localeOf(context).toString();
    final TileShareMode mode = state.mode ?? TileShareMode.broadcast;
    final ClusterListItem item = ClusterListItem(
      cluster: state.cluster!,
      createdByMe: state.isOwner,
      mode: mode,
      mine: state.isOwner ? null : state.myStatus,
    );
    final String? due = ClusterCopy.dueText(l10n, item, now, locale);
    final ClusterDueState? dueState = ClusterCopy.dueState(item, now);
    final bool urgent =
        dueState == ClusterDueState.soon || dueState == ClusterDueState.overdue;
    final int tasks = state.tilettes.length;

    return Card(
      key: const Key('detail_header'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TileShareModeBadge(mode: mode),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ClusterCopy.subtitle(l10n, item),
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.mine != null)
                        TileShareStatusPill(
                          label: ClusterCopy.mineLabel(l10n, item.mine!),
                          tone: ClusterCopy.mineTone(item.mine!),
                        ),
                      if (mode != TileShareMode.broadcast && tasks > 0)
                        Text(l10n.attentionMetaTasks(tasks),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      if (due != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 16,
                                color: urgent
                                    ? scheme.error
                                    : scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(due,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: urgent
                                          ? scheme.error
                                          : scheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The share's tasks, until the mode's own content replaces it (9.13-9.16):
/// each tilette's name and length. Tasks that failed to load say so with Retry.
class TileShareDetailTasks extends StatelessWidget {
  final TileShareDetailState state;
  final VoidCallback onRetry;

  const TileShareDetailTasks(
      {super.key, required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.detailTasks, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (state.tilettesFailed)
          Row(
            key: const Key('detail_tasks_failed'),
            children: [
              Expanded(
                child: Text(l10n.detailTasksFailed,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.error)),
              ),
              TextButton(onPressed: onRetry, child: Text(l10n.attentionRetry)),
            ],
          ),
        for (final TileShareTemplate tilette in state.tilettes)
          Padding(
            key: Key('detail_task_${tilette.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.task_alt, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text((tilette.name ?? '').trim().isEmpty
                      ? l10n.clusterTitleFallback
                      : tilette.name!.trim()),
                ),
                if ((tilette.durationInMs ?? 0) > 0)
                  Text(
                      Duration(milliseconds: tilette.durationInMs!)
                          .toHumanLocalized(context),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}

enum _ShareAction { edit, delete }
