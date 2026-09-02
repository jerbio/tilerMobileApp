import 'package:flutter/material.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Localized copy helpers shared by the Today Status row primitives (spec §11.1).
class TodayStatusFormatting {
  const TodayStatusFormatting._();

  /// Reuses the app's existing travel-duration phrasings so durations stay
  /// consistent (and localized) across the product.
  static String duration(BuildContext context, int minutes) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int hours = minutes ~/ 60;
    final int remainder = minutes % 60;
    if (hours == 0) {
      return l10n.travelDurationMinutes(minutes);
    }
    if (remainder == 0) {
      return l10n.travelDurationHours(hours);
    }
    return l10n.travelDurationHoursMinutes(hours, remainder);
  }

  /// Locale-aware clock time, e.g. "2:00 PM" (spec §11.1).
  static String timeOfDay(BuildContext context, DateTime time) {
    return TimeOfDay.fromDateTime(time).format(context);
  }

  /// The user-facing label for an attention reason (spec §8.2).
  ///
  /// `durationExceedsGap` degrades to the generic label when no duration is
  /// known, rather than rendering "Needs null".
  static String reason(
    BuildContext context,
    AttentionReasonCode code, {
    int? durationMinutes,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (code) {
      case AttentionReasonCode.hardDeadlineConflict:
        return l10n.todayStatusReasonDueToday;
      case AttentionReasonCode.noFeasibleSlot:
        return l10n.todayStatusReasonNoOpenSlot;
      case AttentionReasonCode.travelInfeasible:
        return l10n.todayStatusReasonTravelInfeasible;
      case AttentionReasonCode.outsideAllowedHours:
        return l10n.todayStatusReasonOutsideHours;
      case AttentionReasonCode.dependencyBlocked:
        return l10n.todayStatusReasonDependencyBlocked;
      case AttentionReasonCode.durationExceedsGap:
        return durationMinutes == null
            ? l10n.todayStatusReasonUnknown
            : l10n
                .todayStatusReasonNeedsTime(duration(context, durationMinutes));
      case AttentionReasonCode.manualHold:
        return l10n.todayStatusReasonManualHold;
      case AttentionReasonCode.unknown:
        return l10n.todayStatusReasonUnknown;
    }
  }

  /// Announced status word for screen readers (spec §10.1).
  static String status(BuildContext context, PlanItemStatus status) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (status) {
      case PlanItemStatus.placed:
        return l10n.todayStatusPlacedTitle;
      case PlanItemStatus.needsAttention:
        return l10n.todayStatusAttentionTitle;
      case PlanItemStatus.late:
        return l10n.todayStatusLateTitle;
    }
  }
}
