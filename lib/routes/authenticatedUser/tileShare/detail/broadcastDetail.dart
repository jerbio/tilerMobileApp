import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/participantRow.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

enum _Segment { overview, participants }

/// The owner's Broadcast detail (redesign §5.4), under the detail header:
/// **Overview** - the answers, who may not have got the invitation, the first
/// few people and "View all" (it previews, it never repeats the list) - and
/// **Participants** - the roster with adding and removing.
///
/// Owns the roster cubit for the share's one tilette, reads delivery once, and
/// follows the detail's reloads (a new roster from the server is synced, adds
/// not yet answered are kept).
class BroadcastDetail extends StatefulWidget {
  final TileShareDetailState detail;
  final TileShareRecipientsSource recipients;

  /// How many people the Overview previews.
  static const int previewCount = 3;

  const BroadcastDetail(
      {super.key, required this.detail, required this.recipients});

  @override
  State<BroadcastDetail> createState() => _BroadcastDetailState();
}

class _BroadcastDetailState extends State<BroadcastDetail> {
  TileShareRosterCubit? _roster;
  _Segment _segment = _Segment.overview;

  TileShareTemplate? get _tilette =>
      widget.detail.tilettes.isEmpty ? null : widget.detail.tilettes.first;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final TileShareTemplate? tilette = _tilette;
    final String? clusterId = widget.detail.cluster?.id;
    if (tilette?.id == null || clusterId == null) return;
    _roster = TileShareRosterCubit(
      source: widget.recipients,
      clusterId: clusterId,
      tiletteId: tilette!.id!,
      recipients: tilette.designatedUsers ?? const <DesignatedUser>[],
    )..loadDelivery();
  }

  @override
  void didUpdateWidget(covariant BroadcastDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_roster == null) {
      _start();
      return;
    }
    if (!identical(oldWidget.detail.tilettes, widget.detail.tilettes)) {
      _roster!.sync(_tilette?.designatedUsers ?? const <DesignatedUser>[]);
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
    return BlocProvider<TileShareRosterCubit>.value(
      value: roster,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Segment>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<_Segment>(
                value: _Segment.overview,
                label: Text(l10n.overview,
                    key: const Key('broadcast_segment_overview')),
              ),
              ButtonSegment<_Segment>(
                value: _Segment.participants,
                label: Text(l10n.broadcastParticipants,
                    key: const Key('broadcast_segment_participants')),
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
              builder: (context, state) => _segment == _Segment.overview
                  ? _Overview(
                      state: state,
                      onViewAll: () => _go(_Segment.participants))
                  : _Participants(state: state, roster: roster),
            ),
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final TileShareRosterState state;
  final VoidCallback onViewAll;

  const _Overview({required this.state, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final List<RosterRow> saved =
        state.rows.where((r) => r.assignmentId != null).toList();
    final int accepted =
        saved.where((r) => r.rsvp == InvitationStatus.accepted).length;
    final int issues = saved
        .where((r) =>
            r.delivery == RecipientDelivery.failed ||
            r.delivery == RecipientDelivery.unknown)
        .length;
    return Column(
      key: const Key('broadcast_overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saved.isNotEmpty)
          Text(l10n.clusterRsvpAccepted(accepted, saved.length),
              style: theme.textTheme.titleSmall),
        if (issues > 0) ...[
          const SizedBox(height: 8),
          InkWell(
            key: const Key('broadcast_delivery_issues'),
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.broadcastDeliveryIssues(issues),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.error),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (final RosterRow row in state.rows.take(BroadcastDetail.previewCount))
          ParticipantRow(row: row),
        if (state.rows.isEmpty)
          Text(l10n.broadcastNoParticipants,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (state.rows.length > BroadcastDetail.previewCount)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('broadcast_view_all'),
              onPressed: onViewAll,
              child: Text(l10n.broadcastViewAll(state.rows.length)),
            ),
          ),
      ],
    );
  }
}

class _Participants extends StatelessWidget {
  final TileShareRosterState state;
  final TileShareRosterCubit roster;

  const _Participants({required this.state, required this.roster});

  Future<void> _confirmRemove(BuildContext context, RosterRow row) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.participantRemoveTitle(row.label)),
        content: Text(l10n.participantRemoveBody),
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
    if (ok == true && row.assignmentId != null) {
      roster.remove(row.assignmentId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Column(
      key: const Key('broadcast_participants'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const Key('broadcast_add_participant'),
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
          ParticipantRow(
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
