/// One TileShare activity event as the server projects it
/// (`GET api/TileShare/Activity`).
///
/// Parsing is deliberately **allow-listed and schema-version-gated**: metadata
/// is only read for schema version 1 and for the exact event types that carry
/// it, every value is validated (types, lengths, ranges, allow-listed fields),
/// and anything else — unknown types, future schemas, raw provider payloads,
/// `legacySnapshot` — is ignored, so it can never surface in the UI.
class TileShareActivity {
  final String eventId;
  final int schemaVersion;
  final String eventType;
  final String clusterId;
  final String? tiletteId;
  final String? assignmentId;

  /// The account that performed the action; absent for a deleted account.
  final String? actorId;

  /// The affected participant of a recipient event (an id only).
  final String? targetUserId;
  final DateTime occurredAt;
  final bool targetAvailable;
  final String? title;
  final String? actorName;
  final String? clusterTitle;

  /// The task's current title, projected by the server while the task exists.
  final String? tiletteTitle;
  final String? invitationChannel;

  /// `assignment_completed` / `assignment_reopened`: the scheduled tile.
  final String? calendarEventId;

  /// `tilette_edited`: which of `name` / `deadline` / `note` changed.
  final List<String> changedFields;

  /// `tilette_edited` with a `deadline` change: the old and new deadline.
  final DateTime? deadlineBefore;
  final DateTime? deadlineAfter;

  static const knownTypes = {
    'cluster_created',
    'cluster_deleted',
    'cluster_invitation',
    'tilette_added',
    'tilette_edited',
    'tilette_deleted',
    'tilette_restored',
    'recipient_added',
    'recipient_removed',
    'recipient_restored',
    'assignment_accepted',
    'assignment_declined',
    'assignment_completed',
    'assignment_reopened',
    'invitation_sent',
    'invitation_send_failed',
    'invitation_send_unknown',
  };

  static const _titleTypes = {
    'tilette_added',
    'tilette_deleted',
    'tilette_restored',
    'cluster_deleted',
  };
  static const _deliveryTypes = {
    'invitation_sent',
    'invitation_send_failed',
    'invitation_send_unknown',
  };
  static const _calendarEventTypes = {
    'assignment_completed',
    'assignment_reopened',
  };

  /// The tilette fields the server allows in `changedFields`.
  static const editableFields = ['name', 'deadline', 'note'];
  static const _maxChangedFields = 4;
  static const _maxCalendarEventIdLength = 128;
  static const _maxEpochMs = 253402300799999;

  bool get isKnown => schemaVersion == 1 && knownTypes.contains(eventType);

  TileShareActivity.fromJson(Map<String, dynamic> json)
      : eventId = json['eventId'] as String,
        schemaVersion = json['schemaVersion'] as int,
        eventType = json['eventType'] as String,
        clusterId = json['clusterId'] as String,
        tiletteId = json['tiletteId'] as String?,
        assignmentId = _string(json['assignmentId']),
        actorId = _string(json['actorId']),
        targetUserId = _string(json['targetUserId']),
        occurredAt = DateTime.fromMillisecondsSinceEpoch(
            json['occurredAt'] as int,
            isUtc: true),
        targetAvailable = json['targetAvailable'] == true,
        actorName =
            json['actorId'] is String ? json['actorName'] as String? : null,
        clusterTitle = json['clusterTitle'] as String?,
        tiletteTitle = _string(json['tiletteTitle']),
        invitationChannel = _metadata(json, _deliveryTypes) != null &&
                const {'email', 'sms', 'push'}
                    .contains(_metadata(json, _deliveryTypes)!['channel'])
            ? _metadata(json, _deliveryTypes)!['channel'] as String
            : null,
        title = _metadata(json, _titleTypes)?['title'] is String
            ? _metadata(json, _titleTypes)!['title'] as String
            : null,
        calendarEventId = _calendarEventId(json),
        changedFields = _changedFields(json),
        deadlineBefore = _deadline(json, 'deadlineBefore'),
        deadlineAfter = _deadline(json, 'deadlineAfter');

  static String? _string(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The event's metadata map — only for schema version 1, a known type in
  /// [types], and a JSON object; otherwise `null`.
  static Map? _metadata(Map<String, dynamic> json, Set<String> types) {
    if (json['schemaVersion'] != 1) return null;
    final Object? type = json['eventType'];
    if (type is! String || !knownTypes.contains(type) || !types.contains(type)) {
      return null;
    }
    final Object? metadata = json['metadata'];
    return metadata is Map ? metadata : null;
  }

  static String? _calendarEventId(Map<String, dynamic> json) {
    final Object? id = _metadata(json, _calendarEventTypes)?['calendarEventId'];
    if (id is! String) return null;
    if (id.trim().isEmpty || id.length > _maxCalendarEventIdLength) return null;
    return id;
  }

  static List<String> _changedFields(Map<String, dynamic> json) {
    final Object? raw = _metadata(json, const {'tilette_edited'})?['changedFields'];
    if (raw is! List) return const <String>[];
    final List<String> fields = <String>[];
    for (final Object? field in raw) {
      if (field is String &&
          editableFields.contains(field) &&
          !fields.contains(field)) {
        fields.add(field);
        if (fields.length == _maxChangedFields) break;
      }
    }
    return List<String>.unmodifiable(fields);
  }

  static DateTime? _deadline(Map<String, dynamic> json, String key) {
    if (!_changedFields(json).contains('deadline')) return null;
    final Object? raw = _metadata(json, const {'tilette_edited'})?[key];
    if (raw is! int || raw < 0 || raw > _maxEpochMs) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
}

class TileShareActivityPage {
  final List<TileShareActivity> items;
  final String? nextCursor;
  final int historyAvailableFrom;

  const TileShareActivityPage(
      {required this.items, this.nextCursor, required this.historyAvailableFrom});

  TileShareActivityPage.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List)
            .map((item) =>
                TileShareActivity.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor = json['nextCursor'] as String?,
        historyAvailableFrom = json['historyAvailableFrom'] as int;
}
