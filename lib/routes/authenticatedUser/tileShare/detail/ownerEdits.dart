import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/components/nameAndDateSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/taskSheet.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// What a name-and-deadline edit changed; a field left `null` stayed.
class NameDeadlineChange {
  final String? name;
  final int? endMs;

  const NameDeadlineChange({this.name, this.endMs});

  /// What [update] changed from [name] and [endMs]: a blank or unchanged
  /// name, and an unchanged or cleared deadline, are left out.
  factory NameDeadlineChange.of(NameAndEndTimeUpdate update,
      {String? name, int? endMs}) {
    final String trimmed = (update.Name ?? '').trim();
    final int? end = update.EndTime?.millisecondsSinceEpoch;
    return NameDeadlineChange(
      name: trimmed.isEmpty || trimmed == (name ?? '').trim() ? null : trimmed,
      endMs: end == endMs ? null : end,
    );
  }

  bool get isEmpty => name == null && endMs == null;
}

/// Edits a name and a deadline in the app's name-and-date sheet, under
/// [title] (and [note]). Completes with only what changed, or `null` when
/// dismissed.
Future<NameDeadlineChange?> showNameDeadlineSheet(
  BuildContext context, {
  required Key sheetKey,
  required String title,
  String? note,
  String? name,
  int? endMs,
}) {
  final DateTime? end =
      endMs == null ? null : DateTime.fromMillisecondsSinceEpoch(endMs);
  return showModalBottomSheet<NameDeadlineChange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        key: sheetKey,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: NameAndDateSheetWidget(
          name: name,
          endTime: end,
          appBar: _SheetTitle(title: title, note: note),
          onAddTileShare: (NameAndEndTimeUpdate update) =>
              Navigator.of(sheetContext)
                  .pop(NameDeadlineChange.of(update, name: name, endMs: endMs)),
        ),
      ),
    ),
  );
}

