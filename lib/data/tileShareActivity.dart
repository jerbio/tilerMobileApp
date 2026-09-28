class TileShareActivity {
  final String eventId;
  final int schemaVersion;
  final String eventType;
  final String clusterId;
  final String? tiletteId;
  final DateTime occurredAt;
  final bool targetAvailable;
  final String? title;
  final String? actorName;
  final String? clusterTitle;
  final String? invitationChannel;

  static const knownTypes = {
    'cluster_created',
    'cluster_deleted',
    'tilette_added',
    'tilette_edited',
    'tilette_deleted',
    'tilette_restored',
    'recipient_added',
    'recipient_removed',
    'recipient_restored',
    'assignment_accepted',
    'assignment_declined',
    'invitation_sent',
    'invitation_send_failed',
    'invitation_send_unknown',
  };

  bool get isKnown => schemaVersion == 1 && knownTypes.contains(eventType);

  TileShareActivity.fromJson(Map<String, dynamic> json)
      : eventId = json['eventId'] as String,
        schemaVersion = json['schemaVersion'] as int,
        eventType = json['eventType'] as String,
        clusterId = json['clusterId'] as String,
        tiletteId = json['tiletteId'] as String?,
        occurredAt = DateTime.fromMillisecondsSinceEpoch(
            json['occurredAt'] as int,
            isUtc: true),
        targetAvailable = json['targetAvailable'] == true,
        actorName =
            json['actorId'] is String ? json['actorName'] as String? : null,
        clusterTitle = json['clusterTitle'] as String?,
        invitationChannel = json['schemaVersion'] == 1 &&
                const {
                  'invitation_sent',
                  'invitation_send_failed',
                  'invitation_send_unknown'
                }.contains(json['eventType']) &&
                json['metadata'] is Map &&
                const {'email', 'sms', 'push'}
                    .contains(json['metadata']['channel'])
            ? json['metadata']['channel'] as String
            : null,
        title = json['schemaVersion'] == 1 &&
                knownTypes.contains(json['eventType']) &&
                json['metadata'] is Map &&
                json['metadata']['title'] is String
            ? json['metadata']['title'] as String
            : null;
}

class TileShareActivityPage {
  final List<TileShareActivity> items;
  final String? nextCursor;
  final int historyAvailableFrom;

  TileShareActivityPage.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List)
            .map((item) =>
                TileShareActivity.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor = json['nextCursor'] as String?,
        historyAvailableFrom = json['historyAvailableFrom'] as int;
}
