import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
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

  const AttentionCard({
    super.key,
    required this.item,
    this.onOpen,
    this.onDismiss,
  });

  bool get _dismissible => onDismiss != null && item.eventIds.isNotEmpty;

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TileShareStatusPill(
                              label: AttentionCopy.pill(l10n, item.type),
                              tone: AttentionCopy.tone(item.type),
                            ),
                            if (_dismissible)
                              PopupMenuButton<_CardAction>(
                                key: Key('attention_menu_${item.id}'),
                                tooltip: l10n.attentionMenuTooltip,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_horiz, size: 20),
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
                        ),
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
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(cta),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  // Built from the theme: a bare TextStyle here replaces the
                  // button's text style, dropping the app font.
                  textStyle: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