/// Asks before something that cannot be undone; `true` once confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required Key confirmKey,
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child:
              Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
        TextButton(
          key: confirmKey,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// The owner's changes to the share's tasks (Steps 9.16b, 9.16f), through
/// the detail cubit, in the task sheet (T27).
///
/// A change refused in the sheet is said there, so the detail's banner is
/// dismissed - except when a new task was added but its notes were refused:
/// the task exists, the sheet closes, and the banner retries the notes.
class TaskEditor {
  final TileShareDetailCubit cubit;

  /// The share's roster, for the people of a tilette being edited.
  final TileShareRosterCubit? roster;

  const TaskEditor(this.cubit, {this.roster});

  /// The editor when the signed-in user can change this share now; read
  /// under the roster detail, which provides the roster.
  static TaskEditor? of(BuildContext context) {
    final TileShareDetailCubit cubit = context.read<TileShareDetailCubit>();
    if (!cubit.canEdit) return null;
    return TaskEditor(cubit, roster: context.read<TileShareRosterCubit>());
  }

  int? get _shareDeadlineMs => cubit.state.cluster?.endTimeInMs;

  /// Adds a task: a Class's to [everyone]; a Project's to the assignee
  /// picked from [projectPeople], or to no one yet.
  Future<void> add(
    BuildContext context, {
    required TaskSheetPeople people,
    List<Contact> everyone = const <Contact>[],
    List<RosterRow> projectPeople = const <RosterRow>[],
  }) =>
      showTaskSheet(
        context,
        TaskSheet(
          people: people,
          shareDeadlineMs: _shareDeadlineMs,
          pickAssignee: people == TaskSheetPeople.assignee
              ? projectAssigneePicker(projectPeople)
              : null,
          onSave: (TaskSheetValue value, TaskChanges _) async {
            final Contact? assignee = value.assignee;
            final List<Contact> to = people == TaskSheetPeople.everyone
                ? everyone
                : <Contact>[if (assignee != null) assignee];
            final ClusterTemplateTileModel task = ClusterTemplateTileModel()
              ..Name = value.name
              ..DurationInMs = value.length.inMilliseconds
              ..EndTime = value.deadline.millisecondsSinceEpoch
              ..Contacts = to.map((c) => c.toContactModel()).toList();
            if (await cubit.addTask(task, notes: value.notes)) return true;
            // Added, but its notes were refused: the banner retries them.
            if (cubit.state.editFailed == DetailEdit.editTask) return true;
            cubit.dismissEditFailure();
            return false;
          },
        ),
      );

  /// Edits [tilette]: only what changed is sent; its length stays.
  Future<void> edit(BuildContext context, TileShareTemplate tilette,
      {required TaskSheetPeople people}) {
    final String? id = tilette.id;
    if (id == null) return Future<void>.value();
    return showTaskSheet(
      context,
      TaskSheet(
        task: tilette,
        people: people,
        roster: roster,
        shareDeadlineMs: _shareDeadlineMs,
        onSave: (TaskSheetValue _, TaskChanges changes) async {
          if (changes.isEmpty) return true;
          return _kept(await cubit.updateTask(id,
              name: changes.name, endMs: changes.endMs, notes: changes.notes));
        },
        onDelete: () async => _kept(await cubit.deleteTask(id)),
      ),
    );
  }

  bool _kept(bool ok) {
    if (!ok) cubit.dismissEditFailure();
    return ok;
  }

  /// Deletes [tilette] from its menu, after asking; a refusal shows on the
  /// detail.
  Future<void> delete(BuildContext context, TileShareTemplate tilette) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String name = (tilette.name ?? '').trim().isEmpty
        ? l10n.clusterTitleFallback
        : tilette.name!.trim();
    final bool ok = await confirmDestructive(context,
        title: l10n.detailDeleteTaskTitle(name),
        body: l10n.detailDeleteTaskBody,
        confirmLabel: l10n.delete,
        confirmKey: const Key('task_delete_confirm'));
    if (ok && tilette.id != null) await cubit.deleteTask(tilette.id!);
  }
}

enum _TaskAction { edit, delete }

/// A task's Edit / Delete menu.
class TaskMenu extends StatelessWidget {
  final TileShareTemplate tilette;
  final TaskEditor editor;
  final TaskSheetPeople people;

  const TaskMenu(
      {super.key,
      required this.tilette,
      required this.editor,
      required this.people});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String id = tilette.id ?? '';
    return PopupMenuButton<_TaskAction>(
      key: Key('task_menu_$id'),
      tooltip: l10n.detailEditTask,
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => switch (action) {
        _TaskAction.edit => editor.edit(context, tilette, people: people),
        _TaskAction.delete => editor.delete(context, tilette),
      },
      itemBuilder: (_) => [
        PopupMenuItem<_TaskAction>(
          key: Key('task_edit_$id'),
          value: _TaskAction.edit,
          child: Text(l10n.detailEditTask),
        ),
        PopupMenuItem<_TaskAction>(
          key: Key('task_delete_$id'),
          value: _TaskAction.delete,
          child: Text(l10n.detailDeleteTask),
        ),
      ],
    );
  }
}

/// "Tasks (N)", with "+ Add task" beside it for the owner (mock B).
class TasksHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onAdd;

  const TasksHeader({super.key, required this.count, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final VoidCallback? add = onAdd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('${l10n.detailTasks} ($count)',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (add != null)
            TextButton.icon(
              key: const Key('roster_add_task'),
              onPressed: add,
              icon: const Icon(Icons.add),
              label: Text(l10n.detailAddTask),
            ),
        ],
      ),
    );
  }
}

/// A task as a card in the Tasks tab (mock B's task rows).
class TaskCard extends StatelessWidget {
  final Widget child;

  const TaskCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

class _SheetTitle extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? note;

  const _SheetTitle({required this.title, this.note});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
