import 'package:flutter/material.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Circular tinted container behind a status or category icon (spec §4.1).
///
/// The tint is derived from the semantic [status] so a row never hardcodes a
/// success/attention color, and §10's "never color alone" rule stays enforceable
/// from one place.
class StatusIconWell extends StatelessWidget {
  const StatusIconWell({
    super.key,
    required this.status,
    required this.icon,
    this.size = TodayStatusTokens.iconWell,
    this.iconSize = TodayStatusTokens.iconMd,
  });

  final PlanItemStatus status;
  final IconData icon;
  final double size;
  final double iconSize;

  static Color tintFor(PlanItemStatus status, TodayStatusTokens tokens) {
    switch (status) {
      case PlanItemStatus.placed:
        return tokens.successTint;
      case PlanItemStatus.needsAttention:
        return tokens.attentionTint;
      case PlanItemStatus.late:
        return tokens.dangerTint;
    }
  }

  static Color foregroundFor(PlanItemStatus status, TodayStatusTokens tokens) {
    switch (status) {
      case PlanItemStatus.placed:
        return tokens.success;
      case PlanItemStatus.needsAttention:
        return tokens.attention;
      case PlanItemStatus.late:
        return tokens.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tintFor(status, tokens),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: foregroundFor(status, tokens),
      ),
    );
  }
}
