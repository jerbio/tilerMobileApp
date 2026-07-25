import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileSummary.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Prop-driven horizontal carousel of sub-events grouped by day.
///
/// Data and paging flags are owned by the parent (see `SubEventPaging` in
/// tileDetail). The carousel silently prefetches the next/previous page when
/// the user nears an edge via [onLoadAfter] / [onLoadBefore], shows an inline
/// spinner only if the user reaches the edge before the prefetch resolves, and
/// an "end" chip once a direction is exhausted. Because the data lives with the
/// parent, the carousel survives an edit-and-return round trip (defect #3).
class TileCarousel extends StatefulWidget {
  final List<SubCalendarEvent>? subEvents;
  final bool isInitialLoading;
  final bool hasMoreBefore;
  final bool hasMoreAfter;
  final bool isLoadingBefore;
  final bool isLoadingAfter;
  final Future<void> Function()? onLoadBefore;
  final Future<void> Function()? onLoadAfter;

  const TileCarousel({
    Key? key,
    this.subEvents,
    this.isInitialLoading = false,
    this.hasMoreBefore = false,
    this.hasMoreAfter = false,
    this.isLoadingBefore = false,
    this.isLoadingAfter = false,
    this.onLoadBefore,
    this.onLoadAfter,
  }) : super(key: key);

  @override
  _TileCarouselState createState() => _TileCarouselState();
}

class _TileCarouselState extends State<TileCarousel> {
  static const double _cardWidth = 300;

  /// Fire an edge prefetch when the first/last visible day is within this many
  /// days of the corresponding end of the list.
  static const int _dayLeadThreshold = 1;

  bool _isAutoScrolled = false;

  /// True while a deliberate programmatic scroll is in progress.
  /// [_onDayPositionsChanged] is suppressed during this window to prevent
  /// cascade fetches triggered by intermediate scroll positions.
  bool _isProgrammaticScroll = false;

  final ItemScrollController _dayScrollController = ItemScrollController();
  final ItemPositionsListener _dayPositionsListener =
      ItemPositionsListener.create();

  @override
  void didUpdateWidget(TileCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeScrollToNewItems(oldWidget.subEvents ?? const []);
  }

