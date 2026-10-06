import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/components/nameAndDateSheetWidget.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

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

/// A new task in the app's new-task sheet, sent to [contacts] unless the
/// owner changes them; due when the share is ([endMs]) unless it says
/// otherwise. Completes with the task, or `null` when dismissed.
Future<ClusterTemplateTileModel?> showAddTaskSheet(
  BuildContext context, {
  List<Contact> contacts = const <Contact>[],
  int? endMs,
}) {
  return showModalBottomSheet<ClusterTemplateTileModel>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          key: const Key('add_task_sheet'),
          child: NewTileShareSheetWidget(
            newTile: NewTile()
              ..contacts = contacts.map((c) => c.toContactModel()).toList(),
            isUpdate: false,
            title: AppLocalizations.of(sheetContext)!.detailAddTask,
            onAddTile: (NewTile tile) {
              final ClusterTemplateTileModel task =
                  tile.toClusterTemplateTileModel();
              task.EndTime ??= endMs;
              Navigator.of(sheetContext).pop(task);
            },
          ),
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

/// The owner's changes to the share's tasks (Step 9.16b), through the detail
/// cubit: add a task, rename it or move its deadline, delete it.
class TaskEditor {
  final TileShareDetailCubit cubit;

  const TaskEditor(this.cubit);

  /// The editor when the signed-in user can change this share now.
  static TaskEditor? of(BuildContext context) {
    final TileShareDetailCubit cubit = context.read<TileShareDetailCubit>();
    return cubit.canEdit ? TaskEditor(cubit) : null;
  }

  Future<void> add(BuildContext context,
      {List<Contact> contacts = const <Contact>[]}) async {
    final ClusterTemplateTileModel? task = await showAddTaskSheet(context,
        contacts: contacts, endMs: cubit.state.cluster?.endTimeInMs);
    if (task != null) await cubit.addTask(task);
  }

  Future<void> edit(BuildContext context, TileShareTemplate tilette) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final NameDeadlineChange? change = await showNameDeadlineSheet(context,
        sheetKey: const Key('task_edit_sheet'),
        title: l10n.detailEditTask,
        note: l10n.detailTaskLengthFixed,
        name: tilette.name,
        endMs: tilette.end);
    if (change == null || change.isEmpty || tilette.id == null) return;
    await cubit.updateTask(tilette.id!, name: change.name, endMs: change.endMs);
  }

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

  const TaskMenu({super.key, required this.tilette, required this.editor});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String id = tilette.id ?? '';
    return PopupMenuButton<_TaskAction>(
      key: Key('task_menu_$id'),
      tooltip: l10n.detailEditTask,
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => switch (action) {
        _TaskAction.edit => editor.edit(context, tilette),
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

/// "Add task", under a share's tasks.
class AddTaskButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTaskButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const Key('roster_add_task'),
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.detailAddTask),
        ),
      );
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
