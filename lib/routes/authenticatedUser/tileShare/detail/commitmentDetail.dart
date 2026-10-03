import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_commitment_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

/// The recipient's detail of a share - the commitment (redesign §5.8), under
/// the detail header (who sent it, the mode, when it is due).
///
/// * **The answer follows the mode (T20):** Accept / Decline for a Broadcast,
///   with **Check fit** for its one task (T21-T23); Accept all / Decline all
///   for a Class (every task I hold, one at a time); Accept / Decline on each
///   of my tasks for a Project - never Accept all, never Check fit.
/// * **My tasks**, each with my answer; once accepted, my progress and a way
///   to the scheduled tile; and the task's comments.
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

  const CommitmentDetail({
    super.key,
    required this.detail,
    required this.assignments,
    this.onAnswered,
    this.onPreview,
    this.onOpenTile,
    this.onComments,
  });

  @override
  State<CommitmentDetail> createState() => _CommitmentDetailState();
}

class _CommitmentDetailState extends State<CommitmentDetail> {
  late final TileShareCommitmentCubit _cubit;

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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final TileShareMode mode = widget.detail.mode ?? TileShareMode.broadcast;
    final List<DesignatedTile> mine = widget.detail.mine;
    return BlocBuilder<TileShareCommitmentCubit, TileShareCommitmentState>(
      bloc: _cubit,
      builder: (context, state) {
        final List<String> pending = state.pending;
        final bool sending = state.sending.isNotEmpty;
        final bool answerAll = mode != TileShareMode.project && pending.isNotEmpty;
        return Column(
          key: const Key('commitment'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (answerAll)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton(
                    key: const Key('commitment_accept'),
                    onPressed: sending
                        ? null
                        : () => _cubit.respond(pending, InvitationStatus.accepted),
                    child: Text(AttentionCopy.acceptLabel(l10n, mode)),
                  ),
                  OutlinedButton(
                    key: const Key('commitment_decline'),
                    onPressed: sending
                        ? null
                        : () => _cubit.respond(pending, InvitationStatus.declined),
                    child: Text(AttentionCopy.declineLabel(l10n, mode)),
                  ),
                  if (mode == TileShareMode.broadcast &&
                      pending.length == 1 &&
                      widget.onPreview != null)
                    TextButton.icon(
                      key: const Key('commitment_check_fit'),
                      onPressed: () => widget.onPreview!(pending.single),
                      icon: const Icon(Icons.calendar_view_day_outlined, size: 18),
                      label: Text(l10n.previewCheckFit),
                    ),
                ],
              ),
            if (state.failure != null) ...[
              const SizedBox(height: 8),
              Row(
                key: const Key('commitment_failure'),
                children: [
                  Expanded(
                    child: Text(
                        state.failure!.total > 1
                            ? l10n.commitmentPartialAnswered(
                                state.failure!.answered, state.failure!.total)
                            : state.failure!.status == InvitationStatus.accepted
                                ? l10n.attentionAcceptFailed
                                : l10n.attentionDeclineFailed,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                  TextButton(
                    key: const Key('commitment_retry'),
                    onPressed: sending ? null : _cubit.retry,
                    child: Text(l10n.attentionRetry),
                  ),
                ],
              ),
            ],
            if (state.scheduleRefreshFailed) ...[
              const SizedBox(height: 8),
              Text(l10n.attentionScheduleRefreshFailed,
                  key: const Key('commitment_refresh_failed'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: TileColors.progressMedium)),
            ],
            const SizedBox(height: 16),
            Text(mine.length > 1 ? l10n.commitmentYourTasks : l10n.commitmentYourTask,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final DesignatedTile tile in mine)
              _TaskRow(
                tile: tile,
                status: state.statuses[tile.id] ?? InvitationStatus.none,
                sending: state.sending.contains(tile.id),
                perTask: mode == TileShareMode.project,
                onRespond: (status) => _cubit.respond([tile.id!], status),
                onOpenTile: widget.onOpenTile,
                onComments: widget.onComments,
              ),
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

  const _TaskRow({
    required this.tile,
    required this.status,
    required this.sending,
    required this.perTask,
    required this.onRespond,
    this.onOpenTile,
    this.onComments,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? quiet =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final String id = tile.id ?? '';
    final String name = (tile.name ?? tile.tileTemplate?.name ?? '').trim();
    final int? duration = tile.tileTemplate?.durationInMs;
    final double? completion = tile.completionPercentage;
    final bool accepted = status == InvitationStatus.accepted;
    return Padding(
      key: Key('commitment_task_$id'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name.isEmpty ? l10n.clusterTitleFallback : name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if ((duration ?? 0) > 0)
                Text(Duration(milliseconds: duration!).toHumanLocalized(context),
                    style: quiet),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
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
                Text('${completion.round()}%', style: quiet),
              if (sending)
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          if (accepted && completion != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (completion / 100).clamp(0.0, 1.0),
                minHeight: 4,
                color: TileColors.acceptedTileShare,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (perTask && status == InvitationStatus.none) ...[
                FilledButton(
                  key: Key('commitment_accept_$id'),
                  onPressed: sending ? null : () => onRespond(InvitationStatus.accepted),
                  child: Text(l10n.attentionAccept),
                ),
                OutlinedButton(
                  key: Key('commitment_decline_$id'),
                  onPressed: sending ? null : () => onRespond(InvitationStatus.declined),
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
              if (onComments != null)
                TextButton.icon(
                  key: Key('commitment_comments_$id'),
                  onPressed: () => onComments!(tile),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l10n.commentsTitle),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
