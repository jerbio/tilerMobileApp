import 'package:flutter/material.dart';
import 'package:tiler_app/components/todayStatus/statusIconWell.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// At-a-glance placed / needs-attention metrics (spec §6.3).
///
/// Non-interactive: §6.3 makes tap behavior opt-in, and making halves tappable
/// without a 44px target would break §10.
class StatusSummaryStrip extends StatelessWidget {
  const StatusSummaryStrip({
    super.key,
    required this.placedCount,
    required this.attentionCount,
    this.lateCount = 0,
  });

  static const Key cardKey = Key('todayStatus.summaryStrip');

  final int placedCount;
  final int attentionCount;

  /// Adds a third column only while something is late, so the common case stays
  /// the two-column strip of §6.3.
  final int lateCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);

    return Container(
      key: cardKey,
      constraints: const BoxConstraints(minHeight: 64),
      margin: const EdgeInsets.only(bottom: TodayStatusTokens.space4),
      padding: const EdgeInsets.symmetric(
          horizontal: TodayStatusTokens.space3,
          vertical: TodayStatusTokens.space3),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(TodayStatusTokens.radiusLg),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _metric(
                tokens: tokens,
                status: PlanItemStatus.placed,
                icon: Icons.check_circle,
                count: placedCount,
                label: l10n.todayStatusTilesPlaced(placedCount),
              ),
            ),
            VerticalDivider(
                width: TodayStatusTokens.space4, color: tokens.border),
            Expanded(
              child: _metric(
                tokens: tokens,
                status: PlanItemStatus.needsAttention,
                icon: Icons.error_outline,
                count: attentionCount,
                label: l10n.todayStatusTilesNeedAttention,
              ),
            ),
            if (lateCount > 0) ...[
              VerticalDivider(
                  width: TodayStatusTokens.space4, color: tokens.border),
              Expanded(
                child: _metric(
                  tokens: tokens,
                  status: PlanItemStatus.late,
                  icon: Icons.warning_amber,
                  count: lateCount,
                  label: l10n.todayStatusTilesRunningLate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric({
    required TodayStatusTokens tokens,
    required PlanItemStatus status,
    required IconData icon,
    required int count,
    required String label,
  }) {
    // §6.3: a zero side stays visible but muted rather than disappearing.
    final Color countColor = count == 0
        ? tokens.textSecondary
        : StatusIconWell.foregroundFor(status, tokens);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: TodayStatusTokens.iconSm,
                color: StatusIconWell.foregroundFor(status, tokens)),
            const SizedBox(width: TodayStatusTokens.space1),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: countColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
      ],
    );
  }
}
