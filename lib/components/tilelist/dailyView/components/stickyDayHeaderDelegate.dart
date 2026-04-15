import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/daySummaryHeader.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/quickActionChipsRow.dart';
import 'package:tiler_app/data/timelineSummary.dart';

/// Sticky header delegate for the day summary and action chips
class StickyDayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime? date;
  final TimelineSummary? dayData;
  final VoidCallback? onShowRoute;
  final VoidCallback? onReOptimize;
  final bool isLoading;
  final double minHeight;
  final double maxHeight;

  StickyDayHeaderDelegate({
    this.date,
    this.dayData,
    this.onShowRoute,
    this.onReOptimize,
    this.isLoading = false,
    this.minHeight = 160,
    this.maxHeight = 160,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DaySummaryHeader(date: date, dayData: dayData),
          QuickActionChipsRow(
            onShowRoute: onShowRoute,
            onReOptimize: onReOptimize,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? LinearProgressIndicator(
                    key: const ValueKey('schedule-loading-indicator'),
                    minHeight: 3,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.tertiary,
                  )
                : const SizedBox(
                    key: ValueKey('schedule-loading-hidden'),
                    height: 3,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(StickyDayHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        date != oldDelegate.date ||
        dayData != oldDelegate.dayData ||
        isLoading != oldDelegate.isLoading ||
        onShowRoute != oldDelegate.onShowRoute ||
        onReOptimize != oldDelegate.onReOptimize;
  }
}
