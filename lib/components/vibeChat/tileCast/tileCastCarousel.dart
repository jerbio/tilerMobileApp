import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/dailyView/previewDailyTileList.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastHeaderSheet.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionList.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

/// Navigable TileCast preview carousel.
///
/// Renders one page per [VibePreviewAction] of the active request. Every page
/// shows the same downloaded schedule ([VibeChatState.previewTiles]) but focuses
/// a different tile (the action's `entityId`), so navigation is entirely
/// client-side — swiping or picking from the action list only dispatches a
/// [NavigateTileCastEvent].
class TileCastCarousel extends StatefulWidget {
  const TileCastCarousel({Key? key}) : super(key: key);

  @override
  State<TileCastCarousel> createState() => _TileCastCarouselState();
}

class _TileCastCarouselState extends State<TileCastCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage =
        context.read<VibeChatBloc>().state.currentPreviewIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Finds the target tile for an action by matching the action's entityId
  /// against tile ids (viable-agnostic, so non-viable tiles are still found).
  SubCalendarEvent? _tileForAction(
      VibePreviewAction action, List<SubCalendarEvent> tiles) {
    final entityId = action.entityId;
    if (entityId == null || entityId.isEmpty) return null;
    return tiles.firstWhereOrNull(
      (tile) => tile.id != null && tile.id!.contains(entityId),
    );
  }

  Set<String> _nonViableEntityIds(
      List<VibePreviewAction> actions, List<SubCalendarEvent> tiles) {
    final result = <String>{};
    for (final action in actions) {
      final entityId = action.entityId;
      if (entityId == null) continue;
      final tile = _tileForAction(action, tiles);
      if (tile != null && tile.isViable == false) {
        result.add(entityId);
      }
    }
    return result;
  }

  void _navigateTo(int index) {
    context.read<VibeChatBloc>().add(NavigateTileCastEvent(index));
  }

  void _syncController(int currentPreviewIndex) {
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round() ??
        _pageController.initialPage;
    if (current != currentPreviewIndex) {
      _pageController.animateToPage(
        currentPreviewIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openActionList(
    BuildContext context,
    List<VibePreviewAction> actions,
    int selectedIndex,
    Set<String> nonViableEntityIds,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: TileCastActionList(
            actions: actions,
            selectedIndex: selectedIndex,
            nonViableEntityIds: nonViableEntityIds,
            onSelect: (index) {
              Navigator.of(sheetContext).pop();
              _navigateTo(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, VibeChatState state) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              state.error ?? localization.previewGenerationFailed,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            if (state.previewBatch?.vibeRequestId != null)
              FilledButton.icon(
                onPressed: () => context.read<VibeChatBloc>().add(
                      RetryTileCastEvent(state.previewBatch!.vibeRequestId!),
                    ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(localization.previewRetry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PendingWidget(),
        const SizedBox(height: 12),
        Text(
          localization.previewGenerating,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPage(
      BuildContext context, VibePreviewAction action, List<SubCalendarEvent> tiles) {
    final tile = _tileForAction(action, tiles);
    final displayDate = tile?.startTime ?? Utility.currentTime();
    return _buildPageFallback(context, displayDate,
        key: ValueKey('tilecast_page_${action.entityId}'));
  }

  Widget _buildPageFallback(BuildContext context, DateTime displayDate,
      {Key? key}) {
    return Padding(
      padding: const EdgeInsets.only(top: TileCastHeaderSheet.collapsedHeight),
      child: Stack(
        children: [
          PreviewDailyTileList(
            key: key,
            displayDate: displayDate,
          ),
          if (!displayDate.isToday)
            DayRibbonCarousel(
              displayDate,
              autoUpdateAnchorDate: false,
              preview: true,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        if (state.step == VibeChatStep.loadingPreview) {
          return Container(
            color: colorScheme.surfaceContainerLowest,
            child: _buildLoadingState(context),
          );
        }

        if (state.step == VibeChatStep.error) {
          return Container(
            color: colorScheme.surfaceContainerLowest,
            child: _buildErrorState(context, state),
          );
        }

        final actions = state.previewActions;
        final tiles = state.previewTiles ?? const [];

        if (actions.isEmpty) {
          // No per-action carousel available; fall back to the shared list
          // focused on the currently selected tile's day.
          final selectedTile = state.selectedActionEntityId == null
              ? null
              : tiles.firstWhereOrNull((tile) =>
                  tile.id != null &&
                  tile.id!.contains(state.selectedActionEntityId!));
          return _buildPageFallback(
              context, selectedTile?.startTime ?? Utility.currentTime());
        }

        final index = state.currentPreviewIndex.clamp(0, actions.length - 1);
        final currentAction = actions[index];
        final nonViableEntityIds = _nonViableEntityIds(actions, tiles);
        final bool currentNonViable =
            currentAction.entityId != null &&
                nonViableEntityIds.contains(currentAction.entityId);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncController(index);
        });

        return Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: actions.length,
                onPageChanged: _navigateTo,
                itemBuilder: (context, pageIndex) =>
                    _buildPage(context, actions[pageIndex], tiles),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TileCastHeaderSheet(
                action: currentAction,
                index: index,
                total: actions.length,
                isStale: state.isPreviewStale,
                isNonViable: currentNonViable,
                onPrev: index > 0 ? () => _navigateTo(index - 1) : null,
                onNext: index < actions.length - 1
                    ? () => _navigateTo(index + 1)
                    : null,
                onOpenList: () => _openActionList(
                    context, actions, index, nonViableEntityIds),
              ),
            ),
          ],
        );
      },
    );
  }
}
