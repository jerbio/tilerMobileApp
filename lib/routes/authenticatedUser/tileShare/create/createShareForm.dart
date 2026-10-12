import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/taskSheet.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/contactFieldRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/deadlinePicker.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/shareDetailsForm.dart'
    show shareNameMaxLength, shareNameMinLength;
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personLine.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Picks a length, starting from [seed]. Injected in tests.
typedef CreatePickDuration = Future<Duration?> Function(
    BuildContext context, Duration seed);

/// Called once the share exists, with its id; the host opens it.
typedef OnShareCreated = void Function(BuildContext context, String clusterId);

/// A Broadcast's length when none is picked.
const Duration defaultBroadcastLength = Duration(hours: 1);

/// A new share's deadline when none is picked: a week from [now], at the end
/// of that day. Every share has one (owner, 9.18).
DateTime defaultShareDeadline(DateTime now) =>
    DateTime(now.year, now.month, now.day + 7, 23, 59);

Future<Duration?> _durationScreen(BuildContext context, Duration seed) =>
    pushDurationPicker(context, initialDuration: seed);

/// Shared create form and send lifecycle. Broadcast has one tilette and
/// people on one screen; Class stages tilettes before its people screen.
class CreateShareForm extends StatefulWidget {
  final TileShareMode mode;
  final TileShareCreateSource source;
  final OnShareCreated onCreated;
  final DateTime Function() now;
  final CreatePickDuration pickDuration;
  final DeadlinePickDate pickDate;
  final DeadlinePickTime pickTime;

  /// Edits a tilette's notes; the notes page when null. Injected in tests.
  final TaskSheetEditNotes? editNotes;

  const CreateShareForm({
    super.key,
    required this.source,
    required this.mode,
    required this.onCreated,
    this.now = DateTime.now,
    this.pickDuration = _durationScreen,
    this.pickDate = platformPickDate,
    this.pickTime = platformPickTime,
    this.editNotes,
  }) : assert(mode == TileShareMode.broadcast || mode == TileShareMode.class_);

  @override
  State<CreateShareForm> createState() => _CreateShareFormState();
}

