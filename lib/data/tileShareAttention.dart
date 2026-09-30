import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareMode.dart';

/// Why something needs the user's attention. The declaration order **is** the
/// urgency order used to sort the inbox.
enum AttentionType {
  /// I have been invited and have not answered.
  invitation,

  /// My accepted work no longer fits my schedule.
  atRisk,

  /// (Owner) someone declined.
  declined,

  /// (Owner) an invitation could not be sent, or its outcome is unknown.
  deliveryFailed,

  /// Someone else edited a task in a share I am in.
  changed,

  /// Someone completed a task.
  completed,
}

/// One card of the Attention inbox. There is at most one per
/// (cluster, [type]); [count] says how many underlying things it stands for.
class AttentionItem {
  final AttentionType type;
  final String clusterId;
  final String? clusterTitle;

  /// The cluster's mode when the caller knows it; the Invitations endpoint does
  /// not carry it.
  final TileShareMode? mode;

  /// The number of invitations / events / tiles behind this item.
  final int count;
  final String? actorName;
  final String? inviterName;
  final String? taskTitle;
  final int? deadlineMs;
  final int? occurredAtMs;

  /// Activity events behind the item (newest first) — what a dismissal sends.
  final List<String> eventIds;

  /// Pending assignments behind an [AttentionType.invitation] item.
  final List<String> assignmentIds;

  /// The recipient's own tiles behind an [AttentionType.atRisk] item.
  final List<String> designatedTileIds;

  /// [AttentionType.changed]: the union of changed fields.
  final List<String> changedFields;

  /// [AttentionType.changed]: the latest deadline change, when there was one.
  final DateTime? deadlineBefore;
  final DateTime? deadlineAfter;

  /// [AttentionType.deliveryFailed]: at least one send has an unknown outcome
  /// (it may have been delivered — the owner decides whether to resend).
  final bool hasUnknownOutcome;

  const AttentionItem({
    required this.type,
    required this.clusterId,
    this.clusterTitle,
    this.mode,
    this.count = 1,
    this.actorName,
    this.inviterName,
    this.taskTitle,
    this.deadlineMs,
    this.occurredAtMs,
    this.eventIds = const <String>[],
    this.assignmentIds = const <String>[],
    this.designatedTileIds = const <String>[],
    this.changedFields = const <String>[],
    this.deadlineBefore,
    this.deadlineAfter,
    this.hasUnknownOutcome = false,
  });

  /// Stable across refreshes so the list can animate by key.
  String get id => '${type.name}:$clusterId';
}

/// Derives the Attention inbox (redesign T7) — purely, from what the server
/// already reports. Nothing here reads the network or the clock.
abstract final class AttentionItems {
  static const Set<AttentionType> _deadlineDriven = {
    AttentionType.invitation,
    AttentionType.atRisk,
  };

  static List<AttentionItem> derive({
    required DateTime now,
    String? currentUserId,
    Iterable<TileShareInvitation> invitations = const <TileShareInvitation>[],
    Iterable<TileShareActivity> activity = const <TileShareActivity>[],
    Iterable<DesignatedTile> received = const <DesignatedTile>[],
    Set<String> dismissedEventIds = const <String>{},
    Map<String, TileShareMode> modes = const <String, TileShareMode>{},
    Map<String, String> clusterTitles = const <String, String>{},
  }) {
    final int nowMs = now.millisecondsSinceEpoch;
    final List<AttentionItem> items = <AttentionItem>[
      ..._invitationItems(invitations, nowMs, modes, clusterTitles),
      ..._atRiskItems(received, modes, clusterTitles),
      ..._activityItems(
          activity, currentUserId, dismissedEventIds, modes, clusterTitles),
    ];
    items.sort(_compare);
    return items;
  }

  // ---- invitations -------------------------------------------------------

  static List<AttentionItem> _invitationItems(
    Iterable<TileShareInvitation> invitations,
    int nowMs,
    Map<String, TileShareMode> modes,
    Map<String, String> clusterTitles,
  ) {
    final Map<String, List<TileShareInvitation>> byCluster =
        <String, List<TileShareInvitation>>{};
    for (final TileShareInvitation invitation in invitations) {
      if (invitation.clusterId.isEmpty) continue;
      final int? deadline = invitation.deadlineMs;
      if (deadline != null && deadline < nowMs) continue; // expired
      byCluster
          .putIfAbsent(invitation.clusterId, () => <TileShareInvitation>[])
          .add(invitation);
    }
    return byCluster.entries.map((entry) {
      final List<TileShareInvitation> list = entry.value;
      return AttentionItem(
        type: AttentionType.invitation,
        clusterId: entry.key,
        clusterTitle: _firstNonNull(list.map((i) => i.clusterName)) ??
            clusterTitles[entry.key],
        mode: modes[entry.key],
        count: list.length,
        inviterName: _firstNonNull(list.map((i) => i.inviterName)),
        taskTitle: list.length == 1 ? list.single.name : null,
        deadlineMs: _minOrNull(list.map((i) => i.deadlineMs)),
        assignmentIds: list.map((i) => i.assignmentId).toList(),
      );
    }).toList();
  }

  // ---- at risk -----------------------------------------------------------

  static bool _isAccepted(String? status) {
    if (status == null) return false;
    final String normalized = status.contains('.')
        ? status.substring(status.lastIndexOf('.') + 1)
        : status;
    return DesignatedTile.stringToInvitationStatus(normalized) ==
        InvitationStatus.accepted;
  }

