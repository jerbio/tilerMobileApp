import 'package:flutter/material.dart';
import 'package:tiler_app/components/comments/mention_parsing.dart';
import 'package:tiler_app/data/comments/comment.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Renders a comment's stored text, converting `<@userId>` tokens into
/// highlighted `@Display Name` runs. Unknown or deleted ids render as
/// "Deleted user". The text is never rendered as HTML.
class CommentText extends StatelessWidget {
  final String text;
  final List<CommentPerson> mentions;
  final TextStyle? style;

  const CommentText({
    Key? key,
    required this.text,
    required this.mentions,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lookup = {for (final m in mentions) m.id: m};
    final parts = MentionParser.splitForDisplay(text, lookup);

    if (parts.isEmpty ||
        (parts.length == 1 && parts[0] is String && text.isEmpty)) {
      return Text('');
    }

    final baseStyle = style ?? TileTextStyles.defaultText;
    final colorScheme = Theme.of(context).colorScheme;
    final mentionStyle = baseStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    for (final part in parts) {
      if (part is CommentPerson) {
        final name =
            (part.displayName == null || part.displayName!.isEmpty)
                ? l10n.commentsDeletedAuthor
                : part.displayName!;
        spans.add(
          TextSpan(text: '@$name ', style: mentionStyle),
        );
      } else if (part is String) {
        spans.add(TextSpan(text: part, style: baseStyle));
      }
    }
    return Text.rich(TextSpan(children: spans));
  }
}