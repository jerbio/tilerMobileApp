import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/ownerEdits.dart'
    show confirmDestructive;
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/projectRows.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/deadlinePicker.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/shareDetailsForm.dart'
    show tiletteAccepted;
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Who a task goes to, by the share's mode: everyone in a Class, the
/// assignee picked for a Project task (or no one yet).
enum TaskSheetPeople { everyone, assignee }

/// A task as the sheet holds it.
class TaskSheetValue extends Equatable {
  final String name;
  final Duration length;
  final DateTime deadline;

  /// Markdown; empty for none.
  final String notes;
  final Contact? assignee;

  const TaskSheetValue({
    required this.name,
    required this.length,
    required this.deadline,
    required this.notes,
    this.assignee,
  });

  /// What changed since [before] (what the sheet opened with) - the only
  /// fields an edit sends (T27). A task without its own deadline opens on
  /// the share's; leaving it there is not a change.
  TaskChanges changesSince(TaskSheetValue before) {
    final String trimmed = name.trim();
    final String notesNow = notes.trim();
    return TaskChanges(
      name: trimmed == before.name.trim() ? null : trimmed,
      endMs:
          deadline == before.deadline ? null : deadline.millisecondsSinceEpoch,
      notes: notesNow == before.notes.trim() ? null : notesNow,
    );
  }

  @override
  List<Object?> get props =>
      [name, length, deadline, notes, assignee?.email, assignee?.phoneNumber];
}

/// The fields an edit changed; `null` when unchanged.
class TaskChanges extends Equatable {
  final String? name;
  final int? endMs;
  final String? notes;

  const TaskChanges({this.name, this.endMs, this.notes});

  bool get isEmpty => name == null && endMs == null && notes == null;

  @override
  List<Object?> get props => [name, endMs, notes];
}

typedef TaskSheetPickDuration = Future<Duration?> Function(
    BuildContext context, Duration seed);
typedef TaskSheetEditNotes = Future<String?> Function(
    BuildContext context, String notes);
typedef TaskSheetPickAssignee = Future<Contact?> Function(
    BuildContext context, String taskName);

/// The longest task name (T27).
const int taskNameMaxLength = 100;

/// The shortest task name.
const int taskNameMinLength = 3;

/// A new task's length until one is chosen.
const Duration defaultTaskLength = Duration(hours: 1);

/// Opens [sheet] as a bottom sheet.
Future<void> showTaskSheet(BuildContext context, TaskSheet sheet) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: TodayStatusTokens.of(context).surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: sheet,
      ),
    );

/// One sheet to add a task to a share and to edit one (redesign T27), built
/// from the redesign's form kit, as Add Tile and Edit Tile are.
///
///  * **Name**, 3 to 100 characters.
///  * **Length**, chosen when adding (an hour until then); shown as
///    information once shared - the server does not change it.
///  * **Deadline**, a date then a time, starting at the share's; a later one
///    is allowed with a warning.
///  * **Notes** (markdown) on the notes page, previewed in their row.
///  * **People** by mode: everyone in a Class; an optional assignee for a
///    new Project task. Editing, with the share's [roster]: who has a Class
///    tilette, and adding someone (to every tilette, as Participants does);
///    a Project tilette's assignee, and changing it (as Reassign does).
///    People changes go out at once with their own retry, not with Save.
///  * **Save** stays tappable to say what is missing; a refused save keeps
///    the sheet and what was typed. **Delete task** (editing) asks first.
///
/// It saves nothing itself: [onSave] gets the task and what changed since
/// the sheet opened; it and [onDelete] answer `true` when the change went
/// through, and the sheet closes.
class TaskSheet extends StatefulWidget {
  /// The task being edited; `null` adds one.
  final TileShareTemplate? task;
  final TaskSheetPeople people;

  /// The share's deadline: where a new task's starts, and the line past
  /// which a task's is warned about.
  final int? shareDeadlineMs;
  final Future<bool> Function(TaskSheetValue value, TaskChanges changes) onSave;
  final Future<bool> Function()? onDelete;

  final DeadlinePickDate pickDate;
  final DeadlinePickTime pickTime;
  final TaskSheetPickDuration pickDuration;
  final TaskSheetEditNotes editNotes;
  final TaskSheetPickAssignee? pickAssignee;

  /// The share's roster: who has the tilette, and changing it (editing).
  final TileShareRosterCubit? roster;

