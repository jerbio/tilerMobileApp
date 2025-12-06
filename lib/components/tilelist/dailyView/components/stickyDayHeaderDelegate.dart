import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/daySummaryHeader.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/quickActionChipsRow.dart';

/// Sticky header delegate for the day summary and action chips
class StickyDayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime? date;
  final VoidCallback? onShowRoute;
  final VoidCallback? onReOptimize;
  final double minHeight;
  final double maxHeight;

  StickyDayHeaderDelegate({
    this.date,
    this.onShowRoute,
    this.onReOptimize,
    this.minHeight = 160,
    this.maxHeight = 160,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DaySummaryHeader(date: date),
          QuickActionChipsRow(
            onShowRoute: onShowRoute,
            onReOptimize: onReOptimize,
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
        onShowRoute != oldDelegate.onShowRoute ||
        onReOptimize != oldDelegate.onReOptimize;
  }
}
