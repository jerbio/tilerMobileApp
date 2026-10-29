import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_commitment_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'tiletteWorkCard.dart';
import 'shareWorkWidgets.dart';
import 'shareDisplayOptions.dart';

/// The recipient's detail of a share - the commitment (redesign §5.8), under
/// the detail header (who sent it, the mode, when it is due).
///
/// * **The answer follows the mode (T20):** Accept / Decline for a Broadcast,
///   with **Check fit** for its one task; Accept all / Decline all
///   for a Class (every task I hold, one at a time); Accept / Decline on each
///   of my tasks for a Project. Check fit previews one pending assignment.
/// * **My tasks**, each with its notes (rendered, three lines at most), my
///   answer; once accepted, my progress and a way to the scheduled tile; and
///   the task's comments.
/// * A refused answer says so with Retry (a partial one says how many went
///   through); a schedule that cannot refresh yet is said separately and
///   never undoes the answer.
class CommitmentDetail extends StatefulWidget {
  final TileShareDetailState detail;
  final TileShareAssignmentsSource assignments;

  /// Called after answers went out, so the share reloads.
  final VoidCallback? onAnswered;

  /// Check fit: the accept preview of one assignment; none without it.
  final void Function(String assignmentId)? onPreview;

  /// Opens the scheduled tile of an accepted task.
  final void Function(DesignatedTile tile)? onOpenTile;

  /// Opens a task's comments.
  final void Function(DesignatedTile tile)? onComments;
  final void Function(DesignatedTile tile)? onNotes;
  final void Function(DesignatedTile tile)? onOpenTilette;
  final WidgetBuilder? activityBuilder;

  const CommitmentDetail({
    super.key,
    required this.detail,
    required this.assignments,
    this.onAnswered,
    this.onPreview,
    this.onOpenTile,
    this.onComments,
    this.onNotes,
    this.onOpenTilette,
    this.activityBuilder,
  });

  @override
  State<CommitmentDetail> createState() => _CommitmentDetailState();
}

class _CommitmentDetailState extends State<CommitmentDetail> {
  late final TileShareCommitmentCubit _cubit;
  int _section = 0;
  ShareWorkFilter _filter = ShareWorkFilter.all;

  @override
  void initState() {
    super.initState();
    _cubit = TileShareCommitmentCubit(
      assignments: widget.assignments,
      mine: widget.detail.mine,
      onAnswered: widget.onAnswered,
    );
  }