class _CreateShareFormState extends State<CreateShareForm> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Duration _length = defaultBroadcastLength;
  late DateTime _deadline;
  late final DateTime _initialDeadline;
  final List<Contact> _people = <Contact>[];
  String? _duplicate;
  String? _nameError;
  bool _needsPerson = false;
  bool _busy = false;
  bool _failed = false;
  bool _peopleStep = false;
  bool _needsTask = false;

  /// The tilettes staged for a Class, in order. One without its own
  /// deadline ([ownDeadline] false) follows the share's (owner, 9.19).
  final List<({int id, TaskSheetValue value, bool ownDeadline})> _tasks = [];
  int _nextTaskId = 0;
  final Set<int> _removingTasks = {};
  List<({int id, TaskSheetValue value, bool ownDeadline})> get _activeTasks =>
      _tasks.where((t) => !_removingTasks.contains(t.id)).toList();
  bool get _isClass => widget.mode == TileShareMode.class_;
  String get _prefix => _isClass ? 'create_class' : 'create_broadcast';
  Duration get _effort =>
      _activeTasks.fold(Duration.zero, (sum, task) => sum + task.value.length);

  /// Adds a tilette, or edits draft [index], in the tilette sheet. A
  /// deadline left at the share's is not the tilette's own: it follows the
  /// share's.
  Future<void> _task({int? index}) async {
    final draft = index == null ? null : _tasks[index];
    await showTaskSheet(
        context,
        TaskSheet(
          draft: true,
          task: draft == null
              ? null
              : TileShareTemplate.fromJson({
                  'name': draft.value.name,
                  'duration': draft.value.length.inMilliseconds,
                  if (draft.ownDeadline)
                    'end': draft.value.deadline.millisecondsSinceEpoch,
                  'miscData': {'userNote': draft.value.notes},
                }),
          people: TaskSheetPeople.everyone,
          shareDeadlineMs: _deadline.millisecondsSinceEpoch,
          pickDuration: widget.pickDuration,
          pickDate: widget.pickDate,
          pickTime: widget.pickTime,
          editNotes: widget.editNotes,
          onSave: (value, _) async {
            setState(() {
              if (value.moveShareDeadline) _deadline = value.deadline;
              final entry = (
                id: draft?.id ?? _nextTaskId++,
                value: value,
                ownDeadline: value.deadline != _deadline,
              );
              if (index == null) {
                _tasks.add(entry);
              } else {
                _tasks[index] = entry;
              }
              _needsTask = false;
            });
            return true;
          },
        ));
  }

  void _next() {
    final problem = _nameProblem(AppLocalizations.of(context)!);
    setState(() {
      _nameError = problem;
      _needsTask = _activeTasks.isEmpty;
      if (problem == null && !_needsTask) _peopleStep = true;
    });
  }

  /// A draft's deadline as sent: its own, or the share's.
  DateTime _dueOf(({int id, TaskSheetValue value, bool ownDeadline}) task) =>
      task.ownDeadline ? task.value.deadline : _deadline;

  Widget _taskList(AppLocalizations l10n, TodayStatusTokens tokens,
      TextTheme textTheme, String locale) {
    final DateFormat day = DateFormat.MMMEd(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(l10n.createTilettesLabel,
              style: textTheme.labelSmall
                  ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6)),
        ),
        AddTileSection(children: [
          if (_tasks.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _tasks.length,
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _tasks.insert(newIndex, _tasks.removeAt(oldIndex));
              }),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final String length =
                    formatDurationSummary(l10n, task.value.length) ?? '';
                // Arrives and leaves as the shared lists' rows do (T11).
                return AnimatedPresence(
                  key: Key('create_class_task_${task.id}'),
                  leaving: _removingTasks.contains(task.id),
                  onGone: () => setState(() {
                    _tasks.removeWhere((t) => t.id == task.id);
                    _removingTasks.remove(task.id);
                  }),
                  child: _DraftTiletteRow(
                    index: index,
                    name: task.value.name,
                    detail: task.ownDeadline
                        ? l10n.createTiletteDue(
                            length, day.format(task.value.deadline))
                        : l10n.createTiletteWithShare(length),
                    onTap: _busy ? null : () => _task(index: index),
                    remove: IconButton(
                      key: Key('create_class_remove_task_${task.id}'),
                      tooltip: l10n.detailDeleteTask,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _busy
                          ? null
                          : () => setState(() => _removingTasks.add(task.id)),
                    ),
                  ),
                );
              },
            ),
          AddTileNavRow(
            key: const Key('create_class_add_task'),
            icon: Icons.add,
            title: l10n.detailAddTask,
            onTap: _busy ? null : () => _task(),
          ),
        ]),
        RevealSlot(
          child: _needsTask
              ? Padding(
                  key: const Key('create_class_needs_task'),
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Text(l10n.createNeedsTask,
                      style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error)),
                )
              : null,
        ),
        const SizedBox(height: 12),
        AddTileSection(children: [
          AddTileFieldRow(
            key: const Key('create_class_effort'),
            icon: Icons.hourglass_empty_rounded,
            label: l10n.shareEditEffort,
            value: formatDurationSummary(l10n, _effort) ?? '',
            mutedIcon: true,
            helper: l10n.shareEditEffortHelper,
          ),
        ]),
      ],
    );
  }

  /// The people step opens with what is being sent.
  Widget _summary(AppLocalizations l10n, TodayStatusTokens tokens,
          TextTheme textTheme, String locale) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: AddTileSection(children: [
          Padding(
            key: const Key('create_class_summary'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name.text.trim(),
                    style: textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    l10n.createClassSummary(
                        _activeTasks.length,
                        formatDurationSummary(l10n, _effort) ?? '',
                        DateFormat.MMMEd(locale).format(_deadline)),
                    style: textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary)),
              ],
            ),
          ),
        ]),
      );

  @override
  void initState() {
    super.initState();
    _initialDeadline = defaultShareDeadline(widget.now());
    _deadline = _initialDeadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _entered =>
      _tasks.isNotEmpty ||
      _name.text.trim().isNotEmpty ||
      _people.isNotEmpty ||
      _length != defaultBroadcastLength ||
      _deadline != _initialDeadline;

  bool get _ready =>
      _name.text.trim().length >= shareNameMinLength &&
      _people.isNotEmpty &&
      (!_isClass || _activeTasks.isNotEmpty);

  static String _labelOf(Contact contact) =>
      (contact.email ?? contact.phoneNumber ?? '').trim();

  /// Adds someone; someone already on the list is said so, as listed.
  void _add(Contact contact) {
    final Set<String> keys = ClassFanout.identityKeys(contact);
    final Contact? known = _people
        .where((c) => ClassFanout.identityKeys(c).any(keys.contains))
        .firstOrNull;
    setState(() {
      if (known != null) {
        _duplicate = _labelOf(known);
      } else {
        _duplicate = null;
        _needsPerson = false;
        _people.add(contact);
      }
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

  String? _nameProblem(AppLocalizations l10n) {
    final String name = _name.text.trim();
    if (name.isEmpty) return l10n.addTileNameRequired;
    if (name.length < shareNameMinLength) return l10n.taskSheetNameTooShort;
    return null;
  }

  Future<void> _send() async {
    if (_busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? problem = _nameProblem(l10n);
    if (problem != null ||
        _people.isEmpty ||
        (_isClass && _activeTasks.isEmpty)) {
      setState(() {
        _nameError = problem;
        _needsPerson = _people.isEmpty;
      });
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    // By its mode only (the legacy IsMultiTilette is for older apps), so
    // the Broadcast's one tilette is sent as such, with its people; the
    // share's own list is empty, never null (the server joins the two).
    final int start = widget.now().millisecondsSinceEpoch;
    final int end = _deadline.millisecondsSinceEpoch;
    final ClusterTemplateTileModel tilette = ClusterTemplateTileModel()
      ..Name = _name.text.trim()
      ..DurationInMs = _length.inMilliseconds
      ..StartTime = start
      ..EndTime = end
      ..Contacts = _people.map((c) => c.toContactModel()).toList();
    final drafts = _activeTasks;
    final TileShareClusterData share = TileShareClusterData()
      ..name = _name.text.trim()
      ..mode = widget.mode
      ..startTimeInMs = start
      ..endTimeInMs = end
      ..contacts = <Contact>[]
      ..tilettes = _isClass
          ? [
              for (int i = 0; i < drafts.length; i++)
                ClusterTemplateTileModel()
                  ..Name = drafts[i].value.name
                  ..DurationInMs = drafts[i].value.length.inMilliseconds
                  ..OrderedIndex = i
                  ..StartTime = start
                  ..EndTime = _dueOf(drafts[i]).millisecondsSinceEpoch
                  ..NoteMiscData = drafts[i].value.notes
                  ..Contacts = _people.map((c) => c.toContactModel()).toList(),
            ]
          : <ClusterTemplateTileModel>[tilette];
    final String id;
    try {
      id = await widget.source.createShare(share);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    widget.onCreated(context, id);
  }

  /// Leaves, asking first when something was entered.
  Future<void> _leave() async {
    if (_busy) return;
    if (!_entered) {
      Navigator.of(context).pop();
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createDiscardTitle),
        content: Text(l10n.createDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notesConflictKeepEditing),
          ),
          TextButton(
            key: Key('${_prefix}_discard'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.editTileDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? quiet =
        textTheme.bodySmall?.copyWith(color: tokens.textSecondary);
    final String locale = Localizations.localeOf(context).toString();
    return PopScope(
      canPop: !_entered && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) {
          if (_peopleStep) {
            setState(() => _peopleStep = false);
          } else {
            _leave();
          }
        }
      },
      child: Scaffold(
        key: Key(_prefix),
        backgroundColor: tokens.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _peopleStep
              ? IconButton(
                  key: const Key('create_class_back'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      _busy ? null : () => setState(() => _peopleStep = false),
                )
              : IconButton(
                  key: Key('${_prefix}_close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : _leave,
                ),
          title: _isClass
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.createClassTitle),
                    Text(l10n.createStepOf(_peopleStep ? 2 : 1, 2),
                        style: textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary)),
                  ],
                )
              : Text(l10n.createBroadcastTitle),
        ),
        body: Column(
          children: [
            Expanded(
                child: AbsorbPointer(
              absorbing: _busy,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_peopleStep) ...[
                      AddTileSection(children: [
                        AddTileTextFieldRow(
                          icon: Icons.edit_outlined,
                          label: l10n.shareNameLabel,
                          controller: _name,
                          focusNode: _nameFocus,
                          fieldKey: Key('${_prefix}_name'),
                          required: true,
                          maxLength: shareNameMaxLength,
                          error: _nameError,
                          onChanged: (_) => setState(() => _nameError = null),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      AddTileSection(children: [
                        if (!_isClass)
                          AddTileFieldRow(
                            key: Key('${_prefix}_length'),
                            icon: Icons.hourglass_empty_rounded,
                            label: l10n.addTileFieldDuration,
                            value: formatDurationSummary(l10n, _length) ?? '',
                            onTap: _busy ? null : _pickLength,
                          ),
                        AddTileFieldRow(
                          key: Key('${_prefix}_deadline'),
                          icon: Icons.flag_outlined,
                          label: l10n.editTileFieldDeadline,
                          value: DateFormat.yMMMEd(locale)
                              .add_jm()
                              .format(_deadline),
                          onTap: _busy ? null : _pickDeadline,
                        ),
                      ]),
                      if (_isClass) _taskList(l10n, tokens, textTheme, locale),
                    ],
                    if (_isClass && _peopleStep)
                      _summary(l10n, tokens, textTheme, locale),
                    if (!_isClass || _peopleStep) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                        child: Text(l10n.taskSheetPeopleLabel,
                            style: textTheme.labelSmall?.copyWith(
                                color: tokens.textSecondary,
                                letterSpacing: 0.6)),
                      ),
                      AddTileSection(children: [
                        // People added or taken off grow in and shrink out
                        // (T11).
                        AnimatedKeyedColumn(children: [
                          for (final Contact c in _people)
                            KeyedSubtree(
                              key: Key('${_prefix}_person_${_labelOf(c)}'),
                              child: PersonLine(label: _labelOf(c), trailing: [
                                IconButton(
                                  key: Key('${_prefix}_remove_${_labelOf(c)}'),
                                  tooltip: l10n.participantRemove,
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _people.remove(c)),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ]),
                            ),
                        ]),
                        KeyedSubtree(
                          key: Key('${_prefix}_add_person'),
                          child: ContactFieldRow(
                            label: l10n.taskSheetAddPerson,
                            message: _duplicate == null
                                ? null
                                : l10n.participantAlreadyInvited(_duplicate!),
                            onContact: _add,
                          ),
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                        child: Text(
                            _isClass
                                ? l10n.createClassPeopleHint
                                : l10n.createBroadcastPeopleHint,
                            style: quiet),
                      ),
                    ],
                    RevealSlot(
                      child: _failed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AddTileCallout(
                                key: Key('${_prefix}_failed'),
                                icon: Icons.error_outline,
                                text: l10n.createFailed,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
            AddTilePrimaryButton(
              key: Key(_isClass && !_peopleStep
                  ? 'create_class_next'
                  : '${_prefix}_send'),
              label: _isClass && !_peopleStep
                  ? l10n.createNextPeople
                  : _people.isEmpty
                      ? l10n.createSend
                      : l10n.createSendTo(_people.length),
              busyLabel: l10n.createSending,
              enabled: _isClass && !_peopleStep
                  ? _name.text.trim().length >= shareNameMinLength &&
                      _activeTasks.isNotEmpty
                  : _ready,
              busy: _busy,
              hint: _needsPerson ? l10n.createNeedsPerson : null,
              onTap: _isClass && !_peopleStep ? _next : _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// A staged tilette in the form kit: its drag handle, its name, length and
/// when it is due, and the minus (as for people).
class _DraftTiletteRow extends StatelessWidget {
  final int index;
  final String name;
  final String detail;
  final VoidCallback? onTap;
  final Widget remove;

  const _DraftTiletteRow({
    required this.index,
    required this.name,
    required this.detail,
    required this.onTap,
    required this.remove,
  });

  @override
  Widget build(BuildContext context) {
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Material(
      color: tokens.surface,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child:
                        Icon(Icons.drag_indicator, color: tokens.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge
                              ?.copyWith(color: tokens.textPrimary)),
                      Text(detail,
                          style: textTheme.bodySmall
                              ?.copyWith(color: tokens.textSecondary)),
                    ],
                  ),
                ),
                remove,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
