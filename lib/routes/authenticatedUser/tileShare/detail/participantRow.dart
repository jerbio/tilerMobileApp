import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personAvatar.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// One person on a roster (redesign §5.4): who, their answer, their progress
/// once they accepted, and how their invitation was delivered. A row being
/// added shows progress; a refused add offers Retry and Dismiss; a refused
/// removal says so. Remove is offered only when [onRemove] is given (the
/// Overview previews without it).
class ParticipantRow extends StatelessWidget {
  final RosterRow row;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ParticipantRow({
    super.key,
    required this.row,
    this.onRemove,
    this.onRetry,
    this.onDismiss,
  });

  static String _channel(AppLocalizations l10n, String? channel) {
    switch (channel) {
      case 'email':
        return l10n.channelEmail;
      case 'sms':
        return l10n.channelSms;
      case 'push':
        return l10n.channelPush;
    }
    return '';
  }

  /// "Sent by email", "Couldn't send by SMS", "Delivery unknown"; `null` when
  /// nothing is known.
  static String? deliveryText(AppLocalizations l10n, RosterRow row) {
    final String channel = _channel(l10n, row.deliveryChannel);
    switch (row.delivery) {
      case RecipientDelivery.sent:
        return channel.isEmpty ? l10n.deliverySentPlain : l10n.deliverySent(channel);
      case RecipientDelivery.failed:
        return channel.isEmpty
            ? l10n.deliveryFailedPlain
            : l10n.deliveryFailed(channel);
      case RecipientDelivery.unknown:
        return l10n.deliveryUnknown;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? quiet =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final bool adding = row.phase == RosterRowPhase.adding;
    final bool addFailed = row.phase == RosterRowPhase.addFailed;
    final String? delivery = deliveryText(l10n, row);
    final bool deliveryProblem = row.delivery == RecipientDelivery.failed ||
        row.delivery == RecipientDelivery.unknown;

    final (String label, StatusPillTone tone) = switch (row.rsvp) {
      InvitationStatus.accepted => (l10n.accepted, StatusPillTone.success),
      InvitationStatus.declined => (l10n.declined, StatusPillTone.danger),
      _ => (l10n.participantInvited, StatusPillTone.warning),
    };

    return Padding(
      key: Key('participant_row_${row.label}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(label: row.label),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (adding)
                  Row(
                    children: [
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(l10n.participantAdding, style: quiet)),
                    ],
                  )
                else if (addFailed)
                  Text(l10n.participantAddFailed,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.error))
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TileShareStatusPill(label: label, tone: tone),
                      if (row.rsvp == InvitationStatus.accepted &&
                          row.completion != null)
                        Text('${row.completion!.round()}%', style: quiet),
                    ],
                  ),
                  if (row.rsvp == InvitationStatus.accepted &&
                      row.completion != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (row.completion! / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        color: TileColors.acceptedTileShare,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                  if (delivery != null) ...[
                    const SizedBox(height: 4),
                    Text(delivery,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: deliveryProblem
                                ? scheme.error
                                : scheme.onSurfaceVariant)),
                  ],
                  if (row.phase == RosterRowPhase.removeFailed) ...[
                    const SizedBox(height: 4),
                    Text(l10n.participantRemoveFailed,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error)),
                  ],
                ],
              ],
            ),
          ),
          if (addFailed) ...[
            TextButton(onPressed: onRetry, child: Text(l10n.attentionRetry)),
            IconButton(
              tooltip: l10n.dismiss,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
            ),
          ] else if (onRemove != null && !adding)
            IconButton(
              tooltip: l10n.participantRemove,
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