  @override
  void didUpdateWidget(covariant CommitmentDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.detail.mine, widget.detail.mine)) {
      _cubit.sync(widget.detail.mine);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Widget _responsePanel(BuildContext context, Widget actions) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('commitment_invitation_panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(AppLocalizations.of(context)!.shareYourResponse,
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        actions,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final TileShareMode mode = widget.detail.mode ?? TileShareMode.broadcast;
    final List<DesignatedTile> mine = widget.detail.mine;
    final comfortable =
        TileShareDisplayScope.densityOf(context) == TiletteDensity.comfortable;
    return BlocBuilder<TileShareCommitmentCubit, TileShareCommitmentState>(
      bloc: _cubit,
      builder: (context, state) {
        final List<String> pending = state.pending;
        final bool sending = state.sending.isNotEmpty;
        final bool answerAll =
            mode != TileShareMode.project && pending.isNotEmpty;
        final accepted = mine
            .where((t) => state.statuses[t.id] == InvitationStatus.accepted)
            .toList();
        final complete = accepted
            .where((t) => (shareCompletion(t.completionPercentage) ?? 0) >= 100)
            .length;
        final active = accepted
            .where((t) =>
                (shareCompletion(t.completionPercentage) ?? 0) > 0 &&
                (shareCompletion(t.completionPercentage) ?? 0) < 100)
            .length;
        final visibleMine = mine
            .where((t) => matchesShareWorkFilter(
                _filter, [(state.statuses[t.id], t.completionPercentage)]))
            .toList();
        Widget task(DesignatedTile tile) => _TaskRow(
            key: ValueKey<String>('commitment_row_${tile.id}'),
            tile: tile,
            status: state.statuses[tile.id] ?? InvitationStatus.none,
            sending: state.sending.contains(tile.id),
            perTask: mode == TileShareMode.project,
            onRespond: (status) => _cubit.respond([tile.id!], status),
            onOpenTile: widget.onOpenTile,
            onComments: widget.onComments,
            onNotes: widget.onNotes,
            onPreview:
                mode == TileShareMode.broadcast ? null : widget.onPreview,
            onOpenTilette: widget.onOpenTilette);
        return Column(
          key: const Key('commitment'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mode != TileShareMode.broadcast) ...[
              ShareWorkSummary(
                  key: const Key('commitment_work_summary'),
                  progress: mode == TileShareMode.class_
                      ? ShareCompletionBar(
                          value: mine.isEmpty ? 0 : complete / mine.length,
                          label:
                              l10n.shareCompletionCount(complete, mine.length))
                      : null,
                  stats: [
                    (
                      Icons.schedule,
                      pending.length,
                      l10n.shareNeedsDecision,
                      TileColors.progressMedium
                    ),
                    (
                      Icons.timelapse,
                      active,
                      l10n.shareInProgress,
                      TileColors.responseTileShare
                    ),
                    if (mode == TileShareMode.project)
                      (
                        Icons.check_circle_outline,
                        complete,
                        l10n.completed,
                        TileColors.acceptedTileShare
                      ),
                    if (accepted.length > complete + active)
                      (
                        Icons.check,
                        accepted.length - complete - active,
                        l10n.accepted,
                        theme.colorScheme.onSurfaceVariant
                      ),
                  ]),
              SizedBox(height: comfortable ? 20 : 8),
              ShareDetailTabs<int>(
                  tabs: [
                    (0, l10n.shareMyWork, null),
                    (
                      1,
                      mode == TileShareMode.class_
                          ? l10n.tileShareModeClass
                          : l10n.tileShareModeProject,
                      null
                    ),
                    if (widget.activityBuilder != null)
                      (2, l10n.shareActivity, null),
                  ],
                  selected: _section,
                  onChanged: (s) => setState(() => _section = s)),
              SizedBox(height: comfortable ? 20 : 8),
            ],
            if (_section == 2) widget.activityBuilder!(context),
            if (_section == 1) ...[
              Text(
                  mode == TileShareMode.class_
                      ? l10n.shareClassHint
                      : l10n.shareProjectHint,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              for (final t in widget.detail.tilettes)
                TiletteWorkCard(
                    title: t.name ?? '',
                    durationMs: t.durationInMs,
                    dueMs: t.end),
            ],
            if (_section == 0) ...[
              // The answers, a refusal and a late schedule come and go; they
              // grow in and shrink out so the tasks below slide (T11).
              RevealSlot(
                child: answerAll
                    ? _responsePanel(
                        context,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton(
                              key: const Key('commitment_accept'),
                              onPressed: sending
                                  ? null
                                  : () => _cubit.respond(
                                      pending, InvitationStatus.accepted),
                              child:
                                  Text(AttentionCopy.acceptLabel(l10n, mode)),
                            ),
                            OutlinedButton(
                              key: const Key('commitment_decline'),
                              onPressed: sending
                                  ? null
                                  : () => _cubit.respond(
                                      pending, InvitationStatus.declined),
                              child:
                                  Text(AttentionCopy.declineLabel(l10n, mode)),
                            ),
                            if (mode == TileShareMode.broadcast &&
                                pending.length == 1 &&
                                widget.onPreview != null)
                              TextButton.icon(
                                key: const Key('commitment_check_fit'),
                                onPressed: () =>
                                    widget.onPreview!(pending.single),
                                icon: const Icon(
                                    Icons.calendar_view_day_outlined,
                                    size: 18),
                                label: Text(l10n.previewCheckFit),
                              ),
                          ],
                        ))
                    : null,
              ),
              RevealSlot(
                child: state.failure != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          key: const Key('commitment_failure'),
                          children: [
                            Expanded(
                              child: Text(
                                  state.failure!.total > 1
                                      ? l10n.commitmentPartialAnswered(
                                          state.failure!.answered,
                                          state.failure!.total)
                                      : state.failure!.status ==
                                              InvitationStatus.accepted
                                          ? l10n.attentionAcceptFailed
                                          : l10n.attentionDeclineFailed,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error)),
                            ),
                            TextButton(
                              key: const Key('commitment_retry'),
                              onPressed: sending ? null : _cubit.retry,
                              child: Text(l10n.attentionRetry),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              RevealSlot(
                child: state.scheduleRefreshFailed
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.attentionScheduleRefreshFailed,
                            key: const Key('commitment_refresh_failed'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: TileColors.progressMedium)),
                      )
                    : null,
              ),
              SizedBox(height: comfortable ? 16 : 4),
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                        '${mine.length > 1 ? l10n.commitmentYourTasks : l10n.commitmentYourTask}${comfortable ? '' : ' (${mine.length})'}',
                        style: theme.textTheme.titleSmall),
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const ShareViewOptionsButton(),
                          if (mode != TileShareMode.broadcast)
                            ShareWorkFilterButton(
                                selected: _filter,
                                onChanged: (filter) =>
                                    setState(() => _filter = filter)),
                        ]),
                  ]),
              const SizedBox(height: 4),
              AnimatedKeyedColumn(children: [
                if (visibleMine.isEmpty && mine.isNotEmpty)
                  Text(l10n.shareNoMatches,
                      key: const Key('share_filter_empty')),
                if (mine.isEmpty)
                  Padding(
                      key: const Key('commitment_empty'),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(l10n.shareNoAssignments)),
                if (mode == TileShareMode.project) ...[
                  if (visibleMine.any(
                      (t) => state.statuses[t.id] == InvitationStatus.none))
                    Padding(
                        key: const Key('commitment_decisions'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(l10n.shareNeedsDecision,
                            style: theme.textTheme.titleMedium)),
                  for (final tile in visibleMine.where(
                      (t) => state.statuses[t.id] == InvitationStatus.none))
                    task(tile),
                  if (visibleMine.any(
                      (t) => state.statuses[t.id] == InvitationStatus.accepted))
                    Padding(
                        key: const Key('commitment_commitments'),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(l10n.shareCommitments,
                            style: theme.textTheme.titleMedium)),
                  for (final tile in visibleMine.where(
                      (t) => state.statuses[t.id] == InvitationStatus.accepted))
                    task(tile),
                  for (final tile in visibleMine.where(
                      (t) => state.statuses[t.id] == InvitationStatus.declined))
                    task(tile),
                ] else
                  for (final tile in visibleMine) task(tile),
              ]),
            ],
          ],
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DesignatedTile tile;
  final InvitationStatus status;
  final bool sending;
  final bool perTask;
  final void Function(InvitationStatus status) onRespond;
  final void Function(DesignatedTile tile)? onOpenTile;
  final void Function(DesignatedTile tile)? onComments;
  final void Function(DesignatedTile tile)? onNotes;
  final void Function(DesignatedTile tile)? onOpenTilette;
  final void Function(String assignmentId)? onPreview;

  const _TaskRow({
    super.key,
    required this.tile,
    required this.status,
    required this.sending,
    required this.perTask,
    required this.onRespond,
    this.onOpenTile,
    this.onComments,
    this.onNotes,
    this.onOpenTilette,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String id = tile.id ?? '';
    final String name = (tile.name ?? tile.tileTemplate?.name ?? '').trim();
    final int? duration = tile.tileTemplate?.durationInMs;
    final double? completion = shareCompletion(tile.completionPercentage);
    final String notes = (tile.tileTemplate?.miscData?.userNote ?? '').trim();
    final bool accepted = status == InvitationStatus.accepted;
    return TiletteWorkCard(
      key: Key('commitment_task_$id'),
      title: name,
      onOpen: onOpenTilette == null ? null : () => onOpenTilette!(tile),
      durationMs: duration,
      dueMs: tile.endTime?.millisecondsSinceEpoch,
      preview: notes.isNotEmpty
          ? MarkdownNoteView(markdown: notes, maxLines: 3)
          : null,
      compactStatus: ShareWorkStatus(response: status, completion: completion),
      listStatus: ShareWorkStatus(response: status, completion: completion),
      status: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          switch (status) {
            InvitationStatus.accepted => TileShareStatusPill(
                label: l10n.accepted, tone: StatusPillTone.success),
            InvitationStatus.declined => TileShareStatusPill(
                label: l10n.declined, tone: StatusPillTone.danger),
            InvitationStatus.none => TileShareStatusPill(
                label: l10n.participantInvited, tone: StatusPillTone.warning),
          },
          if (accepted && completion != null)
            ShareWorkStatus(response: status, completion: completion),
          if (sending)
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
      progress: accepted && completion != null
          ? ShareCompletionBar(
              value: completion / 100, label: '${completion.round()}%')
          : null,
      onNotes: onNotes == null ? null : () => onNotes!(tile),
      onComments: onComments == null ? null : () => onComments!(tile),
      notesKey: Key('commitment_notes_$id'),
      commentsKey: Key('commitment_comments_$id'),
      actions: [
        if (status == InvitationStatus.none &&
            id.isNotEmpty &&
            onPreview != null)
          TextButton.icon(
              key: Key('commitment_check_fit_$id'),
              onPressed: sending ? null : () => onPreview!(id),
              icon: const Icon(Icons.calendar_view_day_outlined, size: 18),
              label: Text(l10n.previewCheckFit)),
        if (status == InvitationStatus.none && onOpenTilette != null)
          FilledButton.icon(
              key: Key('commitment_review_$id'),
              onPressed: sending ? null : () => onOpenTilette!(tile),
              icon: const Icon(Icons.chevron_right),
              label: Text(l10n.shareReviewRequest)),
        if (perTask &&
            status == InvitationStatus.none &&
            onOpenTilette == null) ...[
          FilledButton(
            key: Key('commitment_accept_$id'),
            onPressed:
                sending ? null : () => onRespond(InvitationStatus.accepted),
            child: Text(l10n.attentionAccept),
          ),
          OutlinedButton(
            key: Key('commitment_decline_$id'),
            onPressed:
                sending ? null : () => onRespond(InvitationStatus.declined),
            child: Text(l10n.attentionDecline),
          ),
        ],
        if (accepted && onOpenTile != null)
          TextButton.icon(
            key: Key('commitment_open_$id'),
            onPressed: () => onOpenTile!(tile),
            icon: const Icon(Icons.style_outlined, size: 18),
            label: Text(l10n.commitmentOpenTile),
          ),
      ],
    );
  }
}
