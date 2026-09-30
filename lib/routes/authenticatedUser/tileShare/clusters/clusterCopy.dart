import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';

/// How close a deadline is.
enum ClusterDueState { later, soon, overdue }

/// The words on a cluster card. Pure functions of the row and the locale, so
/// the wording rules live in one place.
abstract final class ClusterCopy {
  /// Inside this long before its deadline a cluster is marked urgent.
  static const Duration urgentWithin = Duration(hours: 48);

  static String? title(ClusterListItem item) {
    final String name = (item.cluster.name ?? '').trim();
    return name.isEmpty ? null : name;
  }

  /// "Class · From Sarah Kim": the mode, then whose it is.
  static String subtitle(AppLocalizations l10n, ClusterListItem item) {
    final String? mode = TileShareModeBadge.labelOf(l10n, item.mode);
    final String role = _role(l10n, item);
    return mode == null ? role : '$mode · $role';
  }

  static String _role(AppLocalizations l10n, ClusterListItem item) {
    if (item.createdByMe) return l10n.clusterRoleMine;
    final creator = item.cluster.creator;
    final String? name = _firstNonBlank(
        [creator?.fullName, creator?.username, creator?.email]);
    return name == null ? l10n.clusterRoleShared : l10n.clusterRoleFrom(name);
  }

  static String? _firstNonBlank(Iterable<String?> values) {
    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// "3 of 5 accepted" (Broadcast), "... people ..." (Class), "... tasks ..."
  /// (Project); `null` until the counts are known. RSVP status only (T13).
  static String? rsvp(AppLocalizations l10n, ClusterListItem item) {
    final summary = item.rsvp;
    // Nobody counted (no tilettes, or no roster to read) is no line at all.
    if (summary == null || summary.total == 0) return null;
    switch (item.mode) {
      case TileShareMode.broadcast:
        return l10n.clusterRsvpAccepted(summary.accepted, summary.total);
      case TileShareMode.class_:
        return l10n.clusterRsvpPeople(summary.accepted, summary.total);
      case TileShareMode.project:
        return l10n.clusterRsvpTasks(summary.accepted, summary.total);
    }
  }

  /// Still asking for an answer beats what has been answered so far.
  static String mineLabel(AppLocalizations l10n, MyClusterStatus mine) {
    if (mine.needsAnswer) return l10n.clusterMinePending;
    switch (mine.answer) {
      case MyClusterAnswer.accepted:
        return l10n.clusterMineAccepted;
      case MyClusterAnswer.declined:
        return l10n.clusterMineDeclined;
      case MyClusterAnswer.pending:
        return l10n.clusterMinePending;
      case MyClusterAnswer.mixed:
        return l10n.clusterMineMixed;
    }
  }

  static StatusPillTone mineTone(MyClusterStatus mine) {
    if (mine.needsAnswer) return StatusPillTone.primary;
    switch (mine.answer) {
      case MyClusterAnswer.accepted:
        return StatusPillTone.success;
      case MyClusterAnswer.declined:
        return StatusPillTone.danger;
      case MyClusterAnswer.pending:
        return StatusPillTone.primary;
      case MyClusterAnswer.mixed:
        return StatusPillTone.warning;
    }
  }

  /// The deadline chip's state; `null` when there is nothing to show (no
  /// deadline, or the cluster is completed).
  static ClusterDueState? dueState(ClusterListItem item, DateTime now) {
    final int? end = item.cluster.endTimeInMs;
    if (end == null || item.cluster.isCompleted == true) return null;
    final Duration left =
        DateTime.fromMillisecondsSinceEpoch(end).difference(now);
    if (left.isNegative) return ClusterDueState.overdue;
    return left < urgentWithin ? ClusterDueState.soon : ClusterDueState.later;
  }

  static String? dueText(
      AppLocalizations l10n, ClusterListItem item, DateTime now, String locale) {
    final ClusterDueState? state = dueState(item, now);
    if (state == null) return null;
    if (state == ClusterDueState.overdue) return l10n.clusterOverdue;
    final DateTime end =
        DateTime.fromMillisecondsSinceEpoch(item.cluster.endTimeInMs!).toLocal();
    return l10n.attentionMetaDue(DateFormat.MMMd(locale).format(end));
  }

  static String filterLabel(AppLocalizations l10n, ClusterFilter filter) {
    switch (filter) {
      case ClusterFilter.all:
        return l10n.clusterFilterAll;
      case ClusterFilter.sharedWithMe:
        return l10n.clusterFilterShared;
      case ClusterFilter.createdByMe:
        return l10n.clusterFilterCreated;
    }
  }
}
