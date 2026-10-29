import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

/// Where the signed-in user stands in one cluster shared with them.
enum MyClusterAnswer {
  /// Nothing answered yet.
  pending,

  /// Every task accepted.
  accepted,

  /// Every task declined.
  declined,

  /// Some answered, some not — or accepted on some and declined on others.
  mixed,
}

/// What the signed-in user has answered in one cluster shared with them: the
/// "my status + my task count" of a recipient card (redesign §5.3). Counted
/// over the user's own assignments (one per task they hold); it says nothing
/// about completion or anyone else's answer.
class MyClusterStatus extends Equatable {
  final int taskCount;
  final int accepted;
  final int declined;
  final int pending;

  /// The ids of the assignments still to answer, in the order read (a single
  /// one can be previewed before it is answered).
  final List<String> pendingAssignmentIds;

  const MyClusterStatus({
    required this.taskCount,
    required this.accepted,
    required this.declined,
    required this.pending,
    this.pendingAssignmentIds = const <String>[],
  });

  /// At least one task still waits for an answer.
  bool get needsAnswer => pending > 0;

  MyClusterAnswer get answer {
    if (accepted == taskCount) return MyClusterAnswer.accepted;
    if (declined == taskCount) return MyClusterAnswer.declined;
    if (pending == taskCount) return MyClusterAnswer.pending;
    return MyClusterAnswer.mixed;
  }

  @override
  List<Object?> get props =>
      [taskCount, accepted, declined, pending, pendingAssignmentIds];

  /// One status per cluster the [tiles] belong to, counting only the
  /// designated tile templates whose designated user
  /// ([DesignatedTile.designatedUserId]) is [userId], the signed-in user. The
  /// list can hold templates designated to someone else; previewing or
  /// answering one of those is a request for an id that is not the user's
  /// (the server answers 404). A template whose designated user is not known,
  /// or with no signed-in user, is never mine. A tile without a cluster is
  /// ignored. A status the server spells unexpectedly (`tentative`, something
  /// new) counts as still to answer, never as an answer.
  /// [tilettes] supplies full rosters when mobile assignments omit them.
  static Map<String, MyClusterStatus> byCluster(Iterable<DesignatedTile> tiles,
      {required String? userId,
      Iterable<TileShareTemplate> tilettes = const <TileShareTemplate>[]}) {
    if (userId == null || userId.isEmpty) {
      return const <String, MyClusterStatus>{};
    }
    final Map<String, List<int>> counts = <String, List<int>>{};
    final Map<String, List<String>> pendingIds = <String, List<String>>{};
    for (final DesignatedTile tile in tiles) {
      if (tile.resolveDesignatedUserId(tilettes) != userId) continue;
      final String? clusterId = tile.tileTemplate?.clusterId;
      if (clusterId == null || clusterId.isEmpty) continue;
      // [accepted, declined, pending]
      final List<int> c = counts.putIfAbsent(clusterId, () => <int>[0, 0, 0]);
      switch (_statusOf(tile.invitationStatus)) {
        case InvitationStatus.accepted:
          c[0]++;
        case InvitationStatus.declined:
          c[1]++;
        case InvitationStatus.none:
          c[2]++;
          final String? id = tile.id;
          if (id != null && id.isNotEmpty) {
            pendingIds.putIfAbsent(clusterId, () => <String>[]).add(id);
          }
      }
    }
    return counts.map((String id, List<int> c) => MapEntry(
        id,
        MyClusterStatus(
            taskCount: c[0] + c[1] + c[2],
            accepted: c[0],
            declined: c[1],
            pending: c[2],
            pendingAssignmentIds: List<String>.unmodifiable(
                pendingIds[id] ?? const <String>[]))));
  }

  static InvitationStatus _statusOf(String? raw) {
    if (raw == null) return InvitationStatus.none;
    final String normalized =
        raw.contains('.') ? raw.substring(raw.lastIndexOf('.') + 1) : raw;
    return DesignatedTile.stringToInvitationStatus(normalized) ??
        InvitationStatus.none;
  }
}
