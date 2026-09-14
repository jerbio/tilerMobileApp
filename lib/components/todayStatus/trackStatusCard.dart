import 'package:flutter/material.dart';
import 'package:tiler_app/components/todayStatus/statusIconWell.dart';
import 'package:tiler_app/data/todayStatus/dayPlanViewModel.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Confirms scheduled work is not running late (spec §5.5).
///
/// Takes the already-decided [copy] rather than raw counts so the §8.1 state
/// matrix lives only in [DayPlanViewModel]; whether this card renders at all is
/// the model's `showTrackStatusCard`.
class TrackStatusCard extends StatelessWidget {
  const TrackStatusCard({super.key, required this.copy});

  final TrackStatusCopy copy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      margin: const EdgeInsets.only(bottom: TodayStatusTokens.space4),
      padding: const EdgeInsets.all(TodayStatusTokens.space5),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(TodayStatusTokens.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          const StatusIconWell(
              status: PlanItemStatus.placed, icon: Icons.verified),
          const SizedBox(width: TodayStatusTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy == TrackStatusCopy.everythingOnTrack
                      ? l10n.todayStatusEverythingOnTrack
                      : l10n.todayStatusEverythingElseOnTrack,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: TodayStatusTokens.space1),
                Text(
                  l10n.todayStatusOnTrackSubcopy,
                  style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