  /// When a new page is appended or prepended, scroll to show the first newly
  /// loaded day rather than staying at the edge. This prevents the infinite
  /// pagination loop (edge still visible → fetch triggered again) and surfaces
  /// the fresh content to the user.
  void _maybeScrollToNewItems(List<SubCalendarEvent> oldSubs) {
    final newSubs = _subEvents;
    if (newSubs.length <= oldSubs.length) return;
    if (!_dayScrollController.isAttached) return;

    final oldByDay = _groupByDay(oldSubs);
    final newByDay = _groupByDay(newSubs);
    final oldIndexes = _sortedDayIndexes(oldByDay);
    final newIndexes = _sortedDayIndexes(newByDay);
    if (oldIndexes.isEmpty || newIndexes.isEmpty) return;

    int? targetListIndex;

    if (newIndexes.last > oldIndexes.last) {
      // Days appended at trailing edge — jump to the first new day.
      targetListIndex = oldByDay.length;
    } else if (newIndexes.first < oldIndexes.first) {
      // Days prepended at the leading edge.
      // Do NOT jump to the start of the new items — that would land minIndex
      // at 0-1, immediately re-triggering onLoadBefore and causing a loop.
      // Instead, maintain the user's current view by scrolling to the same
      // day they were on before the prepend (its index has shifted by
      // prependedCount). The new older days are silently available by
      // scrolling left.
      final prependedCount =
          newIndexes.where((i) => i < oldIndexes.first).length;
      final positions = _dayPositionsListener.itemPositions.value;
      final currentMinIndex = positions.isEmpty
          ? 0
          : positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
      targetListIndex = prependedCount + currentMinIndex;
    }

    if (targetListIndex != null) {
      final clamped = targetListIndex.clamp(0, newByDay.length - 1);
      final isAppend = newIndexes.last > oldIndexes.last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_dayScrollController.isAttached) return;
        _isProgrammaticScroll = true;
        if (isAppend) {
          // Animate toward new content so the user sees where fresh items are.
          _dayScrollController.scrollTo(
            index: clamped,
            duration: const Duration(milliseconds: 300),
          );
          // Release the suppression flag after the animation completes.
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _isProgrammaticScroll = false;
          });
        } else {
          // Maintain-position after prepend: jump instantly so there is no
          // animation window during which the listener could fire at an
          // intermediate position and trigger a cascade fetch.
          _dayScrollController.jumpTo(index: clamped);
          _isProgrammaticScroll = false;
        }
      });
    } else {
      // New items all fell on existing day groups — no scroll needed, but we
      // must re-check the edge so the next batch can be triggered if the
      // positions listener didn't fire (no position change occurred).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onDayPositionsChanged();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _dayPositionsListener.itemPositions.addListener(_onDayPositionsChanged);
  }

  @override
  void dispose() {
    _dayPositionsListener.itemPositions.removeListener(_onDayPositionsChanged);
    super.dispose();
  }

  List<SubCalendarEvent> get _subEvents => widget.subEvents ?? const [];

  Map<int, List<SubCalendarEvent>> _groupByDay(List<SubCalendarEvent> subs) {
    final Map<int, List<SubCalendarEvent>> byDay = {};
    for (final sub in subs) {
      final dayIndex = Utility.getDayIndex(sub.startTime);
      byDay.putIfAbsent(dayIndex, () => []).add(sub);
    }
    return byDay;
  }

  List<int> _sortedDayIndexes(Map<int, List<SubCalendarEvent>> byDay) {
    final keys = byDay.keys.toList();
    keys.sort();
    return keys;
  }

  void _onDayPositionsChanged() {
    // Suppress edge-based load callbacks while a deliberate programmatic
    // scroll is in flight to avoid cascade fetches.
    if (_isProgrammaticScroll) return;
    final positions = _dayPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final dayCount = _groupByDay(_subEvents).length;
    if (dayCount == 0) return;

    int minIndex = positions.first.index;
    int maxIndex = positions.first.index;
    for (final pos in positions) {
      if (pos.index < minIndex) minIndex = pos.index;
      if (pos.index > maxIndex) maxIndex = pos.index;
    }

    if (maxIndex >= dayCount - 1 - _dayLeadThreshold) {
      widget.onLoadAfter?.call();
    }
    if (minIndex <= _dayLeadThreshold) {
      widget.onLoadBefore?.call();
    }
  }

  /// Scrolls one day step toward the leading/trailing edge. Bound to the
  /// tappable chevron scroll-hint so it doubles as a manual "next/previous
  /// day" control, not just a passive affordance.
  void _scrollByOneDay({required bool leading}) {
    if (!_dayScrollController.isAttached) return;
    final dayCount = _groupByDay(_subEvents).length;
    if (dayCount == 0) return;

    final positions = _dayPositionsListener.itemPositions.value;
    int currentIndex = leading ? dayCount - 1 : 0;
    if (positions.isNotEmpty) {
      currentIndex = leading
          ? positions.map((pos) => pos.index).reduce((a, b) => a < b ? a : b)
          : positions.map((pos) => pos.index).reduce((a, b) => a > b ? a : b);
    }
    final targetIndex =
        (leading ? currentIndex - 1 : currentIndex + 1).clamp(0, dayCount - 1);

    if (targetIndex == currentIndex) {
      // Already at the absolute edge of loaded items — no day to scroll to.
      // Trigger a fetch directly so the user isn't stuck waiting for the
      // positions listener to fire (it won't fire without a position change).
      if (leading) {
        widget.onLoadBefore?.call();
      } else {
        widget.onLoadAfter?.call();
      }
      return;
    }

    _dayScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildDay(int dayIndex, List<SubCalendarEvent> daySubs) {
    return Container(
      height: 250,
      width: _cardWidth * daySubs.length,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 0, 0),
            child: Text(
              Utility.getTimeFromIndex(dayIndex).humanDate(context),
              style: const TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 25,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: daySubs
                  .map((e) => Container(
                      height: 200, width: _cardWidth, child: TileSummary(e)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgeIndicator({required bool leading}) {
    final theme = Theme.of(context);
    final hasMore = leading ? widget.hasMoreBefore : widget.hasMoreAfter;
    final isLoadingThisEdge =
        leading ? widget.isLoadingBefore : widget.isLoadingAfter;
    final showSpinner = isLoadingThisEdge;
    final showScrollHint = hasMore && !isLoadingThisEdge;

    Widget child = const SizedBox.shrink();
    if (showSpinner) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (showScrollHint) {
      // Affordance telling the user there's more content in this direction.
      // Tappable: scrolls one day toward the edge, or triggers a fetch if
      // already at the absolute edge of loaded items.
      //
      // Uses GestureDetector + HitTestBehavior.opaque so the full 44 px
      // container is tappable, not just the 22 px icon bounding box.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _scrollByOneDay(leading: leading),
        child: Container(
          width: 44,
          alignment: Alignment.center,
          child: Icon(
            leading ? Icons.chevron_left : Icons.chevron_right,
            size: 22,
            color: theme.hintColor.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return Container(width: 44, alignment: Alignment.center, child: child);
  }

  Widget _buildSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 300,
      child: Shimmer.fromColors(
        baseColor: colorScheme.primary.withAlpha(50),
        highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, i) => Center(
            child: Container(
              height: 200,
              width: _cardWidth,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_subEvents.isEmpty) {
      if (widget.isInitialLoading) return _buildSkeleton();
      return const SizedBox();
    }

    final byDay = _groupByDay(_subEvents);
    final dayIndexes = _sortedDayIndexes(byDay);

    // Auto-scroll once to the first day at or after today.
    final todayIndex = Utility.getDayIndex(Utility.currentTime());
    int foundIndex = dayIndexes.length - 1;
    for (int i = 0; i < dayIndexes.length; i++) {
      if (dayIndexes[i] - todayIndex >= 0) {
        foundIndex = i;
        break;
      }
    }
    if (!_isAutoScrolled && foundIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isAutoScrolled = true;
        if (_dayScrollController.isAttached) {
          _dayScrollController.scrollTo(
            index: foundIndex,
            duration: const Duration(milliseconds: 500),
          );
        }
      });
    }

    return Container(
      height: 300,
      child: Row(
        children: [
          _buildEdgeIndicator(leading: true),
          Expanded(
            child: ScrollablePositionedList.builder(
              // Explicit key avoids a PageStorage identity collision: without
              // it, this list's auto-restore slot is derived from its
              // position among the parent ListView's conditionally-inserted
              // children, which can land on a slot previously holding a
              // plain scroll-offset double from a different widget and crash
              // ScrollablePositionedList's `ItemPosition?` cast on restore.
              key: const PageStorageKey<String>('tileCarouselDayList'),
              itemScrollController: _dayScrollController,
              itemPositionsListener: _dayPositionsListener,
              itemCount: dayIndexes.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) =>
                  _buildDay(dayIndexes[index], byDay[dayIndexes[index]]!),
            ),
          ),
          _buildEdgeIndicator(leading: false),
        ],
      ),
    );
  }
}
