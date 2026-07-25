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
  final ItemScrollController _dayScrollController = ItemScrollController();
  final ItemPositionsListener _dayPositionsListener =
      ItemPositionsListener.create();

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
    final showEndChip = !hasMore && !isLoadingThisEdge && _subEvents.isNotEmpty;
    final showScrollHint = hasMore && !isLoadingThisEdge;

    Widget child = const SizedBox.shrink();
    if (showSpinner) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (showEndChip) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          leading ? Icons.first_page : Icons.last_page,
          size: 16,
          color: theme.hintColor,
        ),
      );
    } else if (showScrollHint) {
      // Affordance telling the user there's more content in this direction
      // to scroll to, even before a prefetch is triggered. Tappable so it
      // also acts as a manual "next/previous day" control.
      child = InkResponse(
        onTap: () => _scrollByOneDay(leading: leading),
        radius: 20,
        child: Icon(
          leading ? Icons.chevron_left : Icons.chevron_right,
          size: 22,
          color: theme.hintColor.withValues(alpha: 0.6),
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
