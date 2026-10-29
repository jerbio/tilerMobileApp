import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/classPersonRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/ownerEdits.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/participantRow.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/projectRows.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/taskSheet.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'shareWorkWidgets.dart';
import 'tiletteWorkCard.dart';
import 'shareDisplayOptions.dart';

/// Which owner roster: everyone their own copy of one task (Broadcast), of
/// every task (Class), or one shared project with an assignee per task
/// (Project).
enum RosterMode { broadcast, classMode, project }

/// The owner's Broadcast detail (Step 9.13): Overview · Participants.
class BroadcastDetail extends StatelessWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  /// Opens a tilette's comments (its one thread, shared with everyone on
  /// it); no comments buttons without it.
  final void Function(TileShareTemplate tilette)? onComments;

  const BroadcastDetail(
      {super.key,
      required this.detail,
      required this.recipients,
      this.onComments});

  @override
  Widget build(BuildContext context) => ShareRosterDetail(
      detail: detail,
      recipients: recipients,
      mode: RosterMode.broadcast,
      onComments: onComments);
}

/// A Class's shared work, people and activity, with completion per person.
class ClassDetail extends StatelessWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  /// Opens a tilette's comments (its one thread, shared with everyone on
  /// it); no comments buttons without it.
  final void Function(TileShareTemplate tilette)? onComments;
  final WidgetBuilder? activityBuilder;
  final void Function(TileShareTemplate)? onNotes;
  final void Function(TileShareTemplate)? onOpen;

  const ClassDetail(
      {super.key,
      required this.detail,
      required this.recipients,
      this.onComments,
      this.activityBuilder,
      this.onNotes,
      this.onOpen});

  @override
  Widget build(BuildContext context) => ShareRosterDetail(
      detail: detail,
      recipients: recipients,
      mode: RosterMode.classMode,
      onOpen: onOpen,
      activityBuilder: activityBuilder,
      onNotes: onNotes,
      onComments: onComments);
}

/// A Project's work board, people and activity, with progress per tilette.
class ProjectDetail extends StatelessWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  /// Opens a tilette's comments (its one thread, shared with everyone on
  /// it); no comments buttons without it.
  final void Function(TileShareTemplate tilette)? onComments;
  final WidgetBuilder? activityBuilder;
  final void Function(TileShareTemplate)? onNotes;
  final void Function(TileShareTemplate)? onOpen;

  const ProjectDetail(
      {super.key,
      required this.detail,
      required this.recipients,
      this.onComments,
      this.activityBuilder,
      this.onNotes,
      this.onOpen});

  @override
  Widget build(BuildContext context) => ShareRosterDetail(
      detail: detail,
      recipients: recipients,
      mode: RosterMode.project,
      onOpen: onOpen,
      activityBuilder: activityBuilder,
      onNotes: onNotes,
      onComments: onComments);
}

enum _Segment { overview, tasks, participants, activity }

/// The owner's roster detail (redesign §5.4), under the detail header: a
/// **Broadcast** (everyone their own copy of one task), a **Class** (of every
/// task) or a **Project** (one shared project, an assignee per task):
///
/// * **Overview** previews: the answers (people who accepted everything, for a
///   Class), who is missing from some tasks, who may not have got the
///   invitation, the first few people and "View all" - never the whole list.
/// * **Tasks**: each task with its own answers (Class), or the board - each
///   task's assignee, their answer and that task's own progress, "No one
///   assigned", Assign / Reassign (Project; no rolled-up total, no Accept
///   all). The owner adds a task (a Class's goes to everyone in it, a
///   Project's to no one yet), and renames or deletes one (Step 9.16b).
/// * **Participants**: the add field and the roster. A Broadcast row shows the
///   answer, progress and delivery; a Class row one segment per task, "Not on
///   N tasks" with "Add to all tasks", and the person's tasks on tap.
///
/// One roster cubit for the share's tasks (adds fan out to every task,
/// removals cover every task, one change at a time); it follows the detail's
/// reloads.
class ShareRosterDetail extends StatefulWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;
  final RosterMode mode;

  /// Opens a tilette's comments (its one thread, shared with everyone on
  /// it); no comments buttons without it.
  final void Function(TileShareTemplate tilette)? onComments;
  final WidgetBuilder? activityBuilder;
  final void Function(TileShareTemplate)? onNotes;
  final void Function(TileShareTemplate)? onOpen;

  /// How many people (or tasks) the Overview previews.
  static const int previewCount = 3;

  const ShareRosterDetail({
    super.key,
    required this.detail,
    required this.recipients,
    required this.mode,
    this.onComments,
    this.activityBuilder,
    this.onNotes,
    this.onOpen,
  });

  @override
  State<ShareRosterDetail> createState() => _ShareRosterDetailState();
}

