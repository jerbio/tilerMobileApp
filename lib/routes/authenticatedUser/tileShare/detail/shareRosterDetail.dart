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
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/participantRow.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/util.dart';

/// The owner's Broadcast detail (Step 9.13): Overview · Participants.
class BroadcastDetail extends StatelessWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  const BroadcastDetail(
      {super.key, required this.detail, required this.recipients});

  @override
  Widget build(BuildContext context) =>
      ShareRosterDetail(detail: detail, recipients: recipients, isClass: false);
}

/// The owner's Class detail (Step 9.14): Overview · Tasks · Participants.
class ClassDetail extends StatelessWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  const ClassDetail({super.key, required this.detail, required this.recipients});

  @override
  Widget build(BuildContext context) =>
      ShareRosterDetail(detail: detail, recipients: recipients, isClass: true);
}

enum _Segment { overview, tasks, participants }

/// The owner's roster detail (redesign §5.4), under the detail header, for a
/// share where everyone gets their own copy - a **Broadcast** (one task) or a
/// **Class** (every task):
///
/// * **Overview** previews: the answers (people who accepted everything, for a
///   Class), who is missing from some tasks, who may not have got the
///   invitation, the first few people and "View all" - never the whole list.
/// * **Tasks** (Class): each task with its own answers.
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
  final bool isClass;

  /// How many people the Overview previews.
  static const int previewCount = 3;

  const ShareRosterDetail({
    super.key,
    required this.detail,
    required this.recipients,
    required this.isClass,
  });

  @override
  State<ShareRosterDetail> createState() => _ShareRosterDetailState();
}

class _ShareRosterDetailState extends State<ShareRosterDetail> {
  TileShareRosterCubit? _roster;
  _Segment _segment = _Segment.overview;