  const TaskSheet({
    super.key,
    this.task,
    required this.people,
    required this.shareDeadlineMs,
    required this.onSave,
    this.onDelete,
    this.pickDate = platformPickDate,
    this.pickTime = platformPickTime,
    this.pickDuration = _durationScreen,
    this.editNotes = _notesPage,
    this.pickAssignee,
    this.roster,
  });

  bool get isNew => task == null;

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

Future<Duration?> _durationScreen(BuildContext context, Duration seed) =>
    pushDurationPicker(context, initialDuration: seed);

Future<String?> _notesPage(BuildContext context, String notes) =>
    Navigator.of(context).push<String?>(MaterialPageRoute<String?>(
      builder: (_) => NoteFullPage.draft(initialNote: notes),
    ));

class _TaskSheetState extends State<TaskSheet> {
  late final TextEditingController _name;
  final FocusNode _nameFocus = FocusNode();
  late Duration _length;
  late DateTime _deadline;
  late String _notes;
  Contact? _assignee;
  late final TaskSheetValue _initial;
  String? _nameError;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final TileShareTemplate? task = widget.task;
    final int? shareEnd = widget.shareDeadlineMs;
    _name = TextEditingController(text: (task?.name ?? '').trim());
    _length = Duration(
        milliseconds: task?.durationInMs ?? defaultTaskLength.inMilliseconds);
    final int? end = task?.end ?? shareEnd;
    _deadline = end != null
        ? DateTime.fromMillisecondsSinceEpoch(end)
        : _endOfDay(DateTime.now().add(const Duration(days: 1)));
    _notes = (task?.miscData?.userNote ?? '').trim();
    _initial = _value;
  }

