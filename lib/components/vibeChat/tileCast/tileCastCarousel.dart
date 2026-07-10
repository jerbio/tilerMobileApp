import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/dailyView/previewDailyTileList.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastHeaderSheet.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionList.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionHeader.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastCompositeSummary.dart';
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

  /// The active carousel page index. May differ from the bloc's
  /// currentPreviewIndex because the composite summary page is an extra page
  /// not tracked by the bloc.
  int _currentCarouselPage = 0;

  /// Cached from the latest bloc state so callbacks outside build() can access them.
  List<VibePreviewAction> _allActions = [];
  List<VibePreviewAction> _highlightable = [];
  List<VibePreviewAction> _nonHighlightable = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentCarouselPage);
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

  void _navigateTo(int pageIndex) {
    setState(() => _currentCarouselPage = pageIndex);
    // The composite page (last) has no corresponding bloc action — skip dispatch.
    if (pageIndex < _highlightable.length) {
      final action = _highlightable[pageIndex];
      final fullIndex = _allActions.indexOf(action);
      context
          .read<VibeChatBloc>()
          .add(NavigateTileCastEvent(fullIndex >= 0 ? fullIndex : pageIndex));
    }
  }

  void _syncController(int blocIndex) {
    if (!_pageController.hasClients) return;
    final action =
        blocIndex < _allActions.length ? _allActions[blocIndex] : null;
    final int carouselPage = (action != null && _highlightable.isNotEmpty)
        ? _highlightable.indexOf(action).clamp(0, _highlightable.length - 1)
        : _currentCarouselPage;
    final current =
        _pageController.page?.round() ?? _pageController.initialPage;
    if (current != carouselPage) {
      _pageController.animateToPage(
        carouselPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openActionList(
    BuildContext context,
    List<VibePreviewAction> actions,
    int currentCarouselPage,
    Set<String> nonViableEntityIds,
  ) {
    // Map full-list indices → composite group (non-highlightable actions)
    final compositeGroupIndices = <int>{};
    for (var i = 0; i < actions.length; i++) {
      if (!actions[i].isHighlightable) compositeGroupIndices.add(i);
    }

    // Determine which full-list index is currently "selected" for the list.
    final bool isCompositePage =
        _nonHighlightable.isNotEmpty &&
            currentCarouselPage >= _highlightable.length;
    final int selectedFullIndex = isCompositePage
        ? -1
        : (_highlightable.isNotEmpty
            ? actions.indexOf(
                _highlightable[currentCarouselPage.clamp(0, _highlightable.length - 1)])
            : -1);

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
            selectedIndex: selectedFullIndex,
            compositeGroupIndices: compositeGroupIndices,
            isCompositeSelected: isCompositePage,
            nonViableEntityIds: nonViableEntityIds,
            onSelect: (fullIndex) {
              Navigator.of(sheetContext).pop();
              // Route to the composite page for non-highlightable actions,
              // or to the action's carousel page for highlightable ones.
              if (compositeGroupIndices.contains(fullIndex)) {
                _navigateTo(_highlightable.length); // composite page index
              } else {
                final action = actions[fullIndex];
                final carouselPage = _highlightable.indexOf(action);
                _navigateTo(carouselPage >= 0 ? carouselPage : 0);
              }
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

  Widget _buildCompositePage(
      BuildContext context, List<VibePreviewAction> nonHighlightable) {
    return Stack(
      children: [
        PreviewDailyTileList(
          key: const ValueKey('tilecast_composite_schedule'),
          displayDate: Utility.currentTime(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: TileCastCompositeSummary(actions: nonHighlightable),
        ),
      ],
    );
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
          final selectedTile = state.selectedActionEntityId == null
              ? null
              : tiles.firstWhereOrNull((tile) =>
                  tile.id != null &&
                  tile.id!.contains(state.selectedActionEntityId!));
          return _buildPageFallback(
              context, selectedTile?.startTime ?? Utility.currentTime());
        }

        // Separate into pages that highlight a specific tile and those that don't.
        _allActions = actions;
        _highlightable = actions.where((a) => a.isHighlightable).toList();
        _nonHighlightable = actions.where((a) => !a.isHighlightable).toList();
        final bool hasComposite = _nonHighlightable.isNotEmpty;
        final int totalPages =
            _highlightable.length + (hasComposite ? 1 : 0);
        final int compositePageIndex = totalPages - 1;

        // If all actions are non-highlightable the carousel is just the one
        // composite page; _currentCarouselPage stays 0 which is fine.
        final bool onCompositePage =
            hasComposite && _currentCarouselPage >= _highlightable.length;

        // Determine what to show in the header.
        final VibePreviewAction headerAction;
        final String? headerTitleOverride;
        final bool headerNonViable;
        final int headerIndex;

        if (onCompositePage || _highlightable.isEmpty) {
          headerAction = actions.first; // fallback; overridden by title below
          headerTitleOverride =
              '${AppLocalizations.of(context)!.tileCastAlsoIncluded}'
              ' (${_nonHighlightable.length})';
          headerNonViable = false;
          headerIndex = compositePageIndex;
        } else {
          final pageAction =
              _highlightable[_currentCarouselPage.clamp(0, _highlightable.length - 1)];
          final nonViableEntityIds = _nonViableEntityIds(actions, tiles);
          headerAction = pageAction;
          headerTitleOverride = null;
          headerNonViable = pageAction.entityId != null &&
              nonViableEntityIds.contains(pageAction.entityId);
          headerIndex = _currentCarouselPage;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncController(state.currentPreviewIndex);
        });

        return Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: _navigateTo,
                itemBuilder: (context, pageIndex) {
                  if (hasComposite && pageIndex == compositePageIndex) {
                    return _buildCompositePage(context, _nonHighlightable);
                  }
                  return _buildPage(
                      context, _highlightable[pageIndex], tiles);
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TileCastHeaderSheet(
                action: headerAction,
                index: headerIndex,
                total: totalPages,
                isStale: state.isPreviewStale,
                isNonViable: headerNonViable,
                titleOverride: headerTitleOverride,
                onPrev: _currentCarouselPage > 0
                    ? () => _navigateTo(_currentCarouselPage - 1)
                    : null,
                onNext: _currentCarouselPage < totalPages - 1
                    ? () => _navigateTo(_currentCarouselPage + 1)
                    : null,
                onOpenList: () => _openActionList(
                    context, actions, _currentCarouselPage,
                    _nonViableEntityIds(actions, tiles)),
              ),
            ),
          ],
        );
      },
    );
  }
}
