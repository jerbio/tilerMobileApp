import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionFilter.dart';

/// The Attention inbox (redesign T7): filter chips over an animated list of
/// [AttentionCard]s. Reads a [TileShareAttentionCubit] from the tree.
///
/// Changes never snap (T11): rows are keyed by item id, a chip switch or a
/// refresh inserts and removes cards with a size + fade transition, and a card
/// growing in above existing ones starts at zero height so nothing jumps.
class TileShareAttentionView extends StatefulWidget {
  /// A card was opened. The host decides where that goes.
  final void Function(AttentionItem item)? onOpen;

  const TileShareAttentionView({super.key, this.onOpen});

  @override
  State<TileShareAttentionView> createState() => _TileShareAttentionViewState();
}

class _TileShareAttentionViewState extends State<TileShareAttentionView> {
  AttentionFilter _filter = AttentionFilter.all;

  TileShareAttentionCubit get _cubit => context.read<TileShareAttentionCubit>();

  Future<void> _dismiss(AttentionItem item) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TileShareAttentionCubit cubit = _cubit;
    final bool done = await cubit.resolve(item.id);
    if (!mounted || !done) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.attentionDismissed),
        action: SnackBarAction(
          label: l10n.attentionUndo,
          onPressed: () => cubit.undo(item.id),
        ),
      ));
  }

  void _onState(BuildContext context, TileShareAttentionState state) {
    final AttentionDismissFailure? failure = state.dismissFailure;
    if (failure == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(failure.wasUndo
            ? l10n.attentionUndoFailed
            : l10n.attentionDismissFailed),
      ));
    _cubit.acknowledgeFailure();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocConsumer<TileShareAttentionCubit, TileShareAttentionState>(
      listenWhen: (previous, current) =>
          current.dismissFailure != null &&
          current.dismissFailure != previous.dismissFailure,
      listener: _onState,
      builder: (context, state) {
        final Map<AttentionFilter, int> counts =
            AttentionFilter.counts(state.items);
        final List<AttentionItem> shown = _filter.apply(state.items);
        final bool allFailed =
            state.failedSources.length == AttentionSource.values.length;
        final bool partlyFailed = state.failedSources.isNotEmpty && !allFailed;

        Widget body;
        if (state.load != AttentionLoad.ready && state.items.isEmpty) {
          body = const _Skeleton();
        } else if (allFailed && state.items.isEmpty) {
          body = _ErrorState(
            message: l10n.attentionLoadFailedAll,
            retryLabel: l10n.attentionRetry,
            onRetry: _cubit.refresh,
          );
        } else {
          body = RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: _AnimatedCards(
                    items: shown,
                    itemBuilder: (item) => AttentionCard(
                      key: ValueKey('attention_card_${item.id}'),
                      item: item,
                      onOpen: () => widget.onOpen?.call(item),
                      onDismiss: () => _dismiss(item),
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverToBoxAdapter(
                    child: state.items.isEmpty
                        ? _EmptyState(
                            key: const Key('attention_empty'),
                            title: l10n.attentionEmptyTitle,
                            body: l10n.attentionEmptyBody,
                          )
                        : Padding(
                            key: const Key('attention_filtered_empty'),
                            padding: const EdgeInsets.all(32),
                            child: Center(
                                child: Text(l10n.attentionEmptyFiltered)),
                          ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Chips(
              selected: _filter,
              counts: counts,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            if (partlyFailed)
              _ErrorBanner(
                key: const Key('attention_error_banner'),
                message: l10n.attentionLoadFailed,
                retryLabel: l10n.attentionRetry,
                onRetry: _cubit.refresh,
              ),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

// ---- pieces ---------------------------------------------------------------

class _Chips extends StatelessWidget {
  final AttentionFilter selected;
  final Map<AttentionFilter, int> counts;
  final ValueChanged<AttentionFilter> onSelected;

  const _Chips({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final AttentionFilter filter in AttentionFilter.values) ...[
            ChoiceChip(
              key: Key('attention_chip_${filter.name}'),
              label: Text(
                '${AttentionCopy.filterLabel(l10n, filter.name)} ${counts[filter] ?? 0}',
                key: Key('attention_chip_label_${filter.name}'),
              ),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorBanner({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyState({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.task_alt_outlined,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final Color fill = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Padding(
      key: const Key('attention_skeleton'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              height: 128,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- the animated list ------------------------------------------------------

/// A sliver list that turns changes to [items] into animations: cards that
/// leave shrink and fade out, cards that arrive grow and fade in. Cards are
/// identified by [AttentionItem.id].
class _AnimatedCards extends StatefulWidget {
  final List<AttentionItem> items;
  final Widget Function(AttentionItem item) itemBuilder;

  const _AnimatedCards({required this.items, required this.itemBuilder});

  @override
  State<_AnimatedCards> createState() => _AnimatedCardsState();
}

class _AnimatedCardsState extends State<_AnimatedCards> {
  static const Duration _inDuration = Duration(milliseconds: 300);
  static const Duration _outDuration = Duration(milliseconds: 220);

  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  late List<AttentionItem> _shown;

  @override
  void initState() {
    super.initState();
    _shown = List<AttentionItem>.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.items);
  }

  void _sync(List<AttentionItem> target) {
    final Set<String> targetIds = target.map((i) => i.id).toSet();
    final SliverAnimatedListState? list = _listKey.currentState;

    // Leaving cards animate out (from the end, so indexes stay valid).
    for (int i = _shown.length - 1; i >= 0; i--) {
      if (targetIds.contains(_shown[i].id)) continue;
      final AttentionItem gone = _shown.removeAt(i);
      list?.removeItem(
        i,
        (context, animation) => _transition(animation, widget.itemBuilder(gone)),
        duration: _outDuration,
      );
    }

    // Arriving cards animate in at their place.
    final Set<String> presentIds = _shown.map((i) => i.id).toSet();
    for (int j = 0; j < target.length; j++) {
      if (presentIds.contains(target[j].id)) continue;
      final int at = j < _shown.length ? j : _shown.length;
      _shown.insert(at, target[j]);
      presentIds.add(target[j].id);
      list?.insertItem(at, duration: _inDuration);
    }

    // Cards that stayed take their fresh data (and order) without animating.
    _shown = List<AttentionItem>.of(target);
  }

  Widget _transition(Animation<double> animation, Widget child) {
    final Animation<double> curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) => _transition(
        animation,
        widget.itemBuilder(_shown[index]),
      ),
    );
  }
}
