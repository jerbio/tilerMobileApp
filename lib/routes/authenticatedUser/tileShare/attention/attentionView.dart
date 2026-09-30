import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionFilter.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedCardList.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/listScaffolding.dart';

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

  /// The colour of an "Undo" action on a snack bar. The framework default is a
  /// muted colour that makes a working button look disabled, so use the brand
  /// colour where it is legible on the bar (the dark theme's light bar) and
  /// the theme's own readable "on inverse" colour where it is not (the light
  /// theme's translucent-black bar). Legible means a contrast of at least 3:1
  /// — the bar's colour is blended over the page it sits on.
  Color _undoColor(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bar = Color.alphaBlend(
        theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
        theme.scaffoldBackgroundColor);
    final Color brand = theme.colorScheme.primary;
    return _contrast(brand, bar) >= 3.0
        ? brand
        : theme.colorScheme.onInverseSurface;
  }

  static double _contrast(Color a, Color b) {
    final double la = a.computeLuminance(), lb = b.computeLuminance();
    final double hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  Future<void> _dismiss(AttentionItem item) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TileShareAttentionCubit cubit = _cubit;
    final Color undoColor = _undoColor(context);
    final bool done = await cubit.resolve(item.id);
    if (!mounted || !done) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        persist: false,
        content: Text(l10n.attentionDismissed),
        action: SnackBarAction(
          textColor: undoColor,
          label: l10n.attentionUndo,
          onPressed: () => cubit.undo(item.id),
        ),
      ));
  }

  /// Accepts or declines inline, with an Undo that lasts as long as the
  /// cubit's undo window (after which the answer is sent).
  void _answer(AttentionItem item, InvitationStatus status) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TileShareAttentionCubit cubit = _cubit;
    final Color undoColor = _undoColor(context);
    if (!cubit.respond(item.id, status)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        persist: false,
        duration: cubit.undoWindow,
        content: Text(AttentionCopy.answered(l10n, status, item.count)),
        action: SnackBarAction(
          textColor: undoColor,
          label: l10n.attentionUndo,
          onPressed: () => cubit.undoResponse(item.id),
        ),
      ));
  }

  void _onState(BuildContext context, TileShareAttentionState state) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AttentionDismissFailure? dismissFailure = state.dismissFailure;
    final AttentionRespondFailure? respondFailure = state.respondFailure;
    if (dismissFailure == null && respondFailure == null) return;
    final String message = respondFailure != null
        ? AttentionCopy.answerFailure(l10n, respondFailure)
        : (dismissFailure!.wasUndo
            ? l10n.attentionUndoFailed
            : l10n.attentionDismissFailed);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _cubit.acknowledgeFailure();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocConsumer<TileShareAttentionCubit, TileShareAttentionState>(
      listenWhen: (previous, current) =>
          (current.dismissFailure != null &&
              current.dismissFailure != previous.dismissFailure) ||
          (current.respondFailure != null &&
              current.respondFailure != previous.respondFailure),
      listener: _onState,
      builder: (context, state) {
        final Map<AttentionFilter, int> counts =
            AttentionFilter.counts(state.items);
        final List<AttentionItem> shown = _filter.apply(state.items);
        final bool allFailed =
            state.failedSources.length == AttentionSource.values.length;
        final bool anyFailed = state.failedSources.isNotEmpty;
        // With items on screen a failure is a banner above them; with none, it
        // is the whole story - an empty list after a failure is NOT "all
        // caught up", it just means we could not check everything.
        final bool bannerFailure = anyFailed && state.items.isNotEmpty;

        Widget body;
        if (state.load != AttentionLoad.ready && state.items.isEmpty) {
          body = const TileShareSkeleton(key: Key('attention_skeleton'));
        } else if (anyFailed && state.items.isEmpty) {
          body = TileShareErrorState(
            message: allFailed
                ? l10n.attentionLoadFailedAll
                : l10n.attentionLoadFailed,
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
                  sliver: TileShareAnimatedCardList<AttentionItem>(
                    items: shown,
                    idOf: (item) => item.id,
                    itemBuilder: (item) => AttentionCard(
                      key: ValueKey('attention_card_${item.id}'),
                      item: item,
                      onOpen: () => widget.onOpen?.call(item),
                      onDismiss: () => _dismiss(item),
                      onAccept: () => _answer(item, InvitationStatus.accepted),
                      onDecline: () => _answer(item, InvitationStatus.declined),
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverToBoxAdapter(
                    child: state.items.isEmpty
                        ? TileShareEmptyState(
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
            TileShareChipBar<AttentionFilter>(
              keyPrefix: 'attention',
              values: AttentionFilter.values,
              selected: _filter,
              labelOf: (filter) =>
                  AttentionCopy.filterLabel(l10n, filter.name),
              countOf: (filter) => counts[filter],
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            if (bannerFailure)
              TileShareErrorBanner(
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