  List<TileShareTemplate> get _tilettes => widget.isClass
      ? widget.detail.tilettes
      : widget.detail.tilettes.take(1).toList();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final String? clusterId = widget.detail.cluster?.id;
    if (_tilettes.isEmpty || clusterId == null) return;
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
    if (roster == null) return const SizedBox.shrink();
    final List<_Segment> segments = [
      _Segment.overview,
      if (widget.isClass) _Segment.tasks,
      _Segment.participants,
    ];
    String label(_Segment s) => switch (s) {
          _Segment.overview => l10n.overview,
          _Segment.tasks => l10n.detailTasks,
          _Segment.participants => l10n.broadcastParticipants,
        };
    return BlocProvider<TileShareRosterCubit>.value(
      value: roster,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Segment>(
            showSelectedIcon: false,
            segments: [
              for (final _Segment s in segments)
                ButtonSegment<_Segment>(
                  value: s,
                  label: Text(label(s),
                      key: Key('roster_segment_${s.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => _go(s.first),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
              key: ValueKey<_Segment>(_segment),
              builder: (context, state) => switch (_segment) {
                _Segment.overview => _Overview(
                    state: state,
                    isClass: widget.isClass,
                    onParticipants: () => _go(_Segment.participants)),
                _Segment.tasks => _Tasks(state: state, tilettes: _tilettes),
                _Segment.participants => _Participants(
                    state: state,
                    roster: roster,
                    isClass: widget.isClass,
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
Widget _previewRow(RosterRow row, bool isClass) =>
    isClass ? ClassPersonRow(row: row) : ParticipantRow(row: row);

class _Overview extends StatelessWidget {
  final TileShareRosterState state;
  final bool isClass;
  final VoidCallback onParticipants;

  const _Overview(
      {required this.state, required this.isClass, required this.onParticipants});

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
    final int incomplete = saved.where((r) => r.isIncomplete).length;
    final String? answers = saved.isEmpty
        ? null
        : isClass
            ? l10n.clusterRsvpPeople(
                saved.where((r) => r.acceptedAll).length, saved.length)
            : l10n.clusterRsvpAccepted(
                saved.where((r) => r.rsvp == InvitationStatus.accepted).length,
                saved.length);

    Widget alert(Key key, IconData icon, String text, Color color) => InkWell(
          key: key,
          onTap: onParticipants,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color)),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        );

    return Column(
      key: const Key('roster_overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (answers != null) Text(answers, style: theme.textTheme.titleSmall),
        if (isClass && incomplete > 0) ...[
          const SizedBox(height: 8),
          alert(const Key('class_incomplete'), Icons.group_add_outlined,
              l10n.classPeopleIncomplete(incomplete), theme.colorScheme.tertiary),
        ],
        if (issues > 0) ...[
          const SizedBox(height: 8),
          alert(const Key('roster_delivery_issues'),
              Icons.mark_email_unread_outlined,
              l10n.broadcastDeliveryIssues(issues), theme.colorScheme.error),
        ],
        const SizedBox(height: 8),
        for (final RosterRow row in state.rows.take(ShareRosterDetail.previewCount))
          _previewRow(row, isClass),
        if (state.rows.isEmpty)
          Text(l10n.broadcastNoParticipants,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (state.rows.length > ShareRosterDetail.previewCount)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('roster_view_all'),
              onPressed: onParticipants,
              child: Text(l10n.broadcastViewAll(state.rows.length)),
            ),
          ),
      ],
    );
  }
}

class _Tasks extends StatelessWidget {
  final TileShareRosterState state;
  final List<TileShareTemplate> tilettes;

  const _Tasks({required this.state, required this.tilettes});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final TextStyle? quiet = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      key: const Key('class_tasks'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < tilettes.length; i++)
          () {
            final List<RosterCell> cells = <RosterCell>[
              for (final RosterRow r in state.rows)
                if (i < r.cells.length && r.cells[i].isPresent) r.cells[i],
            ];
            final int accepted =
                cells.where((c) => c.rsvp == InvitationStatus.accepted).length;
            final TileShareTemplate t = tilettes[i];
            return Padding(
              key: Key('class_task_${t.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.task_alt,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((t.name ?? '').trim().isEmpty
                            ? l10n.clusterTitleFallback
                            : t.name!.trim()),
                        Text(l10n.clusterRsvpAccepted(accepted, cells.length),
                            style: quiet),
                      ],
                    ),
                  ),
                  if ((t.durationInMs ?? 0) > 0)
                    Text(
                        Duration(milliseconds: t.durationInMs!)
                            .toHumanLocalized(context),
                        style: quiet),
                ],
              ),
            );
          }(),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  final TileShareRosterState state;
  final TileShareRosterCubit roster;
  final bool isClass;
  final List<TileShareTemplate> tilettes;

  const _Participants({
    required this.state,
    required this.roster,
    required this.isClass,
    required this.tilettes,
  });

  Future<void> _confirmRemove(BuildContext context, RosterRow row) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.participantRemoveTitle(row.label)),
        content: Text(
            isClass ? l10n.classRemoveBody : l10n.participantRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          TextButton(
            key: const Key('participant_remove_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.participantRemove),
          ),
        ],
      ),
    );
    if (ok == true) roster.remove(row.key);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Column(
      key: const Key('roster_participants'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            child: Text(l10n.broadcastNoParticipants,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        for (final RosterRow row in state.rows)
          isClass
              ? ClassPersonRow(
                  key: ValueKey<String>('participant_${row.key}'),
                  row: row,
                  onTap: () => showClassPersonSheet(context, row, tilettes),
                  onRepair: () => roster.repair(row.key),
                  onRemove: () => _confirmRemove(context, row),
                  onRetry: () => roster.retryAdd(row.key),
                  onDismiss: () => roster.dismiss(row.key),
                )
              : ParticipantRow(
                  key: ValueKey<String>('participant_${row.key}'),
                  row: row,
                  onRemove: row.assignmentId == null
                      ? null
                      : () => _confirmRemove(context, row),
                  onRetry: () => roster.retryAdd(row.key),
                  onDismiss: () => roster.dismiss(row.key),
                ),
      ],
    );
  }
}
