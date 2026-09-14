import 'package:flutter/material.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Compact icon + text metadata (date, duration) used inside a task row
/// (spec §7.1).
class MetadataLabel extends StatelessWidget {
  const MetadataLabel({
    super.key,
    required this.icon,
    required this.label,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;

  /// Renders on a tinted pill instead of plain text (spec §5.3 / §5.4).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: TodayStatusTokens.iconSm, color: tokens.textSecondary),
        const SizedBox(width: TodayStatusTokens.space1),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
          ),
        ),
      ],
    );

    if (!emphasis) {
      return content;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TodayStatusTokens.space2,
          vertical: TodayStatusTokens.space1),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(TodayStatusTokens.radiusMd),
      ),
      child: content,
    );
  }
}
