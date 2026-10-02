import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clusterCopy.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';
import 'package:tiler_app/theme/tile_colors.dart';

enum _ClusterAction { delete }

/// One card of the Clusters list (redesign §5.3): the mode, the cluster, whose
/// it is and when it is due — then what matters to the viewer.
///
/// * **Owner** (created by me): who it went to, and the RSVP line — "3 of 5
///   accepted" — counted by the cubit; a Project also draws one segment per
///   task. It is status, never progress (T13). Has a Delete menu.
/// * **Recipient** (shared with me): my status and, for a Class or Project, how
///   many tasks I hold. While a Broadcast or Class invitation waits it offers
///   Accept / Decline inline ("Accept all" for a Class); a Project says how many
///   tasks need a response and is reviewed task by task instead (T20).
class ClusterCard extends StatelessWidget {
  static const int _maxAvatars = 4;
  static const int _maxSegments = 24;

  final ClusterListItem item;

  /// "Now" for the deadline chip; the clock unless a test says otherwise.
  final DateTime? now;
  final VoidCallback? onOpen;

  /// Owner only: the menu's Delete. The confirmation belongs to the caller.
  final VoidCallback? onDelete;

  /// Recipient only: answer a pending Broadcast / Class invitation inline.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Owner only: try counting the responses again after a failure.
  final VoidCallback? onRetryRsvp;

  /// Recipient only: open the accept preview (T21-T23) of a pending Broadcast
  /// task. A Class or a Project is never previewed from here.
  final VoidCallback? onCheckFit;

  const ClusterCard({
    super.key,
    required this.item,
    this.now,
    this.onOpen,
    this.onDelete,
    this.onAccept,
    this.onDecline,
    this.onRetryRsvp,
    this.onCheckFit,
  });

  bool get _inlineAnswers =>
      !item.createdByMe &&
      item.mine?.needsAnswer == true &&
      onAccept != null &&
      onDecline != null &&
      (item.mode == TileShareMode.broadcast ||
          item.mode == TileShareMode.class_);