  static DateTime _endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59);

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  TaskSheetValue get _value => TaskSheetValue(
        name: _name.text.trim(),
        length: _length,
        deadline: _deadline,
        notes: _notes,
        assignee: _assignee,
      );

  bool get _nameValid => _name.text.trim().length >= taskNameMinLength;
  bool get _changed => widget.isNew || _value != _initial;

  bool get _late {
    final int? shareEnd = widget.shareDeadlineMs;
    return shareEnd != null && _deadline.millisecondsSinceEpoch > shareEnd;
  }

  String? _nameProblem(AppLocalizations l10n) {
    final String name = _name.text.trim();
    if (name.isEmpty) return l10n.addTileNameRequired;
    if (name.length < taskNameMinLength) return l10n.taskSheetNameTooShort;
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? problem = _nameProblem(l10n);
    if (problem != null) {
      setState(() => _nameError = problem);
      return;
    }
    if (!_changed) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool ok = await widget.onSave(_value, _value.changesSince(_initial));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  Future<void> _delete() async {
    final Future<bool> Function()? onDelete = widget.onDelete;
    if (onDelete == null || _busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String name = (widget.task?.name ?? '').trim();
    final bool confirmed = await confirmDestructive(context,
        title: l10n.detailDeleteTaskTitle(
            name.isEmpty ? l10n.clusterTitleFallback : name),
        body: l10n.detailDeleteTaskBody,
        confirmLabel: l10n.delete,
        confirmKey: const Key('task_delete_confirm'));
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool ok = await onDelete();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  Future<void> _pickLength() async {
    final Duration? picked = await widget.pickDuration(context, _length);
    if (picked != null && picked > Duration.zero && mounted) {
      setState(() => _length = picked);
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await pickDeadline(context, _deadline,
        pickDate: widget.pickDate, pickTime: widget.pickTime);
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  Future<void> _editNotes() async {
    final String? edited = await widget.editNotes(context, _notes);
    if (edited != null && mounted) setState(() => _notes = edited.trim());
  }

  Future<void> _pickAssignee() async {
    final TaskSheetPickAssignee? pick = widget.pickAssignee;
    if (pick == null) return;
    final Contact? who = await pick(context, _name.text.trim());
    if (who != null && mounted) setState(() => _assignee = who);
  }

  /// Gives the tilette to someone else, as Reassign on the board does.
  Future<void> _reassign(TileShareRosterCubit roster, String tiletteId,
      RosterRow? current, RosterCell? cell) async {
    final TaskSheetPickAssignee pick = widget.pickAssignee ??
        (context, name) => showProjectAssignSheet(
            context, name, roster.state.rows,
            exclude: {if (current != null) current.key});
    final Contact? who = await pick(context, _name.text.trim());
    if (who == null || !mounted) return;
    await roster.assignTask(tiletteId, who,
        replacingAssignmentId: cell?.assignmentId);
  }

  Widget _people(
      BuildContext context, TileShareRosterCubit roster, String tiletteId) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? quiet =
        textTheme.bodySmall?.copyWith(color: tokens.textSecondary);
    RosterCell? cellOf(RosterRow row) {
      for (final RosterCell c in row.cells) {
        if (c.tiletteId == tiletteId) return c;
      }
      return null;
    }

    return BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
      bloc: roster,
      builder: (context, state) {
        if (widget.people == TaskSheetPeople.assignee) {
          RosterRow? current;
          RosterCell? cell;
          for (final RosterRow r in state.rows) {
            final RosterCell? c = cellOf(r);
            if (c != null && c.isPresent) {
              current = r;
              cell = c;
              break;
            }
          }
          final TaskChange? change = state.tasks[tiletteId];
          final bool working = change?.phase == TaskChangePhase.working;
          return Column(
            key: const Key('task_sheet_people'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AddTileSection(children: [
                AddTileFieldRow(
                  key: const Key('task_sheet_assignee'),
                  icon: Icons.person_add_alt_1_outlined,
                  label: l10n.taskSheetAssignee,
                  value: current?.label ?? l10n.projectUnassigned,
                  valueIsPlaceholder: current == null,
                  onTap: working || _busy
                      ? null
                      : () => _reassign(roster, tiletteId, current, cell),
                ),
              ]),
              if (working)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Text(l10n.projectReassigning, style: quiet),
                )
              else if (change?.phase == TaskChangePhase.failed)
                Row(children: [
                  Expanded(
                    child: Text(l10n.projectReassignFailed,
                        style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                  TextButton(
                    onPressed: () => roster.retryTask(tiletteId),
                    child: Text(l10n.attentionRetry),
                  ),
                ]),
              Padding(
                key: const Key('task_sheet_people_hint'),
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(l10n.taskSheetPeopleHintProject, style: quiet),
              ),
            ],
          );
        }
        // A Class: who has this tilette, and anyone being added.
        final List<RosterRow> people = <RosterRow>[
          for (final RosterRow r in state.rows)
            if ((cellOf(r)?.isPresent ?? false) ||
                r.phase == RosterRowPhase.adding ||
                r.phase == RosterRowPhase.addFailed)
              r,
        ];
        return Column(
          key: const Key('task_sheet_people'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddTileSection(children: [
              for (final RosterRow r in people)
                _PersonRow(
                  key: Key('task_sheet_person_${r.label}'),
                  row: r,
                  rsvp: cellOf(r)?.rsvp,
                  onRetry: () => roster.retryAdd(r.key),
                ),
              KeyedSubtree(
                key: const Key('task_sheet_add_person'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ContactInputFieldWidget(
                    isReadOnly: false,
                    showPills: false,
                    startExpanded: true,
                    onContactAdded: roster.add,
                  ),
                ),
              ),
            ]),
            if (state.duplicate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(l10n.participantAlreadyInvited(state.duplicate!),
                    style: textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error)),
              ),
            Padding(
              key: const Key('task_sheet_people_hint'),
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(l10n.taskSheetPeopleHintClass, style: quiet),
            ),
          ],
        );
      },
    );
  }

  String _when(DateTime at) {
    final String locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).add_jm().format(at);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isNew = widget.isNew;
    final int? shareEnd = widget.shareDeadlineMs;
    final Contact? assignee = _assignee;

    return ConstrainedBox(
      key: const Key('task_sheet'),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(isNew ? l10n.detailAddTask : l10n.detailEditTask,
                      style: textTheme.titleLarge
                          ?.copyWith(color: tokens.textPrimary)),
                ),
                IconButton(
                  key: const Key('task_sheet_close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddTileSection(children: [
                    AddTileTextFieldRow(
                      icon: Icons.edit_outlined,
                      label: l10n.tiletteNameLabel,
                      controller: _name,
                      focusNode: _nameFocus,
                      fieldKey: const Key('task_sheet_name'),
                      required: true,
                      maxLength: taskNameMaxLength,
                      error: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  AddTileSection(children: [
                    AddTileFieldRow(
                      key: const Key('task_sheet_length'),
                      icon: Icons.hourglass_empty_rounded,
                      label: l10n.addTileFieldDuration,
                      value: formatDurationSummary(l10n, _length) ?? '',
                      // Once shared, information: no chevron, a quiet icon.
                      onTap: isNew ? _pickLength : null,
                      mutedIcon: !isNew,
                      helper: isNew ? null : l10n.detailTaskLengthFixed,
                    ),
                    AddTileFieldRow(
                      key: const Key('task_sheet_deadline'),
                      icon: Icons.flag_outlined,
                      label: l10n.editTileFieldDeadline,
                      value: _when(_deadline),
                      onTap: _pickDeadline,
                    ),
                    if (widget.people == TaskSheetPeople.assignee && isNew)
                      AddTileFieldRow(
                        key: const Key('task_sheet_assignee'),
                        icon: Icons.person_add_alt_1_outlined,
                        label: l10n.taskSheetAssignee,
                        value: assignee == null
                            ? l10n.projectUnassigned
                            : (assignee.displayedIdentifier ?? ''),
                        valueIsPlaceholder: assignee == null,
                        onTap: _pickAssignee,
                      ),
                  ]),
                  if (_late && shareEnd != null) ...[
                    const SizedBox(height: 12),
                    AddTileCallout(
                      key: const Key('task_sheet_late'),
                      icon: Icons.warning_amber_rounded,
                      // Someone has accepted it: the server moves the
                      // share's deadline out to this one (O27).
                      text: widget.task != null && tiletteAccepted(widget.task!)
                          ? l10n.taskSheetMovesShareDeadline(_when(_deadline))
                          : l10n.taskSheetAfterShareDeadline(_when(
                              DateTime.fromMillisecondsSinceEpoch(shareEnd))),
                    ),
                  ],
                  if (!isNew &&
                      widget.roster != null &&
                      widget.task?.id != null) ...[
                    const SizedBox(height: 12),
                    _people(context, widget.roster!, widget.task!.id!),
                  ],
                  if (widget.people == TaskSheetPeople.everyone && isNew) ...[
                    const SizedBox(height: 12),
                    AddTileCallout(
                      key: const Key('task_sheet_everyone'),
                      icon: Icons.groups_outlined,
                      text: l10n.taskSheetEveryone,
                    ),
                  ],
                  const SizedBox(height: 12),
                  AddTileSection(children: [
                    AddTileNavRow(
                      key: const Key('task_sheet_notes'),
                      icon: Icons.notes_rounded,
                      title: l10n.editTileNotesTitle,
                      subtitle:
                          _notes.isEmpty ? l10n.addTileValueNotSet : _notes,
                      // A preview: the full notes are on the notes page.
                      subtitleMaxLines: 3,
                      onTap: _editNotes,
                    ),
                  ]),
                  if (_failed) ...[
                    const SizedBox(height: 12),
                    AddTileCallout(
                      key: const Key('task_sheet_failed'),
                      icon: Icons.error_outline,
                      text: l10n.editTileSaveFailed,
                    ),
                  ],
                  if (!isNew && widget.onDelete != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      child: TextButton.icon(
                        key: const Key('task_sheet_delete'),
                        onPressed: _busy ? null : _delete,
                        style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.detailDeleteTask),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AddTilePrimaryButton(
            key: const Key('task_sheet_save'),
            label: isNew ? l10n.detailAddTask : l10n.editTileSave,
            busyLabel: l10n.editTileSaving,
            enabled: _nameValid && _changed,
            busy: _busy,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

/// The people already in a project, offered when assigning a new task.
TaskSheetPickAssignee projectAssigneePicker(List<RosterRow> people) =>
    (context, taskName) => showProjectAssignSheet(context, taskName, people);

/// Someone with a Class tilette: their answer to it, or that they are
/// being added (with Retry when that failed).
class _PersonRow extends StatelessWidget {
  final RosterRow row;
  final InvitationStatus? rsvp;
  final VoidCallback onRetry;

  const _PersonRow(
      {super.key,
      required this.row,
      required this.rsvp,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget status = switch (row.phase) {
      RosterRowPhase.adding => Text(l10n.participantAdding,
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary)),
      RosterRowPhase.addFailed =>
        TextButton(onPressed: onRetry, child: Text(l10n.attentionRetry)),
      _ => switch (rsvp) {
          InvitationStatus.accepted => TileShareStatusPill(
              label: l10n.accepted, tone: StatusPillTone.success),
          InvitationStatus.declined => TileShareStatusPill(
              label: l10n.declined, tone: StatusPillTone.danger),
          _ => TileShareStatusPill(
              label: l10n.participantInvited, tone: StatusPillTone.warning),
        },
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const AddTileIconChip(icon: Icons.person_outline),
          const SizedBox(width: 14),
          Expanded(
            child: Text(row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.bodyLarge?.copyWith(color: tokens.textPrimary)),
          ),
          const SizedBox(width: 8),
          status,
        ],
      ),
    );
  }
}
