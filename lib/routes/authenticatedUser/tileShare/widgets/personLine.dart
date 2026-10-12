import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personAvatar.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// One person: their avatar (as on Participants), how they are shown, their
/// answer ([below]) or a quiet [note] under it (a staged change), and what
/// is trailing - only actions, so a long address still fits.
class PersonLine extends StatelessWidget {
  final String label;
  final String? note;
  final bool noteIsWarning;
  final bool faded;
  final List<Widget> trailing;

  /// Under the name (the answer, as on Participants).
  final Widget? below;

  const PersonLine({
    required this.label,
    this.below,
    this.note,
    this.noteIsWarning = false,
    this.faded = false,
    this.trailing = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? note = this.note;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      child: Row(
        children: [
          PersonAvatar(label: label),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                        color:
                            faded ? tokens.textSecondary : tokens.textPrimary,
                        decoration: faded ? TextDecoration.lineThrough : null)),
                if (below != null) ...[
                  const SizedBox(height: 4),
                  below!,
                ],
                if (note != null)
                  Text(note,
                      style: textTheme.bodySmall?.copyWith(
                          color: noteIsWarning
                              ? Theme.of(context).colorScheme.error
                              : tokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ...trailing,
        ],
      ),
    );
  }
}
