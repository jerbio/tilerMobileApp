import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/ownerEdits.dart'
    show confirmDestructive;
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/projectRows.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/contactFieldRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/deadlinePicker.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personLine.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Who a task goes to, by the share's mode: everyone in a Class, the
/// assignee picked for a Project task (or no one yet).
/// Who a task goes to: [everyone] in a Class, one [assignee] in a Project,
/// or [none] yet - a new Project's tilette, assigned later on the board.
enum TaskSheetPeople { everyone, assignee, none }

/// A task as the sheet holds it.
class TaskSheetValue extends Equatable {
  final String name;
  final Duration length;
  final DateTime deadline;

  /// Markdown; empty for none.
  final String notes;
  final Contact? assignee;

  /// The owner ticked *Also move the share's deadline*: the share's deadline
  /// becomes [deadline] too. The server never moves it for a tilette's
  /// (9.16v), so the app does. Only with a deadline after the share's.
  final bool moveShareDeadline;

  const TaskSheetValue({
    required this.name,
    required this.length,
    required this.deadline,
    required this.notes,
    this.assignee,
    this.moveShareDeadline = false,
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
  List<Object?> get props => [
        name,
        length,
        deadline,
        notes,
        assignee?.email,
        assignee?.phoneNumber,
        moveShareDeadline,
      ];
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

/// The tallest the people list grows before it scrolls inside itself.
const double peopleListMaxHeight = 240;

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
///    tilette, adding someone (to every tilette, as Participants does) and
///    removing someone (from every tilette, asked first); a Project
///    tilette's assignee, and changing it (as Reassign does). People changes
///    are staged in the sheet - *Will be added*, *Will be removed*, *Will be
///    assigned* - and sent on Save; closing the sheet sends nothing. A
///    change that does not go through keeps the sheet, with Retry on it.
///    The people list scrolls in a box of its own, so the tilette's other
///    fields stay put.
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

  /// Unsaved create-flow tilette: its length is still editable.
  final bool draft;

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

  /// The notes are saved by the notes page itself (an existing tilette's,
  /// through the notes endpoint), so they are not part of Save.
  final bool notesSaveThemselves;

  const TaskSheet({
    super.key,
    this.task,
    this.draft = false,
    required this.people,
    required this.shareDeadlineMs,
    required this.onSave,
    this.onDelete,
    this.pickDate = platformPickDate,
    this.pickTime = platformPickTime,
    this.pickDuration = _durationScreen,
    TaskSheetEditNotes? editNotes,
    this.notesSaveThemselves = false,
    this.pickAssignee,
    this.roster,
  }) : editNotes = editNotes ?? _notesPage;

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
  late TaskSheetValue _initial;
  String? _nameError;
  bool _busy = false;
  bool _failed = false;

  /// *Also move the share's deadline*, ticked (only counts while late).
  bool _moveShare = false;

  /// People changes staged until Save: additions, removals (by roster row
  /// key) and a Project tilette's new assignee.
  final List<Contact> _adds = <Contact>[];
  final Set<String> _removals = <String>{};
  Contact? _newAssignee;
  String? _duplicate;
  bool _peopleFailed = false;
  bool _scrolled = false;
  final ScrollController _peopleScroll = ScrollController();

  bool get _peopleStaged =>
      _adds.isNotEmpty || _removals.isNotEmpty || _newAssignee != null;

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
    _peopleScroll.dispose();
    super.dispose();
  }

  TaskSheetValue get _value => TaskSheetValue(
        name: _name.text.trim(),
        length: _length,
        deadline: _deadline,
        notes: _notes,
        assignee: _assignee,
        moveShareDeadline: _late && _moveShare,
      );

  bool get _nameValid => _name.text.trim().length >= taskNameMinLength;
  bool get _changed => widget.isNew || _value != _initial || _peopleStaged;

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
      _peopleFailed = false;
    });
    final TaskChanges changes = _value.changesSince(_initial);
    if (widget.isNew ||
        widget.draft ||
        !changes.isEmpty ||
        _value.moveShareDeadline) {
      final bool ok = await widget.onSave(_value, changes);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _failed = true;
        });
        return;
      }
      _initial = _value;
    }
    final bool peopleOk = widget.isNew || await _sendPeople();
    if (!mounted) return;
    if (peopleOk) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _peopleFailed = true;
    });
  }

  /// Sends the staged people changes, one at a time, through the share's
  /// roster (the same calls as Participants and the board); `false` when
  /// any did not go through - the roster then shows it, with Retry.
  Future<bool> _sendPeople() async {
    final TileShareRosterCubit? roster = widget.roster;
    final String? id = widget.task?.id;
    if (roster == null || id == null) return true;
    bool ok = true;
    for (final Contact contact in List<Contact>.of(_adds)) {
      await roster.add(contact);
      final Set<String> keys = ClassFanout.identityKeys(contact);
      if (roster.state.rows.any((r) =>
          r.phase == RosterRowPhase.addFailed &&
          r.identities.any(keys.contains))) {
        ok = false;
      }
    }
    for (final String key in List<String>.of(_removals)) {
      await roster.remove(key);
      if (roster.state.rows
          .any((r) => r.key == key && r.phase == RosterRowPhase.removeFailed)) {
        ok = false;
      }
    }
    final Contact? who = _newAssignee;
    if (who != null) {
      await roster.assignTask(id, who,
          replacingAssignmentId:
              _assigneeOf(roster.state, id)?.$2.assignmentId);
      if (roster.state.tasks[id]?.phase == TaskChangePhase.failed) ok = false;
    }
    if (mounted) {
      setState(() {
        _adds.clear();
        _removals.clear();
        _newAssignee = null;
      });
    }
    return ok;
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
    if (edited == null || !mounted) return;
    setState(() {
      _notes = edited.trim();
      // Saved by the notes page already: not a change for Save.
      if (widget.notesSaveThemselves) {
        _initial = TaskSheetValue(
            name: _initial.name,
            length: _initial.length,
            deadline: _initial.deadline,
            notes: _notes,
            assignee: _initial.assignee);
      }
    });
  }

  Future<void> _pickAssignee() async {
    final TaskSheetPickAssignee? pick = widget.pickAssignee;
    if (pick == null) return;
    final Contact? who = await pick(context, _name.text.trim());
    if (who != null && mounted) setState(() => _assignee = who);
  }

  static RosterCell? _cellOf(RosterRow row, String tiletteId) {
    for (final RosterCell c in row.cells) {
      if (c.tiletteId == tiletteId) return c;
    }
    return null;
  }

  /// Who has the Project tilette [tiletteId], with their cell for it.
  static (RosterRow, RosterCell)? _assigneeOf(
      TileShareRosterState state, String tiletteId) {
    for (final RosterRow r in state.rows) {
      final RosterCell? c = _cellOf(r, tiletteId);
      if (c != null && c.isPresent) return (r, c);
    }
    return null;
  }

  static String _labelOf(Contact contact) =>
      (contact.email ?? contact.phoneNumber ?? '').trim();

  /// Stages someone to add; someone already here (or staged) is said so.
  void _stageAdd(TileShareRosterCubit roster, Contact contact) {
    final Set<String> keys = ClassFanout.identityKeys(contact);
    final bool known =
        roster.state.rows.any((r) => r.identities.any(keys.contains)) ||
            _adds.any((c) => ClassFanout.identityKeys(c).any(keys.contains));
    setState(() {
      if (known) {
        _duplicate = _labelOf(contact);
      } else {
        _duplicate = null;
        _adds.add(contact);
      }
    });
    if (!known) _showLastPerson();
  }

  /// Keeps the end of the people list - where someone just added is - in
  /// view while their row grows in, so the rows above slide up with it.
  void _showLastPerson() {
    Duration? start;
    void follow(Duration now) {
      if (!mounted || !_peopleScroll.hasClients) return;
      _peopleScroll.jumpTo(_peopleScroll.position.maxScrollExtent);
      start ??= now;
      if (now - start! <= AnimatedKeyedColumn.inDuration) {
        WidgetsBinding.instance.addPostFrameCallback(follow);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(follow);
  }

  /// Stages the removal. Nothing is sent before Save, and Undo takes it
  /// back, so there is nothing to confirm (owner).
  void _stageRemoval(RosterRow row) => setState(() => _removals.add(row.key));

  /// Stages a new assignee for the Project tilette, as Reassign would.
  Future<void> _stageAssignee(
      TileShareRosterCubit roster, RosterRow? current) async {
    final TaskSheetPickAssignee pick = widget.pickAssignee ??
        (context, name) => showProjectAssignSheet(
            context, name, roster.state.rows,
            exclude: {if (current != null) current.key});
    final Contact? who = await pick(context, _name.text.trim());
    if (who == null || !mounted) return;
    final Set<String> keys = ClassFanout.identityKeys(who);
    final bool same = current != null && current.identities.any(keys.contains);
    setState(() => _newAssignee = same ? null : who);
  }

  Widget _people(
      BuildContext context, TileShareRosterCubit roster, String tiletteId) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? quiet =
        textTheme.bodySmall?.copyWith(color: tokens.textSecondary);
    final Widget heading = Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(l10n.taskSheetPeopleLabel,
          style: textTheme.labelSmall
              ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6)),
    );

    return BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
      bloc: roster,
      builder: (context, state) {
        if (widget.people == TaskSheetPeople.assignee) {
          final (RosterRow, RosterCell)? holder = _assigneeOf(state, tiletteId);
          final RosterRow? current = holder?.$1;
          final Contact? next = _newAssignee;
          final TaskChange? change = state.tasks[tiletteId];
          final bool working = change?.phase == TaskChangePhase.working;
          return Column(
            key: const Key('task_sheet_people'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              AddTileSection(children: [
                AddTileFieldRow(
                  key: const Key('task_sheet_assignee'),
                  icon: Icons.person_add_alt_1_outlined,
                  label: l10n.taskSheetAssignee,
                  value: next != null
                      ? _labelOf(next)
                      : (current?.label ?? l10n.projectUnassigned),
                  valueIsPlaceholder: next == null && current == null,
                  helper: next == null ? null : l10n.taskSheetWillBeAssigned,
                  onTap: working || _busy
                      ? null
                      : () => _stageAssignee(roster, current),
                ),
              ]),
              RevealSlot(
                child: working
                    ? Padding(
                        key: const Key('task_sheet_reassigning'),
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                        child: Text(l10n.projectReassigning, style: quiet),
                      )
                    : change?.phase == TaskChangePhase.failed
                        ? Row(
                            key: const Key('task_sheet_reassign_failed'),
                            children: [
                                Expanded(
                                  child: Text(l10n.projectReassignFailed,
                                      style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                                ),
                                TextButton(
                                  onPressed: () => roster.retryTask(tiletteId),
                                  child: Text(l10n.attentionRetry),
                                ),
                              ])
                        : null,
              ),
              Padding(
                key: const Key('task_sheet_people_hint'),
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(l10n.taskSheetPeopleHintProject, style: quiet),
              ),
            ],
          );
        }
        // A Class: who has this tilette, anyone staged to add, and anyone
        // whose change did not go through.
        final List<Widget> rows = <Widget>[
          for (final RosterRow r in state.rows)
            if ((_cellOf(r, tiletteId)?.isPresent ?? false) ||
                r.phase != RosterRowPhase.saved)
              _PersonRow(
                key: Key('task_sheet_person_${r.label}'),
                row: r,
                rsvp: _cellOf(r, tiletteId)?.rsvp,
                removing: _removals.contains(r.key),
                onRemove: r.phase == RosterRowPhase.saved && !_busy
                    ? () => _stageRemoval(r)
                    : null,
                onUndo: () => setState(() => _removals.remove(r.key)),
                onRetry: switch (r.phase) {
                  RosterRowPhase.addFailed => () => roster.retryAdd(r.key),
                  RosterRowPhase.removeFailed => () => roster.remove(r.key),
                  _ => null,
                },
              ),
          for (final Contact c in _adds)
            _StagedPersonRow(
              key: Key('task_sheet_person_${_labelOf(c)}'),
              label: _labelOf(c),
              onUndo: () => setState(() => _adds.remove(c)),
            ),
        ];
        return Column(
          key: const Key('task_sheet_people'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            AddTileSection(children: [
              // Its own scroll, so a long list never moves the tilette's
              // other fields; people added or taken back grow in and shrink
              // out (T11). Empty, it takes no space.
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: peopleListMaxHeight),
                child: Scrollbar(
                  controller: _peopleScroll,
                  // All the rows are built (a roster is short), so the end
                  // of the list is exact when someone is added to it.
                  child: SingleChildScrollView(
                    key: const Key('task_sheet_people_list'),
                    controller: _peopleScroll,
                    child: AnimatedKeyedColumn(children: rows),
                  ),
                ),
              ),
              KeyedSubtree(
                key: const Key('task_sheet_add_person'),
                child: ContactFieldRow(
                  label: l10n.taskSheetAddPerson,
                  message: _duplicate == null
                      ? null
                      : l10n.participantAlreadyInvited(_duplicate!),
                  onContact: (c) => _stageAdd(roster, c),
                ),
              ),
            ]),
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
          // A line under the title once the body scrolls under it; the space
          // is always there, so nothing moves when it appears.
          SizedBox(
            height: 1,
            child: _scrolled
                ? ColoredBox(
                    key: const Key('task_sheet_header_divider'),
                    color: tokens.border)
                : null,
          ),
          Flexible(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0) {
                  final bool scrolled = n.metrics.pixels > 0;
                  if (scrolled != _scrolled) {
                    setState(() => _scrolled = scrolled);
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                key: const Key('task_sheet_body'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        onTap: isNew || widget.draft ? _pickLength : null,
                        mutedIcon: !isNew && !widget.draft,
                        helper: isNew || widget.draft
                            ? null
                            : l10n.detailTaskLengthFixed,
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
                    // Warnings and refusals grow in and shrink out, so the
                    // fields below slide (T11).
                    RevealSlot(
                      child: _late && shareEnd != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AddTileCallout(
                                    key: const Key('task_sheet_late'),
                                    icon: Icons.warning_amber_rounded,
                                    text: l10n.taskSheetAfterShareDeadline(
                                        _when(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                shareEnd))),
                                  ),
                                  const SizedBox(height: 8),
                                  // The server never moves the share's
                                  // deadline for a tilette's (9.16v); the
                                  // owner chooses to, knowingly.
                                  AddTileSection(children: [
                                    AddTileCheckboxRow(
                                      key: const Key('task_sheet_move_share'),
                                      label: l10n.taskSheetMoveShareDeadline(
                                          _when(_deadline)),
                                      value: _moveShare,
                                      onChanged: _busy
                                          ? null
                                          : (v) =>
                                              setState(() => _moveShare = v),
                                    ),
                                  ]),
                                ],
                              ),
                            )
                          : null,
                    ),
                    if (!isNew &&
                        widget.roster != null &&
                        widget.task?.id != null) ...[
                      const SizedBox(height: 16),
                      _people(context, widget.roster!, widget.task!.id!),
                      RevealSlot(
                        child: _peopleFailed
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: AddTileCallout(
                                  key: const Key('task_sheet_people_failed'),
                                  icon: Icons.error_outline,
                                  text: l10n.taskSheetPeopleFailed,
                                ),
                              )
                            : null,
                      ),
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
                            // No subtitle without notes: the tilettes may arrive without
                            // them, so "Not set" could be wrong.
                            _notes.isEmpty ? null : _notes,
                        // A preview: the full notes are on the notes page.
                        subtitleMaxLines: 3,
                        onTap: _editNotes,
                      ),
                    ]),
                    RevealSlot(
                      child: _failed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AddTileCallout(
                                key: const Key('task_sheet_failed'),
                                icon: Icons.error_outline,
                                text: l10n.editTileSaveFailed,
                              ),
                            )
                          : null,
                    ),
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
          ),
          AddTilePrimaryButton(
            key: const Key('task_sheet_save'),
            label: isNew ? l10n.detailAddTask : l10n.tileShareSaveChanges,
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

/// Someone with a Class tilette: their answer to it; *Will be removed* (with
/// Undo) once a removal is staged; that they are being added; Retry when a
/// change did not go through.
class _PersonRow extends StatelessWidget {
  final RosterRow row;
  final InvitationStatus? rsvp;
  final bool removing;
  final VoidCallback? onRemove;
  final VoidCallback onUndo;
  final VoidCallback? onRetry;

  const _PersonRow({
    super.key,
    required this.row,
    required this.rsvp,
    required this.removing,
    required this.onRemove,
    required this.onUndo,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String label = row.label;
    return switch (row.phase) {
      RosterRowPhase.adding =>
        PersonLine(label: label, note: l10n.participantAdding),
      RosterRowPhase.addFailed ||
      RosterRowPhase.removeFailed =>
        PersonLine(label: label, trailing: [
          TextButton(onPressed: onRetry, child: Text(l10n.attentionRetry)),
        ]),
      _ when removing => PersonLine(
            label: label,
            note: l10n.taskSheetWillBeRemoved,
            noteIsWarning: true,
            faded: true,
            trailing: [
              TextButton(
                key: Key('task_sheet_undo_$label'),
                onPressed: onUndo,
                child: Text(l10n.attentionUndo),
              ),
            ]),
      _ => PersonLine(
            label: label,
            below: switch (rsvp) {
              InvitationStatus.accepted => TileShareStatusPill(
                  label: l10n.accepted, tone: StatusPillTone.success),
              InvitationStatus.declined => TileShareStatusPill(
                  label: l10n.declined, tone: StatusPillTone.danger),
              _ => TileShareStatusPill(
                  label: l10n.participantInvited, tone: StatusPillTone.warning),
            },
            trailing: [
              if (onRemove != null)
                IconButton(
                  key: Key('task_sheet_remove_$label'),
                  tooltip: l10n.participantRemove,
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ]),
    };
  }
}

/// Someone staged to add: *Will be added*, with Undo.
class _StagedPersonRow extends StatelessWidget {
  final String label;
  final VoidCallback onUndo;

  const _StagedPersonRow(
      {super.key, required this.label, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return PersonLine(label: label, note: l10n.taskSheetWillBeAdded, trailing: [
      IconButton(
        key: Key('task_sheet_undo_$label'),
        tooltip: l10n.attentionUndo,
        onPressed: onUndo,
        icon: const Icon(Icons.close),
      ),
    ]);
  }
}
