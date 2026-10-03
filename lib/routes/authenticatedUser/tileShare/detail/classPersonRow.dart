import 'package:flutter/material.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/participantRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// One person in a Class (redesign §5.4): one progress segment per task
/// (accepted, invited, declined, or not on it), how many tasks they accepted,
/// and - when they are missing from some tasks - "Not on N tasks" with "Add to
/// all tasks". Tapping the person lists their tasks one by one
/// ([showClassPersonSheet]). Never a single rolled-up total (T13).
class ClassPersonRow extends StatelessWidget {
  final RosterRow row;
  final VoidCallback? onTap;
  final VoidCallback? onRepair;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ClassPersonRow({
    super.key,
    required this.row,
    this.onTap,
    this.onRepair,
    this.onRemove,
    this.onRetry,
    this.onDismiss,
  });

  static Color segmentColor(ColorScheme scheme, RosterCell cell) {
    if (!cell.isPresent) return Colors.transparent;
    switch (cell.rsvp) {
      case InvitationStatus.accepted:
        return TileColors.acceptedTileShare;
      case InvitationStatus.declined:
        return scheme.error;
      default:
        return TileColors.progressMedium;
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
    final String? delivery = ParticipantRow.deliveryText(l10n, row);
    final bool deliveryProblem = row.delivery == RecipientDelivery.failed ||
        row.delivery == RecipientDelivery.unknown;

    return Padding(
      key: Key('participant_row_${row.label}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(row.label.isEmpty ? '?' : row.label[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    key: Key('class_segments_${row.label}'),
                    children: [
                      for (int i = 0; i < row.cells.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            key: const Key('class_segment'),
                            height: 6,
                            decoration: BoxDecoration(
                              color: segmentColor(scheme, row.cells[i]),
                              borderRadius: BorderRadius.circular(3),
                              border: row.cells[i].isPresent
                                  ? null
                                  : Border.all(color: scheme.outline),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (adding)
                    Row(children: [
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(l10n.participantAdding, style: quiet)),
                    ])
                  else ...[
                    Text(l10n.clusterRsvpTasks(row.acceptedCount, row.cells.length),
                        style: quiet),
                    if (addFailed)
                      Text(l10n.classAddFailed,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.error))
                    else if (row.isIncomplete)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(l10n.classMissingTasks(row.missingCount),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: TileColors.progressMedium)),
                          if (onRepair != null)
                            TextButton(
                              onPressed: onRepair,
                              child: Text(l10n.classAddToAll),
                            ),
                        ],
                      ),
                    if (delivery != null)
                      Text(delivery,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: deliveryProblem
                                  ? scheme.error
                                  : scheme.onSurfaceVariant)),
                    if (row.phase == RosterRowPhase.removeFailed)
                      Text(l10n.participantRemoveFailed,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.error)),
                  ],
                ],
              ),
            ),
          ),
          if (addFailed) ...[
            TextButton(onPressed: onRetry, child: Text(l10n.attentionRetry)),
            IconButton(
              tooltip: l10n.dismiss,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
            ),
          ] else if (onRemove != null && !adding && row.assignmentId != null)
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

/// One person's tasks, one by one: each task's name, then their answer and
/// progress on it, or "Not added".
Future<void> showClassPersonSheet(BuildContext context, RosterRow row,
    List<TileShareTemplate> tilettes) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final AppLocalizations l10n = AppLocalizations.of(sheetContext)!;
      final ThemeData theme = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          key: const Key('class_person_sheet'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(row.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (int i = 0; i < row.cells.length && i < tilettes.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text((tilettes[i].name ?? '').trim().isEmpty
                            ? l10n.clusterTitleFallback
                            : tilettes[i].name!.trim()),
                      ),
                      const SizedBox(width: 8),
                      if (!row.cells[i].isPresent)
                        Text(l10n.classTaskNotAdded,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant))
                      else ...[
                        if (row.cells[i].rsvp == InvitationStatus.accepted &&
                            row.cells[i].completion != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                                '${row.cells[i].completion!.round()}%',
                                style: theme.textTheme.bodySmall),
                          ),
                        switch (row.cells[i].rsvp) {
                          InvitationStatus.accepted => TileShareStatusPill(
                              label: l10n.accepted, tone: StatusPillTone.success),
                          InvitationStatus.declined => TileShareStatusPill(
                              label: l10n.declined, tone: StatusPillTone.danger),
                          _ => TileShareStatusPill(
                              label: l10n.participantInvited,
                              tone: StatusPillTone.warning),
                        },
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