class _ShareRosterDetailState extends State<ShareRosterDetail> {
  TileShareRosterCubit? _roster;
  _Segment _segment = _Segment.overview;
  ShareWorkFilter _filter = ShareWorkFilter.all;

  List<TileShareTemplate> get _tilettes => widget.mode == RosterMode.broadcast
      ? widget.detail.tilettes.take(1).toList()
      : widget.detail.tilettes;

  @override
  void initState() {
    super.initState();
    if (widget.mode != RosterMode.broadcast) _segment = _Segment.tasks;
    _start();
  }

  void _start() {
    final String? clusterId = widget.detail.cluster?.id;
    // Started with no tilettes too: a Project can have none (created that
    // way, or its last one deleted) and still needs its tabs and Add tilette.
    if (clusterId == null) return;
    _roster = TileShareRosterCubit(
      source: widget.recipients,
      clusterId: clusterId,
      tilettes: _tilettes,
    )..loadDelivery();
  }

  @override
  void didUpdateWidget(covariant ShareRosterDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_roster == null) {
      _start();
      return;
    }
    if (!identical(oldWidget.detail.tilettes, widget.detail.tilettes)) {
      _roster!.sync(_tilettes);
    }
  }

  @override
  void dispose() {
    _roster?.close();
    super.dispose();
  }

  void _go(_Segment segment) => setState(() => _segment = segment);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TileShareRosterCubit? roster = _roster;
    final comfortable =
        TileShareDisplayScope.densityOf(context) == TiletteDensity.comfortable;
    if (roster == null) return const SizedBox.shrink();
    final List<_Segment> segments = [
      if (widget.mode == RosterMode.broadcast) _Segment.overview,
      if (widget.mode != RosterMode.broadcast) _Segment.tasks,
      _Segment.participants,
      if (widget.mode != RosterMode.broadcast)
        widget.activityBuilder == null ? _Segment.overview : _Segment.activity,
    ];
    String label(_Segment s) => switch (s) {
          _Segment.overview => l10n.overview,
          _Segment.tasks => l10n.shareWork,
          _Segment.participants => l10n.sharePeople,
          _Segment.activity => l10n.shareActivity,
        };
    return BlocProvider<TileShareRosterCubit>.value(
      value: roster,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mode != RosterMode.broadcast) ...[
            BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
              builder: (context, state) => InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (sheetContext) => TileShareDisplayScope.wrap(
                      context,
                      SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _Overview(
                            state: state,
                            mode: widget.mode,
                            tilettes: _tilettes,
                            onParticipants: () {
                              Navigator.pop(sheetContext);
                              _go(_Segment.participants);
                            },
                            onTasks: () {
                              Navigator.pop(sheetContext);
                              _go(_Segment.tasks);
                            },
                            onComments: widget.onComments,
                          ),
                        ),
                      )),
                ),
                child: _WorkSummary(
                    state: state, mode: widget.mode, tilettes: _tilettes),
              ),
            ),
            SizedBox(height: comfortable ? 20 : 8),
          ],
          ShareDetailTabs<_Segment>(
            tabs: [
              for (final _Segment s in segments)
                (s, label(s), Key('roster_segment_${s.name}')),
            ],
            selected: _segment,
            onChanged: _go,
          ),
          SizedBox(height: comfortable ? 16 : 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
              key: ValueKey<_Segment>(_segment),
              builder: (context, state) => switch (_segment) {
                _Segment.activity => widget.activityBuilder!(context),
                _Segment.overview => _Overview(
                    state: state,
                    mode: widget.mode,
                    tilettes: _tilettes,
                    onParticipants: () => _go(_Segment.participants),
                    onTasks: () => _go(_Segment.tasks),
                    onComments: widget.onComments),
                _Segment.tasks => widget.mode == RosterMode.project
                    ? _Board(
                        state: state,
                        roster: roster,
                        tilettes: _tilettes,
                        filter: _filter,
                        onFilter: (filter) => setState(() => _filter = filter),
                        onNotes: widget.onNotes,
                        onOpen: widget.onOpen,
                        onComments: widget.onComments)
                    : _Tasks(
                        state: state,
                        tilettes: _tilettes,
                        filter: _filter,
                        onFilter: (filter) => setState(() => _filter = filter),
                        onNotes: widget.onNotes,
                        onOpen: widget.onOpen,
                        onMissingAssignments: () => _go(_Segment.participants),
                        onComments: widget.onComments),
                _Segment.participants => _Participants(
                    state: state,
                    roster: roster,
                    mode: widget.mode,
                    tilettes: _tilettes),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A preview row: the mode's row, without actions.
Widget _previewRow(RosterRow row, RosterMode mode) =>
    mode == RosterMode.classMode
        ? ClassPersonRow(row: row)
        : ParticipantRow(row: row);

/// Whoever has task [index], with their cell for it.
List<(RosterRow, RosterCell)> _assigneesOf(List<RosterRow> rows, int index) =>
    <(RosterRow, RosterCell)>[
      for (final RosterRow r in rows)
        if (index < r.cells.length && r.cells[index].isPresent)
          (r, r.cells[index]),
    ];

class _WorkSummary extends StatelessWidget {
  final TileShareRosterState state;
  final RosterMode mode;
  final List<TileShareTemplate> tilettes;
  const _WorkSummary(
      {required this.state, required this.mode, required this.tilettes});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final rows = state.rows.where((r) => r.assignmentId != null).toList();
    bool complete(RosterCell c) =>
        c.rsvp == InvitationStatus.accepted &&
        (shareCompletion(c.completion) ?? 0) >= 100;
    if (mode == RosterMode.classMode) {
      final assignments =
          rows.expand((r) => r.cells).where((c) => c.isPresent).toList();
      final total = assignments.length;
      final missing = rows.length * tilettes.length - total;
      final done = assignments.where(complete).length;
      final attention = rows
          .where((r) =>
              r.isIncomplete ||
              r.delivery == RecipientDelivery.failed ||
              r.cells.any(
                  (c) => c.isPresent && c.rsvp != InvitationStatus.accepted))
          .length;
      return ShareWorkSummary(
        key: const Key('class_work_summary'),
        progress:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ShareCompletionBar(
              value: total == 0 ? 0 : done / total,
              label: l.shareCompletionCount(done, total)),
          if (missing > 0)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.shareMissingAssignments(missing),
                    style: TextStyle(color: TileColors.progressMedium))),
        ]),
        stats: [
          (Icons.people_outline, rows.length, l.sharePeople, scheme.tertiary),
          (
            Icons.error_outline,
            attention,
            l.shareNeedsAttention,
            TileColors.progressMedium
          ),
        ],
      );
    }
    int attention = 0, active = 0, done = 0, accepted = 0;
    for (int i = 0; i < tilettes.length; i++) {
      final cells = _assigneesOf(rows, i).map((a) => a.$2).toList();
      if (cells.isEmpty ||
          cells.any((c) => c.rsvp != InvitationStatus.accepted)) {
        attention++;
      } else if (cells.every(complete)) {
        done++;
      } else if (cells.any((c) => (shareCompletion(c.completion) ?? 0) > 0)) {
        active++;
      } else {
        accepted++;
      }
    }
    return ShareWorkSummary(key: const Key('project_work_summary'), stats: [
      (
        Icons.error_outline,
        attention,
        l.shareNeedsAttention,
        TileColors.progressMedium
      ),
      (
        Icons.timelapse,
        active,
        l.shareInProgress,
        TileColors.responseTileShare
      ),
      (
        Icons.check_circle_outline,
        done,
        l.completed,
        TileColors.acceptedTileShare
      ),
      if (accepted > 0)
        (Icons.check, accepted, l.accepted, scheme.onSurfaceVariant),
    ]);
  }
}

