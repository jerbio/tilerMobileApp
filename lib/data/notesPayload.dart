/// Response payload from `GET|PUT /api/CalendarEvent/Notes`.
///
/// Mirrors the C# `NotesPayload` DTO (and the TilerWeb `NotesPayload` type).
/// `Etag` is an opaque concurrency token returned by the server on every
/// load/save; callers should round-trip it on the next save.
class NotesPayload {
  final String? eventId;
  final String? scope;
  final String? userNote;
  final String? agentNote;
  final String? source;
  final String? authorUserId;
  final DateTime? agentNoteUpdatedAt;
  final String etag;
  final bool concurrencyConflict;
  final bool truncated;

  NotesPayload({
    this.eventId,
    this.scope,
    this.userNote,
    this.agentNote,
    this.source,
    this.authorUserId,
    this.agentNoteUpdatedAt,
    this.etag = '',
    this.concurrencyConflict = false,
    this.truncated = false,
  });

  factory NotesPayload.fromJson(Map<String, dynamic> json) {
    DateTime? parsedAgentUpdatedAt;
    final dynamic rawAgentUpdatedAt =
        json['AgentNoteUpdatedAt'] ?? json['agentNoteUpdatedAt'];
    if (rawAgentUpdatedAt is String && rawAgentUpdatedAt.isNotEmpty) {
      parsedAgentUpdatedAt = DateTime.tryParse(rawAgentUpdatedAt);
    }
    return NotesPayload(
      eventId: (json['EventId'] ?? json['eventId']) as String?,
      scope: (json['Scope'] ?? json['scope']) as String?,
      userNote: (json['UserNote'] ?? json['userNote']) as String?,
      agentNote: (json['AgentNote'] ?? json['agentNote']) as String?,
      source: (json['Source'] ?? json['source']) as String?,
      authorUserId: (json['AuthorUserId'] ?? json['authorUserId']) as String?,
      agentNoteUpdatedAt: parsedAgentUpdatedAt,
      etag: ((json['Etag'] ?? json['etag']) as String?) ?? '',
      concurrencyConflict: (json['concurrencyConflict'] as bool?) ?? false,
      truncated: (json['truncated'] as bool?) ?? false,
    );
  }
}

/// Scope discriminator for the Notes endpoint.
///
///  - [auto]     — sub-event blob if it has content, else parent calendar blob.
///  - [calendar] — always the parent calendar event blob.
///  - [subEvent] — always the sub-event blob.
enum NotesScope {
  auto,
  calendar,
  subEvent,
}

extension NotesScopeWire on NotesScope {
  String get wireValue {
    switch (this) {
      case NotesScope.calendar:
        return 'calendar';
      case NotesScope.subEvent:
        return 'subevent';
      case NotesScope.auto:
        return 'auto';
    }
  }
}
