import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/taskSheet.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

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

  /// Edits [tilette]: only what changed is sent; its length stays. Its notes
  /// are edited on the notes page and save themselves (the tilette notes
  /// endpoint, as tile notes do); the share reloads after if they changed.
  Future<void> edit(BuildContext context, TileShareTemplate tilette,
      {required TaskSheetPeople people}) async {
    final String? id = tilette.id;
    final NotesApi? notesApi = cubit.tiletteNotes;
    if (id == null) return;
    bool notesChanged = false;
    await showTaskSheet(
      context,
      TaskSheet(
        task: tilette,
        people: people,
        roster: roster,
        notesSaveThemselves: notesApi != null,
        editNotes: notesApi == null
            ? null
            : (context, notes) => Navigator.of(context).push<String?>(
                  MaterialPageRoute<String?>(
                    builder: (_) => NoteFullPage(
                      eventId: id,
                      initialNote: notes,
                      notesApi: notesApi,
                      onNotePersisted: (_) => notesChanged = true,
                    ),
                  ),
                ),
        shareDeadlineMs: _shareDeadlineMs,
        onSave: (TaskSheetValue _, TaskChanges changes) async {
          if (changes.isEmpty) return true;
          return _kept(await cubit.updateTask(id,
              name: changes.name, endMs: changes.endMs));
        },
        onDelete: () async => _kept(await cubit.deleteTask(id)),
      ),
    );
    if (notesChanged && !cubit.isClosed) await cubit.refresh();
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