class _Overview extends StatelessWidget {
  final TileShareRosterState state;
  final RosterMode mode;
  final List<TileShareTemplate> tilettes;
  final VoidCallback onParticipants;
  final VoidCallback onTasks;
  final void Function(TileShareTemplate tilette)? onComments;

  const _Overview({
    required this.state,
    required this.mode,
    required this.tilettes,
    required this.onParticipants,
    required this.onTasks,
    this.onComments,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final List<RosterRow> saved =
        state.rows.where((r) => r.assignmentId != null).toList();
    final int issues = saved
        .where((r) =>
            r.delivery == RecipientDelivery.failed ||
            r.delivery == RecipientDelivery.unknown)
        .length;
    final bool isProject = mode == RosterMode.project;
    final int incomplete = saved.where((r) => r.isIncomplete).length;
    final List<int> taskIndexes = List<int>.generate(tilettes.length, (i) => i);
    final int unassigned = isProject
        ? taskIndexes.where((i) => _assigneesOf(state.rows, i).isEmpty).length
        : 0;
    final String? answers = switch (mode) {
      RosterMode.project => tilettes.isEmpty
          ? null
          : l10n.clusterRsvpTasks(
              taskIndexes
                  .where((i) => _assigneesOf(state.rows, i)
                      .any((a) => a.$2.rsvp == InvitationStatus.accepted))
                  .length,
              tilettes.length),
      RosterMode.classMode => saved.isEmpty
          ? null
          : l10n.clusterRsvpPeople(
              saved.where((r) => r.acceptedAll).length, saved.length),
      RosterMode.broadcast => saved.isEmpty
          ? null
          : l10n.clusterRsvpAccepted(
              saved.where((r) => r.rsvp == InvitationStatus.accepted).length,
              saved.length),
    };

    Widget alert(Key key, IconData icon, String text, Color color,
            {VoidCallback? onTap}) =>
        Padding(
          key: key,
          // The space above it comes and goes with it.
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: onTap ?? onParticipants,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(color: color)),
                  ),
                  Icon(Icons.chevron_right, color: color),
                ],
              ),
            ),
          ),
        );

    return Column(
      key: const Key('roster_overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (answers != null) Text(answers, style: theme.textTheme.titleSmall),
        // Alerts come and go with the roster; they grow in and shrink out so
        // the preview below slides (T11).
        RevealSlot(
          child: isProject && unassigned > 0
              ? alert(
                  const Key('project_unassigned_alert'),
                  Icons.assignment_late_outlined,
                  l10n.projectTasksUnassigned(unassigned),
                  theme.colorScheme.tertiary,
                  onTap: onTasks)
              : null,
        ),
        RevealSlot(
          child: mode == RosterMode.classMode && incomplete > 0
              ? alert(
                  const Key('class_incomplete'),
                  Icons.group_add_outlined,
                  l10n.classPeopleIncomplete(incomplete),
                  theme.colorScheme.tertiary)
              : null,
        ),
        RevealSlot(
          child: issues > 0
              ? alert(
                  const Key('roster_delivery_issues'),
                  Icons.mark_email_unread_outlined,
                  l10n.broadcastDeliveryIssues(issues),
                  theme.colorScheme.error)
              : null,
        ),
        const SizedBox(height: 8),
        if (isProject) ...[
          AnimatedKeyedColumn(children: [
            for (int i = 0;
                i < tilettes.length && i < ShareRosterDetail.previewCount;
                i++)
              KeyedSubtree(
                key: ValueKey<String>('preview_task_${tilettes[i].id}'),
                child: ProjectTaskRow(
                    tilette: tilettes[i],
                    assignees: _assigneesOf(state.rows, i)),
              ),
          ]),
          RevealSlot(
            child: tilettes.length > ShareRosterDetail.previewCount
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const Key('roster_view_all'),
                      onPressed: onTasks,
                      child: Text(l10n.broadcastViewAll(tilettes.length)),
                    ),
                  )
                : null,
          ),
        ] else ...[
          AnimatedKeyedColumn(children: [
            for (final RosterRow row
                in state.rows.take(ShareRosterDetail.previewCount))
              KeyedSubtree(
                key: ValueKey<String>('preview_person_${row.key}'),
                child: _previewRow(row, mode),
              ),
          ]),
          RevealSlot(
            child: state.rows.isEmpty
                ? Text(l10n.broadcastNoParticipants,
                    key: const Key('roster_preview_empty'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                : null,
          ),
          RevealSlot(
            child: state.rows.length > ShareRosterDetail.previewCount
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const Key('roster_view_all'),
                      onPressed: onParticipants,
                      child: Text(l10n.broadcastViewAll(state.rows.length)),
                    ),
                  )
                : null,
          ),
          // A Broadcast is one tilette and has no Tilettes tab: its comments
          // are here.
          if (mode == RosterMode.broadcast &&
              onComments != null &&
              tilettes.isNotEmpty)
            alert(const Key('broadcast_comments'), Icons.chat_bubble_outline,
                l10n.commentsTitle, theme.colorScheme.primary,
                onTap: () => onComments!(tilettes.first)),
        ],
      ],
    );
  }
}

