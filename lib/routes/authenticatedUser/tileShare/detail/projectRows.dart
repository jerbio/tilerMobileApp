import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personAvatar.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/participantRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

/// A task's name, or the fallback for a task without one.
String projectTaskName(AppLocalizations l10n, TileShareTemplate t) =>
    (t.name ?? '').trim().isEmpty ? l10n.clusterTitleFallback : t.name!.trim();

/// One task on a Project's board (redesign §5.4): its name and length, who has
/// it with their answer and **that task's own progress** (T13 - no rolled-up
/// total), "No one assigned" when nobody does (O10), and Assign / Reassign. A
/// change going out shows progress; a refused one says so with Retry. No
/// Accept all: a Project is answered task by task (T20).
class ProjectTaskRow extends StatelessWidget {
  final TileShareTemplate tilette;

  /// Whoever has the task (their cell for it), in roster order.
  final List<(RosterRow, RosterCell)> assignees;
  final TaskChange? change;
  final VoidCallback? onAssign;
  final VoidCallback? onRetry;

  /// The owner's Edit / Delete for the task; none without it.
  final Widget? menu;

  const ProjectTaskRow({
    super.key,
    required this.tilette,
    required this.assignees,
    this.change,
    this.onAssign,
    this.onRetry,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? quiet =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final bool working = change?.phase == TaskChangePhase.working;
    final bool failed = change?.phase == TaskChangePhase.failed;
    return Padding(
      key: Key('project_task_${tilette.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(projectTaskName(l10n, tilette),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if ((tilette.durationInMs ?? 0) > 0)
                Text(
                    Duration(milliseconds: tilette.durationInMs!)
                        .toHumanLocalized(context),
                    style: quiet),
              if (menu != null) menu!,
            ],
          ),
          const SizedBox(height: 6),
          if (assignees.isEmpty)
            Text(l10n.projectUnassigned,
                key: Key('project_unassigned_${tilette.id}'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: TileColors.progressMedium)),
          for (final (RosterRow person, RosterCell cell) in assignees)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(person.label, style: theme.textTheme.bodyMedium),
                  switch (cell.rsvp) {
                    InvitationStatus.accepted => TileShareStatusPill(
                        label: l10n.accepted, tone: StatusPillTone.success),
                    InvitationStatus.declined => TileShareStatusPill(
                        label: l10n.declined, tone: StatusPillTone.danger),
                    _ => TileShareStatusPill(
                        label: l10n.participantInvited,
                        tone: StatusPillTone.warning),
                  },
                  if (cell.rsvp == InvitationStatus.accepted &&
                      cell.completion != null)
                    Text('${cell.completion!.round()}%', style: quiet),
                ],
              ),
            ),
          if (working)
            Row(children: [
              const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.projectReassigning, style: quiet)),
            ])
          else if (failed)
            Row(children: [
              Expanded(
                child: Text(l10n.projectReassignFailed,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.error)),
              ),
              TextButton(
                key: Key('project_retry_${tilette.id}'),
                onPressed: onRetry,
                child: Text(l10n.attentionRetry),
              ),
            ]),
          if (onAssign != null && !working)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: Key('project_assign_${tilette.id}'),
                onPressed: onAssign,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(assignees.isEmpty
                    ? l10n.projectAssign
                    : l10n.projectReassign),
              ),
            ),
        ],
      ),
    );
  }
}

/// One person in a Project: who, which tasks they own, and how their
/// invitation was delivered.
class ProjectPersonRow extends StatelessWidget {
  final RosterRow row;
  final List<TileShareTemplate> tilettes;
  final VoidCallback? onRemove;

  const ProjectPersonRow(
      {super.key, required this.row, required this.tilettes, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? quiet =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final List<String> owned = <String>[
      for (int i = 0; i < row.cells.length && i < tilettes.length; i++)
        if (row.cells[i].isPresent) projectTaskName(l10n, tilettes[i]),
    ];
    final String? delivery = ParticipantRow.deliveryText(l10n, row);
    final bool deliveryProblem = row.delivery == RecipientDelivery.failed ||
        row.delivery == RecipientDelivery.unknown;
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
                Text(l10n.projectOwnsTasks(owned.length), style: quiet),
                for (final String name in owned)
                  Text(name, style: theme.textTheme.bodySmall),
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
            ),
          ),
          if (onRemove != null && row.assignmentId != null)
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

/// Who gets the task named [taskName] (an existing task, or one being
/// added): someone already in the project, or a new contact. Completes with
/// the chosen contact, or `null` when dismissed.
Future<Contact?> showProjectAssignSheet(
    BuildContext context, String taskName, List<RosterRow> people,
    {Set<String> exclude = const <String>{}}) {
  return showModalBottomSheet<Contact>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final AppLocalizations l10n = AppLocalizations.of(sheetContext)!;
      final ThemeData theme = Theme.of(sheetContext);
      final List<RosterRow> others = people
          .where((p) => p.contact != null && !exclude.contains(p.key))
          .toList();
      return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            key: const Key('project_assign_sheet'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    l10n.projectAssignTitle(taskName.trim().isEmpty
                        ? l10n.clusterTitleFallback
                        : taskName.trim()),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ContactInputFieldWidget(
                  isReadOnly: false,
                  showPills: false,
                  startExpanded: true,
                  onContactAdded: (contact) =>
                      Navigator.of(sheetContext).pop(contact),
                ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l10n.projectAlreadyIn,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final RosterRow p in others)
                        ActionChip(
                          label: Text(p.label),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(p.contact),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
