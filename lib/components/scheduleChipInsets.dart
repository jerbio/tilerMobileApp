import 'package:flutter/widgets.dart';

/// Where schedule-change chips may sit at the bottom of the Daily content.
///
/// The Daily page runs behind the bottom navigation bar (the scaffold
/// extends its body), so chips pinned to the bottom of the content would be
/// hidden under it. The host that wraps the content measures the bar once
/// and shares it here, so every chip below it (the "Plan updated" chip, and
/// the list and grid edge chips) clears the same bar and the add button.
class ScheduleChipInsets extends InheritedWidget {
  /// Height of whatever covers the bottom of the content (the navigation
  /// bar and the home indicator).
  final double bottomBar;

  const ScheduleChipInsets({
    super.key,
    required this.bottomBar,
    required super.child,
  });

  /// Room kept clear on the right for the floating add button.
  static const double fabClearance = 88;

  /// Gap between the bar and the "Plan updated" chip.
  static const double summaryGap = 16;

  /// Gap between the bar and edge chips, which sit above the summary chip.
  static const double edgeChipGap = 84;

  /// The covered height at the bottom: the shared value when a host
  /// provides one, else the scaffold's own bottom padding (which includes
  /// an extended body's navigation bar).
  static double bottomBarOf(BuildContext context) {
    final insets =
        context.dependOnInheritedWidgetOfExactType<ScheduleChipInsets>();
    return insets?.bottomBar ?? MediaQuery.paddingOf(context).bottom;
  }

  @override
  bool updateShouldNotify(ScheduleChipInsets oldWidget) =>
      bottomBar != oldWidget.bottomBar;
}
