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

  /// Width of the sentinel placeholder items at each end of the list.
  static const double _placeholderWidth = 56;

  bool _isAutoScrolled = false;

  /// True while the initial auto-scroll animation plays.
  /// Suppresses [_onDayPositionsChanged] so the leading placeholder that is
  /// briefly in view at t=0 does not fire [onLoadBefore] spuriously.
  bool _isProgrammaticScroll = false;

  final ItemScrollController _dayScrollController = ItemScrollController();
  final ItemPositionsListener _dayPositionsListener =
      ItemPositionsListener.create();

  @override
  void didUpdateWidget(TileCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _correctPositionAfterPrepend(oldWidget);
  }

  /// After a prepend, the new day groups are inserted at list indices 1..M
  /// (right after the leading placeholder at index 0). Every old item shifts
  /// right by M list positions, so without correction the user's view snaps
  /// to unintended content.
  ///
  /// We capture the leftmost visible list index **before** the rebuild frame
  /// paints (the positions listener still reflects the old layout at that
  /// point) and immediately [jumpTo] the same day's new list index
  /// (oldAnchor + prependedDayCount) once the frame settles.
  void _correctPositionAfterPrepend(TileCarousel oldWidget) {
    final oldByDay = _groupByDay(oldWidget.subEvents ?? const []);
    final newByDay = _groupByDay(widget.subEvents ?? const []);
    final oldDayIndexes = _sortedDayIndexes(oldByDay);
    final newDayIndexes = _sortedDayIndexes(newByDay);

    if (oldDayIndexes.isEmpty || newDayIndexes.isEmpty) return;
    if (newDayIndexes.first >= oldDayIndexes.first) return; // not a prepend

    final prependedDayCount =
        newDayIndexes.where((i) => i < oldDayIndexes.first).length;
    if (prependedDayCount == 0) return;

    // Snapshot the leftmost visible list index NOW, before the new frame
    // renders. The same day will appear at anchorListIndex + prependedDayCount
    // after the rebuild.
    final positions = _dayPositionsListener.itemPositions.value;
    final anchorListIndex = positions.isEmpty
        ? 1
        : positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);

    final targetListIndex =
        (anchorListIndex + prependedDayCount).clamp(0, newByDay.length + 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dayScrollController.isAttached) return;
      _isProgrammaticScroll = true;
      _dayScrollController.jumpTo(index: targetListIndex);
      // Release after the next frame so the positions listener fires at the
      // settled (corrected) scroll position, not the pre-jump position.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isProgrammaticScroll = false;
      });
    });
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
    if (_isProgrammaticScroll) return;
    final positions = _dayPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    // +2 for the leading and trailing placeholder sentinel items.
    final totalCount = _groupByDay(_subEvents).length + 2;
    for (final pos in positions) {
      if (pos.index == 0) {
        widget.onLoadBefore?.call();
      } else if (pos.index == totalCount - 1) {
        widget.onLoadAfter?.call();
      }
    }
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

  /// Sentinel placeholder rendered as list index 0 (leading) and last index
  /// (trailing). Its visibility in the viewport is the sole trigger for
  /// pagination — [_onDayPositionsChanged] fires the load callback as soon as
  /// it scrolls into view. No external edge-indicator widgets are needed.
  ///
  /// Because the placeholder is always the very first/last list item:
  /// - After **append**: new days insert before the trailing placeholder, so
  ///   the user's scroll position (which was on the placeholder) now lands on
  ///   the first new day automatically — no programmatic scroll needed.
  /// - After **prepend**: the leading placeholder stays at index 0 (pixel 0)
  ///   and new days grow to its right — the view never jumps.
  Widget _buildPlaceholder({required bool leading}) {
    final theme = Theme.of(context);
    final isLoading = leading ? widget.isLoadingBefore : widget.isLoadingAfter;
    final hasMore = leading ? widget.hasMoreBefore : widget.hasMoreAfter;

    Widget child = const SizedBox.shrink();
    if (isLoading) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (hasMore) {
      // Tappable chevron as a manual fallback so the user can force a load
      // without waiting for a scroll gesture to reach the placeholder.
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            leading ? widget.onLoadBefore?.call() : widget.onLoadAfter?.call(),
        child: SizedBox(
          width: _placeholderWidth,
          height: double.infinity,
          child: Icon(
            leading ? Icons.chevron_left : Icons.chevron_right,
            size: 22,
            color: theme.hintColor.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return SizedBox(width: _placeholderWidth, child: Center(child: child));
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
    final dayCount = dayIndexes.length;
    // Total items = leading placeholder + real day groups + trailing placeholder.
    final totalCount = dayCount + 2;

    // Auto-scroll once to the first day at or after today.
    // Real days start at list index 1 (index 0 is the leading placeholder).
    final todayIndex = Utility.getDayIndex(Utility.currentTime());
    int foundDayIndex = dayIndexes.length - 1;
    for (int i = 0; i < dayIndexes.length; i++) {
      if (dayIndexes[i] - todayIndex >= 0) {
        foundDayIndex = i;
        break;
      }
    }
    if (!_isAutoScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isAutoScrolled = true;
        // Suppress edge callbacks during the animation so the leading
        // placeholder (briefly in view at scroll offset 0) does not fire
        // onLoadBefore before the user has even interacted.
        _isProgrammaticScroll = true;
        if (_dayScrollController.isAttached) {
          _dayScrollController.scrollTo(
            index: foundDayIndex + 1, // +1 to skip the leading placeholder
            duration: const Duration(milliseconds: 500),
          );
        }
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _isProgrammaticScroll = false;
        });
      });
    }

    return Container(
      height: 300,
      child: ScrollablePositionedList.builder(
        key: const PageStorageKey<String>('tileCarouselDayList'),
        itemScrollController: _dayScrollController,
        itemPositionsListener: _dayPositionsListener,
        itemCount: totalCount,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == 0) return _buildPlaceholder(leading: true);
          if (index == totalCount - 1) return _buildPlaceholder(leading: false);
          return _buildDay(
              dayIndexes[index - 1], byDay[dayIndexes[index - 1]]!);
        },
      ),
    );
  }
}
