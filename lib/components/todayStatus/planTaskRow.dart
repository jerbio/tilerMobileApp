import 'package:flutter/material.dart';
import 'package:tiler_app/components/todayStatus/metadataLabel.dart';
import 'package:tiler_app/components/todayStatus/reasonChip.dart';
import 'package:tiler_app/components/todayStatus/statusIconWell.dart';
import 'package:tiler_app/components/todayStatus/todayStatusFormatting.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// One tile row inside a Today Status section card (spec §7.2).
///
/// The title always wins the available width: metadata drops to a second line
/// below it rather than squeezing or truncating the title.
class PlanTaskRow extends StatelessWidget {
  const PlanTaskRow({
    super.key,
    required this.item,
    this.onTap,
    this.leading,
    this.showReasonChip = true,
    this.groupCount,
  });

  static const Key titleKey = Key('todayStatus.planTaskRow.title');
  static const Key inlineMetadataKey =
      Key('todayStatus.planTaskRow.metadata.inline');
  static const Key stackedMetadataKey =
      Key('todayStatus.planTaskRow.metadata.stacked');

  /// Below this the trailing metadata no longer fits beside a usable title
  /// width, so it wraps underneath (spec §11).
  static const double _stackMetadataBelowWidth = 360;

  /// §7.2: trailing metadata is intrinsically sized but capped.
  static const double _maxTrailingWidth = 140;

  final PlanItemViewModel item;
  final VoidCallback? onTap;

  /// Replaces the status icon well, so the attention section can inject its
  /// multi-select checkbox without forking this widget.
  final Widget? leading;

  final bool showReasonChip;

  /// When set, this row stands for a collapsed set of sibling sub-events and
  /// reports the count in place of its own date/duration metadata.
  final int? groupCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);

    final String title = item.isProcrastinate
        ? l10n.procrastinateBlockOut
        : (item.title ?? l10n.todayStatusUntitledTile);
    final List<Widget> metadata = _metadata(context);

    return Semantics(
      button: onTap != null,
      label: _semanticsLabel(context, title),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: TodayStatusTokens.rowMinHeight),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: TodayStatusTokens.space2),
            child: LayoutBuilder(builder: (context, constraints) {
              final bool stackMetadata =
                  constraints.maxWidth < _stackMetadataBelowWidth;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading ??
                      StatusIconWell(
                        status: item.status,
                        icon: _iconFor(item.status),
                        size: TodayStatusTokens.iconWellRow,
                        iconSize: TodayStatusTokens.iconRow,
                      ),
                  const SizedBox(width: TodayStatusTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          key: titleKey,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                        if (stackMetadata && metadata.isNotEmpty) ...[
                          const SizedBox(height: TodayStatusTokens.space1),
                          Wrap(
                            key: stackedMetadataKey,
                            spacing: TodayStatusTokens.space2,
                            runSpacing: TodayStatusTokens.space1,
                            children: metadata,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!stackMetadata && metadata.isNotEmpty) ...[
                    const SizedBox(width: TodayStatusTokens.space2),
                    ConstrainedBox(
                      key: inlineMetadataKey,
                      constraints:
                          const BoxConstraints(maxWidth: _maxTrailingWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final Widget entry in metadata)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: TodayStatusTokens.space1),
                              child: entry,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Shows the most informative temporal attribute rather than always the
  /// date, which would otherwise repeat "Today" down the whole screen:
  /// late rows lead with their scheduled time, attention rows with how long
  /// the tile needs, and placed rows only name a date when it isn't today.
  List<Widget> _metadata(BuildContext context) {
    if (groupCount != null) {
      return [
        MetadataLabel(
          icon: Icons.event_repeat,
          label: AppLocalizations.of(context)!
              .todayStatusSessionCount(groupCount!),
        ),
      ];
    }

    final Widget? temporal = _temporalLabel(context);
    return [
      if (temporal != null) temporal,
      if (showReasonChip && item.reasonCode != null)
        ReasonChip(
          reasonCode: item.reasonCode!,
          durationMinutes: item.durationMinutes,
        ),
    ];
  }

  Widget? _temporalLabel(BuildContext context) {
    final DateTime? start = item.scheduledStart;
    final DateTime? date = item.displayDate;

    switch (item.status) {
      case PlanItemStatus.late:
        if (start != null) {
          return MetadataLabel(
              icon: Icons.schedule,
              label: TodayStatusFormatting.timeOfDay(context, start));
        }
        break;
      case PlanItemStatus.needsAttention:
        if (item.durationMinutes != null) {
          return MetadataLabel(
            icon: Icons.hourglass_bottom,
            label:
                TodayStatusFormatting.duration(context, item.durationMinutes!),
          );
        }
        break;
      case PlanItemStatus.placed:
        if (date != null && date.isToday && start != null) {
          return MetadataLabel(
              icon: Icons.schedule,
              label: TodayStatusFormatting.timeOfDay(context, start));
        }
        break;
    }

    if (date == null) return null;
    return MetadataLabel(
        icon: Icons.calendar_month, label: date.humanDate(context));
  }

  /// §10.1: title, status, date, then duration/reason in one concise sequence.
  /// The untruncated title is used so a visually clipped row still reads fully.
  String _semanticsLabel(BuildContext context, String title) {
    final List<String> parts = [
      title,
      TodayStatusFormatting.status(context, item.status),
      if (item.displayDate != null) item.displayDate!.humanDate(context),
      if (item.reasonCode != null)
        TodayStatusFormatting.reason(context, item.reasonCode!,
            durationMinutes: item.durationMinutes)
      else if (item.durationMinutes != null)
        TodayStatusFormatting.duration(context, item.durationMinutes!),
    ];
    return parts.join('. ');
  }

  static IconData _iconFor(PlanItemStatus status) {
    switch (status) {
      case PlanItemStatus.placed:
        return Icons.check_circle;
      case PlanItemStatus.needsAttention:
        return Icons.error_outline;
      case PlanItemStatus.late:
        return Icons.warning_amber;
    }
  }
}