/// A Project's board: every task with its assignee, Assign / Reassign.
class _Board extends StatelessWidget {
  final TileShareRosterState state;
  final TileShareRosterCubit roster;
  final List<TileShareTemplate> tilettes;

  final void Function(TileShareTemplate tilette)? onComments;
  final void Function(TileShareTemplate)? onNotes;
  final void Function(TileShareTemplate)? onOpen;
  final ShareWorkFilter filter;
  final ValueChanged<ShareWorkFilter> onFilter;

  const _Board(
      {required this.state,
      required this.roster,
      required this.tilettes,
      this.onComments,
      this.onNotes,
      this.onOpen,
      required this.filter,
      required this.onFilter});

  Future<void> _assign(BuildContext context, int index) async {
    final TileShareTemplate tilette = tilettes[index];
    final List<(RosterRow, RosterCell)> current =
        _assigneesOf(state.rows, index);
    final contact = await showProjectAssignSheet(context,
        projectTaskName(AppLocalizations.of(context)!, tilette), state.rows,
        exclude: {for (final (RosterRow r, RosterCell _) in current) r.key});
    if (contact == null || tilette.id == null) return;
    roster.assignTask(tilette.id!, contact,
        replacingAssignmentId:
            current.isEmpty ? null : current.first.$2.assignmentId);
  }

