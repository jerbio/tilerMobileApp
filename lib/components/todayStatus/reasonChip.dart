import 'package:flutter/material.dart';
import 'package:tiler_app/components/todayStatus/todayStatusFormatting.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// A single attention reason (spec §6.5).
///
/// Only one chip is ever shown per row; the caller picks the highest-priority
/// reason and exposes the rest in tile detail.
class ReasonChip extends StatelessWidget {
  const ReasonChip({
    super.key,
    required this.reasonCode,
    this.durationMinutes,
  });

  final AttentionReasonCode reasonCode;
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
          horizontal: TodayStatusTokens.space2,
          vertical: TodayStatusTokens.space1),
      decoration: BoxDecoration(
        color: tokens.attentionTint,
        borderRadius: BorderRadius.circular(TodayStatusTokens.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        TodayStatusFormatting.reason(context, reasonCode,
            durationMinutes: durationMinutes),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: tokens.attention,
        ),
      ),
    );
  }
}