  bool get _checkFit =>
      !item.createdByMe &&
      onCheckFit != null &&
      item.mode == TileShareMode.broadcast &&
      item.mine?.pendingAssignmentIds.length == 1;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).toString();
    final String id = item.id;

    final String title = ClusterCopy.title(item) ?? l10n.clusterTitleFallback;
    final String? due =
        ClusterCopy.dueText(l10n, item, now ?? DateTime.now(), locale);
    final ClusterDueState? dueState =
        ClusterCopy.dueState(item, now ?? DateTime.now());
    final bool urgent =
        dueState == ClusterDueState.soon || dueState == ClusterDueState.overdue;
    final mine = item.mine;
    final bool showTaskCount =
        mine != null && mine.taskCount > 0 && item.mode != TileShareMode.broadcast;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TileShareModeBadge(mode: item.mode),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (item.createdByMe && onDelete != null)
                              PopupMenuButton<_ClusterAction>(
                                key: Key('cluster_menu_$id'),
                                tooltip: l10n.clusterMenuTooltip,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_horiz, size: 20),
                                // Keeps the title row as tall as the title, so
                                // an owner card reads like a recipient card.
                                style: const ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onSelected: (_) => onDelete!(),
                                itemBuilder: (context) => [
                                  PopupMenuItem<_ClusterAction>(
                                    value: _ClusterAction.delete,
                                    child: Text(l10n.clusterDelete),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(width: 8),
                          ],
                        ),
                        Text(
                          ClusterCopy.subtitle(l10n, item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (due != null || mine != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (mine != null)
                                KeyedSubtree(
                                  key: Key('cluster_mine_$id'),
                                  child: TileShareStatusPill(
                                    label: ClusterCopy.mineLabel(l10n, mine),
                                    tone: ClusterCopy.mineTone(mine),
                                  ),
                                ),
                              if (showTaskCount)
                                Text(
                                  l10n.attentionMetaTasks(mine.taskCount),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
                              if (due != null)
                                _DueChip(
                                  key: Key(urgent
                                      ? 'cluster_due_urgent_$id'
                                      : 'cluster_due_$id'),
                                  text: due,
                                  urgent: urgent,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ..._owner(context, l10n),
              ..._recipient(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ---- owner -----------------------------------------------------------------

  List<Widget> _owner(BuildContext context, AppLocalizations l10n) {
    if (!item.createdByMe) return const <Widget>[];
    final ThemeData theme = Theme.of(context);
    final String? rsvp = ClusterCopy.rsvp(l10n, item);
    final List<Contact> contacts = item.cluster.contacts ?? const <Contact>[];
    final bool hasAvatars = contacts.isNotEmpty;
    if (!hasAvatars && rsvp == null && !item.rsvpFailed) {
      return const <Widget>[];
    }
    final String id = item.id;

    return [
      const SizedBox(height: 12),
      Row(
        children: [
          if (hasAvatars)
            _AvatarStack(
              key: Key('cluster_avatars_$id'),
              contacts: contacts,
              moreKnown: item.cluster.isMoreContact == true,
              max: _maxAvatars,
            ),
          if (hasAvatars && (rsvp != null || item.rsvpFailed))
            const SizedBox(width: 12),
          if (rsvp != null)
            Expanded(
              child: Text(rsvp,
                  key: Key('cluster_rsvp_$id'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            )
          else if (item.rsvpFailed)
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(l10n.clusterRsvpUnavailable,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  TextButton(
                    onPressed: onRetryRsvp,
                    child: Text(l10n.attentionRetry),
                  ),
                ],
              ),
            ),
        ],
      ),
      if (item.mode == TileShareMode.project &&
          (item.rsvp?.total ?? 0) > 0) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _Segments(
            key: Key('cluster_segments_$id'),
            accepted: item.rsvp!.accepted,
            pending: item.rsvp!.pending,
            declined: item.rsvp!.declined,
            max: _maxSegments,
          ),
        ),
      ],
    ];
  }

  // ---- recipient ---------------------------------------------------------------

  List<Widget> _recipient(BuildContext context, AppLocalizations l10n) {
    final mine = item.mine;
    if (item.createdByMe || mine == null || !mine.needsAnswer) {
      return const <Widget>[];
    }
    final ThemeData theme = Theme.of(context);
    final String id = item.id;

    if (item.mode == TileShareMode.project) {
      return [
        const SizedBox(height: 10),
        Text(l10n.clusterProjectNeedsAnswer(mine.pending),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ];
    }
    if (!_inlineAnswers && !_checkFit) return const <Widget>[];
    return [
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_inlineAnswers) ...[
            FilledButton(
              key: Key('cluster_accept_$id'),
              onPressed: onAccept,
              child: Text(AttentionCopy.acceptLabel(l10n, item.mode)),
            ),
            OutlinedButton(
              key: Key('cluster_decline_$id'),
              onPressed: onDecline,
              child: Text(AttentionCopy.declineLabel(l10n, item.mode)),
            ),
          ],
          if (_checkFit)
            TextButton.icon(
              key: Key('cluster_check_fit_$id'),
              onPressed: onCheckFit,
              icon: const Icon(Icons.calendar_view_day_outlined, size: 18),
              label: Text(l10n.previewCheckFit),
            ),
        ],
      ),
    ];
  }
}

// ---- pieces ---------------------------------------------------------------------

class _DueChip extends StatelessWidget {
  final String text;
  final bool urgent;

  const _DueChip({super.key, required this.text, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tone = urgent ? scheme.error : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (urgent ? scheme.error : scheme.outline).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: tone),
          const SizedBox(width: 4),
          Text(text,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: urgent ? scheme.error : scheme.onSurface,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Overlapping initials of who it went to, with "+N" for the rest.
class _AvatarStack extends StatelessWidget {
  static const double _size = 26;
  static const double _step = 18;

  final List<Contact> contacts;
  final bool moreKnown;
  final int max;

  const _AvatarStack({
    super.key,
    required this.contacts,
    required this.moreKnown,
    required this.max,
  });

  static String _initial(Contact contact) {
    final String? email = contact.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<Contact> shown = contacts.take(max).toList();
    final int extra = contacts.length - shown.length;
    final String? more = extra > 0 ? '+$extra' : (moreKnown ? '…' : null);

    Widget circle(Widget child, Color fill, Color text) => Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surfaceContainerLow, width: 2),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelSmall!
                .copyWith(color: text, fontWeight: FontWeight.w700),
            child: child,
          ),
        );

    final List<Widget> circles = [
      for (final Contact contact in shown)
        circle(Text(_initial(contact)), scheme.secondaryContainer,
            scheme.onSecondaryContainer),
      if (more != null)
        circle(Text(more), scheme.surfaceContainerHighest, scheme.onSurface),
    ];
    return SizedBox(
      width: _size + _step * (circles.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (int i = 0; i < circles.length; i++)
            Positioned(left: i * _step, child: circles[i]),
        ],
      ),
    );
  }
}

/// One segment per task, in the order accepted, still pending, declined.
class _Segments extends StatelessWidget {
  final int accepted;
  final int pending;
  final int declined;
  final int max;

  const _Segments({
    super.key,
    required this.accepted,
    required this.pending,
    required this.declined,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> colors = [
      for (int i = 0; i < accepted; i++) TileColors.acceptedTileShare,
      for (int i = 0; i < pending; i++) scheme.outlineVariant,
      for (int i = 0; i < declined; i++) scheme.error,
    ];
    final List<Color> shown = colors.take(max).toList();
    return Row(
      children: [
        for (int i = 0; i < shown.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == shown.length - 1 ? 0 : 3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shown[i],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox(height: 6),
              ),
            ),
          ),
      ],
    );
  }
}