  @override
  Widget build(BuildContext context) {
    final TaskEditor? editor = TaskEditor.of(context);
    final visible = [
      for (int i = 0; i < tilettes.length; i++)
        if (matchesShareWorkFilter(
            filter,
            _assigneesOf(state.rows, i)
                .map((a) => (a.$2.rsvp, a.$2.completion))))
          i
    ];
    return Column(
      key: const Key('project_board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TasksHeader(
          count: tilettes.length,
          filter: ShareWorkFilterButton(selected: filter, onChanged: onFilter),
          // A new Project task goes to the assignee picked, or to no one.
          onAdd: editor == null
              ? null
              : () => editor.add(context,
                  people: TaskSheetPeople.assignee, projectPeople: state.rows),
        ),
        AnimatedKeyedColumn(children: [
          if (visible.isEmpty && filter != ShareWorkFilter.all)
            Text(AppLocalizations.of(context)!.shareNoMatches,
                key: const Key('share_filter_empty')),
          for (final i in visible)
            KeyedSubtree(
              key: ValueKey<String>('project_card_${tilettes[i].id}'),
              child: ProjectTaskRow(
                tilette: tilettes[i],
                assignees: _assigneesOf(state.rows, i),
                change: state.tasks[tilettes[i].id],
                onAssign: () => _assign(context, i),
                onRetry: () => roster.retryTask(tilettes[i].id ?? ''),
                onComments:
                    onComments == null ? null : () => onComments!(tilettes[i]),
                onNotes: onNotes == null ? null : () => onNotes!(tilettes[i]),
                onOpen: onOpen == null ? null : () => onOpen!(tilettes[i]),
                menu: editor == null
                    ? null
                    : TaskMenu(
                        tilette: tilettes[i],
                        editor: editor,
                        people: TaskSheetPeople.assignee),
              ),
            ),
        ]),
      ],
    );
  }
}

