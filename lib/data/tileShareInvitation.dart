/// One pending invitation of the signed-in user, from
/// `GET api/TileShare/Invitations`. The server deliberately exposes only what
/// is needed to respond — no roster and no cluster history.
class TileShareInvitation {
  /// The recipient's own assignment (the id a response is sent against).
  final String assignmentId;
  final String clusterId;
  final String? tiletteId;

  /// The task's name.
  final String? name;
  final String? clusterName;

  /// The task's deadline in epoch ms; `null` when it has none.
  final int? deadlineMs;
  final String? inviterName;

  const TileShareInvitation({
    required this.assignmentId,
    required this.clusterId,
    this.tiletteId,
    this.name,
    this.clusterName,
    this.deadlineMs,
    this.inviterName,
  });

  TileShareInvitation.fromJson(Map<String, dynamic> json)
      : assignmentId = (json['assignmentId'] ?? '').toString(),
        clusterId = (json['clusterId'] ?? '').toString(),
        tiletteId = json['tiletteId'] as String?,
        name = json['name'] as String?,
        clusterName = json['clusterName'] as String?,
        deadlineMs = json['deadline'] is num
            ? (json['deadline'] as num).toInt()
            : null,
        inviterName = json['inviterName'] as String?;
}

class TileShareInvitationPage {
  final List<TileShareInvitation> items;
  final String? nextCursor;

  const TileShareInvitationPage(this.items, [this.nextCursor]);

  TileShareInvitationPage.fromJson(Map<String, dynamic> json)
      : items = ((json['invitations'] as List?) ?? const <dynamic>[])
            .map((e) => TileShareInvitation.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor = json['nextCursor'] as String?;
}
