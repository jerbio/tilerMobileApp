import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';

enum _CardAction { dismiss }

/// One card of the Attention inbox (redesign T7, §5.3): the mode, the cluster,
/// why it needs attention, a status pill, and the action that opens it.
class AttentionCard extends StatelessWidget {
  final AttentionItem item;

  /// The card (or its action) was tapped.
  final VoidCallback? onOpen;

  /// Dismiss the item. The overflow menu only exists for an item that *can* be
  /// dismissed (one made of activity events) and only when this is set.
  final VoidCallback? onDismiss;

  /// Answer the invitation inline (T20): shown only for a Broadcast or Class
  /// invitation — a Class answers all its tasks ("Accept all"), a Project (or a
  /// cluster whose mode is not known yet) is reviewed instead.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Opens the accept preview (T21-T23): shown only for a Broadcast invitation
  /// of one task. A Class or a Project is never previewed from here.
  final VoidCallback? onCheckFit;

  const AttentionCard({
    super.key,
    required this.item,
    this.onOpen,
    this.onDismiss,
    this.onAccept,
    this.onDecline,
    this.onCheckFit,
  });

  bool get _dismissible => onDismiss != null && item.eventIds.isNotEmpty;

  bool get _inlineAnswers =>
      item.type == AttentionType.invitation &&
      onAccept != null &&
      onDecline != null &&
      (item.mode == TileShareMode.broadcast ||
          item.mode == TileShareMode.class_);

  bool get _checkFit =>
      item.type == AttentionType.invitation &&
      onCheckFit != null &&
      item.mode == TileShareMode.broadcast &&
      item.assignmentIds.length == 1;

  /// The "open it" action — always there, whatever else the card offers.
  Widget _review(ThemeData theme, ColorScheme scheme, String label) {
    return TextButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.arrow_forward, size: 18),
      iconAlignment: IconAlignment.end,
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        // Built from the theme: a bare TextStyle here replaces the button's
        // text style, dropping the app font.
        textStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).toString();

    final String title = AttentionCopy.title(item);
    final String reason = AttentionCopy.reason(l10n, item, locale);
    final String? meta = AttentionCopy.meta(l10n, item, locale);
    final String cta = AttentionCopy.cta(l10n, item.type);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TileShareModeBadge(mode: item.mode),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                            builder: (context, constraints) => Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Capped, so large text on a narrow phone shortens
                                    // the pill's label instead of pushing the row over.
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth:
                                              constraints.maxWidth * 0.45),
                                      child: TileShareStatusPill(
                                        label:
                                            AttentionCopy.pill(l10n, item.type),
                                        tone: AttentionCopy.tone(item.type),
                                      ),
                                    ),
                                    if (_dismissible)
                                      PopupMenuButton<_CardAction>(
                                        key: Key('attention_menu_${item.id}'),
                                        tooltip: l10n.attentionMenuTooltip,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_horiz,
                                            size: 20),
                                        onSelected: (_) => onDismiss!(),
                                        itemBuilder: (context) => [
                                          PopupMenuItem<_CardAction>(
                                            value: _CardAction.dismiss,
                                            child: Text(l10n.attentionDismiss),
                                          ),
                                        ],
                                      )
                                    else
                                      const SizedBox(width: 8),
                                  ],
                                )),
                        Text(
                          reason,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_inlineAnswers || _checkFit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_inlineAnswers) ...[
                        FilledButton(
                          key: Key('attention_accept_${item.id}'),
                          onPressed: onAccept,
                          child:
                              Text(AttentionCopy.acceptLabel(l10n, item.mode)),
                        ),
                        OutlinedButton(
                          key: Key('attention_decline_${item.id}'),
                          onPressed: onDecline,
                          child:
                              Text(AttentionCopy.declineLabel(l10n, item.mode)),
                        ),
                      ],
                      if (_checkFit)
                        TextButton.icon(
                          key: Key('attention_check_fit_${item.id}'),
                          onPressed: onCheckFit,
                          icon: const Icon(Icons.calendar_view_day_outlined,
                              size: 18),
                          label: Text(l10n.previewCheckFit),
                        ),
                      _review(theme, scheme, cta),
                    ],
                  ),
                )
              else
                _review(theme, scheme, cta),
            ],
          ),
        ),
      ),
    );
  }
}