class _Tasks extends StatelessWidget {
  final TileShareRosterState state;
  final List<TileShareTemplate> tilettes;

  final void Function(TileShareTemplate tilette)? onComments;
  final void Function(TileShareTemplate)? onNotes;
  final void Function(TileShareTemplate)? onOpen;
  final ShareWorkFilter filter;
  final ValueChanged<ShareWorkFilter> onFilter;
  final VoidCallback onMissingAssignments;

  const _Tasks(
      {required this.state,
      required this.tilettes,
      this.onComments,
      this.onNotes,
      this.onOpen,
      required this.filter,
      required this.onFilter,
      required this.onMissingAssignments});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final TextStyle? quiet = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final TaskEditor? editor = TaskEditor.of(context);
    final savedRows = state.rows.where((r) => r.assignmentId != null).toList();
    List<RosterCell> cellsAt(int i) => [
          for (final r in savedRows)
            if (i < r.cells.length && r.cells[i].isPresent) r.cells[i],
        ];
    final visible = [
      for (int i = 0; i < tilettes.length; i++)
        if (filter == ShareWorkFilter.attention &&
                cellsAt(i).length < savedRows.length ||
            matchesShareWorkFilter(
                filter, cellsAt(i).map((c) => (c.rsvp, c.completion))))
          i
    ];
    return Column(
      key: const Key('class_tasks'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TasksHeader(
          count: tilettes.length,
          filter: ShareWorkFilterButton(selected: filter, onChanged: onFilter),
          // Everyone in a Class has every task, the new one too.
          onAdd: editor == null
              ? null
              : () => editor.add(context,
                      people: TaskSheetPeople.everyone,
                      everyone: [
                        for (final RosterRow r in state.rows)
                          if (r.assignmentId != null && r.contact != null)
                            r.contact!,
                      ]),
        ),
        AnimatedKeyedColumn(children: [
          if (visible.isEmpty && filter != ShareWorkFilter.all)
            Text(l10n.shareNoMatches, key: const Key('share_filter_empty')),
          for (final i in visible)
            () {
              final cells = cellsAt(i);
              final missing = savedRows.length - cells.length;
              final done = cells
                  .where((c) =>
                      c.rsvp == InvitationStatus.accepted &&
                      (shareCompletion(c.completion) ?? 0) >= 100)
                  .length;
              final int accepted = cells
                  .where((c) => c.rsvp == InvitationStatus.accepted)
                  .length;
              final TileShareTemplate t = tilettes[i];
              return TiletteWorkCard(
                key: Key('class_task_${t.id}'),
                title: t.name ?? '',
                onOpen: onOpen == null ? null : () => onOpen!(t),
                durationMs: t.durationInMs,
                dueMs: t.end,
                menu: editor == null
                    ? null
                    : TaskMenu(
                        tilette: t,
                        editor: editor,
                        people: TaskSheetPeople.everyone),
                status: Text(
                    cells.isEmpty
                        ? l10n.projectUnassigned
                        : l10n.clusterRsvpAccepted(accepted, cells.length),
                    style: quiet),
                compactStatus: Text(
                    cells.isEmpty
                        ? l10n.projectUnassigned
                        : l10n.clusterRsvpAccepted(accepted, cells.length),
                    style: quiet),
                listStatus: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      cells.isEmpty
                          ? l10n.projectUnassigned
                          : l10n.shareCompletionCount(done, cells.length),
                      style: quiet),
                  if (missing > 0)
                    Tooltip(
                        message: l10n.shareMissingAssignments(missing),
                        child: const Icon(Icons.person_add_alt_1_outlined,
                            size: 18, color: TileColors.progressMedium)),
                ]),
                details: missing == 0
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                            key: Key('class_task_missing_${t.id}'),
                            onPressed: onMissingAssignments,
                            icon: const Icon(Icons.person_add_alt_1_outlined,
                                size: 18),
                            label:
                                Text(l10n.shareMissingAssignments(missing)))),
                progress: cells.isEmpty
                    ? null
                    : ShareCompletionBar(
                        value: done / cells.length,
                        label: l10n.shareCompletionCount(done, cells.length)),
                onNotes: onNotes == null ? null : () => onNotes!(t),
                onComments: onComments == null ? null : () => onComments!(t),
                notesKey: Key('class_task_notes_${t.id}'),
                commentsKey: Key('class_task_comments_${t.id}'),
              );
            }(),
        ]),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  final TileShareRosterState state;
  final TileShareRosterCubit roster;
  final RosterMode mode;
  final List<TileShareTemplate> tilettes;

  const _Participants({
    required this.state,
    required this.roster,
    required this.mode,
    required this.tilettes,
  });

  Future<void> _confirmRemove(BuildContext context, RosterRow row) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool ok = await confirmDestructive(
      context,
      title: l10n.participantRemoveTitle(row.label),
      body: switch (mode) {
        RosterMode.classMode => l10n.classRemoveBody,
        RosterMode.project => l10n.projectRemoveBody,
        RosterMode.broadcast => l10n.participantRemoveBody,
      },
      confirmLabel: l10n.participantRemove,
      confirmKey: const Key('participant_remove_confirm'),
    );
    if (ok) roster.remove(row.key);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Column(
      key: const Key('roster_participants'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // People join a Project through a task (Assign on the board).
        if (mode != RosterMode.project)
          KeyedSubtree(
            key: const Key('roster_add_participant'),
            child: ContactInputFieldWidget(
              isReadOnly: false,
              showPills: false,
              startExpanded: true,
              onContactAdded: roster.add,
            ),
          ),
        if (state.duplicate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(l10n.participantAlreadyInvited(state.duplicate!),
                key: const Key('participant_duplicate'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ),
        if (state.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            // A Project has no add field here: people join by being
            // assigned a tilette.
            child: Text(
                mode == RosterMode.project
                    ? l10n.shareProjectNoPeople
                    : l10n.broadcastNoParticipants,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        AnimatedKeyedColumn(children: [
          for (final RosterRow row in state.rows)
            if (mode == RosterMode.project)
              ProjectPersonRow(
                key: ValueKey<String>('participant_${row.key}'),
                row: row,
                tilettes: tilettes,
                onRemove: () => _confirmRemove(context, row),
              )
            else if (mode == RosterMode.classMode)
              ClassPersonRow(
                key: ValueKey<String>('participant_${row.key}'),
                row: row,
                onTap: () => showClassPersonSheet(context, row, tilettes),
                onRepair: () => roster.repair(row.key),
                onRemove: () => _confirmRemove(context, row),
                onRetry: () => roster.retryAdd(row.key),
                onDismiss: () => roster.dismiss(row.key),
              )
            else
              ParticipantRow(
                key: ValueKey<String>('participant_${row.key}'),
                row: row,
                onRemove: row.assignmentId == null
                    ? null
                    : () => _confirmRemove(context, row),
                onRetry: () => roster.retryAdd(row.key),
                onDismiss: () => roster.dismiss(row.key),
              ),
        ]),
      ],
    );
  }
}