  static List<AttentionItem> _atRiskItems(
    Iterable<DesignatedTile> received,
    Map<String, TileShareMode> modes,
    Map<String, String> clusterTitles,
  ) {
    final Map<String, List<DesignatedTile>> byCluster =
        <String, List<DesignatedTile>>{};
    for (final DesignatedTile tile in received) {
      if (!_isAccepted(tile.invitationStatus)) continue;
      if (tile.isViable != false) continue;
      final String? clusterId = tile.tileTemplate?.clusterId;
      if (clusterId == null || clusterId.isEmpty) continue;
      byCluster.putIfAbsent(clusterId, () => <DesignatedTile>[]).add(tile);
    }
    return byCluster.entries.map((entry) {
      final List<DesignatedTile> tiles = entry.value;
      return AttentionItem(
        type: AttentionType.atRisk,
        clusterId: entry.key,
        clusterTitle: clusterTitles[entry.key],
        mode: modes[entry.key],
        count: tiles.length,
        taskTitle: tiles.length == 1 ? tiles.single.name : null,
        deadlineMs: _minOrNull(
            tiles.map((t) => t.endTime?.millisecondsSinceEpoch)),
        designatedTileIds:
            tiles.map((t) => t.id).whereType<String>().toList(),
      );
    }).toList();
  }

  // ---- activity ----------------------------------------------------------

  static AttentionType? _typeOfEvent(TileShareActivity event) {
    switch (event.eventType) {
      case 'tilette_edited':
        return AttentionType.changed;
      case 'assignment_completed':
        return AttentionType.completed;
      case 'assignment_declined':
        return AttentionType.declined;
      case 'invitation_send_failed':
      case 'invitation_send_unknown':
        return AttentionType.deliveryFailed;
    }
    return null;
  }

  static List<AttentionItem> _activityItems(
    Iterable<TileShareActivity> activity,
    String? currentUserId,
    Set<String> dismissed,
    Map<String, TileShareMode> modes,
    Map<String, String> clusterTitles,
  ) {
    final Map<String, List<TileShareActivity>> groups =
        <String, List<TileShareActivity>>{};
    final Map<String, AttentionType> groupType = <String, AttentionType>{};
    for (final TileShareActivity event in activity) {
      if (!event.isKnown || dismissed.contains(event.eventId)) continue;
      final AttentionType? type = _typeOfEvent(event);
      if (type == null) continue;
      // What I did myself never needs my attention — except a delivery
      // problem, which is always the owner's own action.
      final bool mine = currentUserId != null && event.actorId == currentUserId;
      if (mine && type != AttentionType.deliveryFailed) continue;
      final String key = '${type.name}:${event.clusterId}';
      groups.putIfAbsent(key, () => <TileShareActivity>[]).add(event);
      groupType[key] = type;
    }

    return groups.entries.map((entry) {
      final List<TileShareActivity> events = List<TileShareActivity>.of(entry.value)
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      final TileShareActivity newest = events.first;
      final AttentionType type = groupType[entry.key]!;

      final List<String> fields = <String>[];
      DateTime? before, after;
      for (final TileShareActivity event in events) {
        for (final String field in event.changedFields) {
          if (!fields.contains(field)) fields.add(field);
        }
        if (before == null &&
            after == null &&
            event.deadlineBefore != null &&
            event.deadlineAfter != null) {
          before = event.deadlineBefore;
          after = event.deadlineAfter;
        }
      }

      return AttentionItem(
        type: type,
        clusterId: newest.clusterId,
        clusterTitle: _firstNonNull(events.map((e) => e.clusterTitle)) ??
            clusterTitles[newest.clusterId],
        mode: modes[newest.clusterId],
        count: events.length,
        actorName: newest.actorName,
        taskTitle: newest.tiletteTitle,
        occurredAtMs: newest.occurredAt.millisecondsSinceEpoch,
        eventIds: events.map((e) => e.eventId).toList(),
        changedFields: fields,
        deadlineBefore: before,
        deadlineAfter: after,
        hasUnknownOutcome: type == AttentionType.deliveryFailed &&
            events.any((e) => e.eventType == 'invitation_send_unknown'),
      );
    }).toList();
  }

  // ---- helpers -----------------------------------------------------------

  static String? _firstNonNull(Iterable<String?> values) {
    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static int? _minOrNull(Iterable<int?> values) {
    int? min;
    for (final int? value in values) {
      if (value != null && (min == null || value < min)) min = value;
    }
    return min;
  }

  /// Urgency (enum order), then earliest deadline (deadline-driven types, no
  /// deadline last) or newest event (event-driven types), then id.
  static int _compare(AttentionItem a, AttentionItem b) {
    final int rank = a.type.index.compareTo(b.type.index);
    if (rank != 0) return rank;
    if (_deadlineDriven.contains(a.type)) {
      final int? da = a.deadlineMs, db = b.deadlineMs;
      if (da != db) {
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      }
    } else {
      final int? oa = a.occurredAtMs, ob = b.occurredAtMs;
      if (oa != ob) {
        if (oa == null) return 1;
        if (ob == null) return -1;
        return ob.compareTo(oa);
      }
    }
    return a.id.compareTo(b.id);
  }
}
