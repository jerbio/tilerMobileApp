/// The accept preview (redesign T21): what the backend answers for
/// `POST api/DesignatedTile/Preview` and its follow-ups. The model is tolerant —
/// a field the server adds, or a value this app does not know, never throws —
/// but it never invents permission: nothing may be accepted or explored unless
/// the response itself says so.

/// How an accepted preview is applied.
///
/// * [flexible] - accept every session at the reviewed times; Tiler may move
///   flexible work later as the schedule changes.
/// * [lockSession] - accept every session and fix only one of them (named by its
///   `sessionKey`, and by the interval the user was shown - see
///   [TileShareLockedTimeLine]) at that interval; the others stay flexible.
enum TileShareAcceptanceMode {
  flexible('Flexible'),
  lockSession('LockSession');

  /// The value the server expects.
  final String wire;

  const TileShareAcceptanceMode(this.wire);
}

/// The interval a lock fixes: when it starts (epoch ms, UTC) and how long it
/// is, sent as `LockedTimeLineRequest` on the accept.
///
/// With a preview the server **checks it against its own stored session** - it
/// must equal that session's start and length or the accept is a 409
/// `invalidSession` - so it states exactly what the user saw and agreed to; it
/// is not where the time comes from. It is only valid with a lock.
class TileShareLockedTimeLine {
  final int startMs;
  final int durationMs;

  const TileShareLockedTimeLine(
      {required this.startMs, required this.durationMs});

  /// The interval of a session, as the preview showed it.
  factory TileShareLockedTimeLine.fromBlock(PreviewBlock session) =>
      TileShareLockedTimeLine(
          startMs: session.startMs, durationMs: session.endMs - session.startMs);

  /// The wire form: `{StartTimeUnixMsUtc, DurationInMs}`.
  Map<String, Object> toJson() => <String, Object>{
        'StartTimeUnixMsUtc': startMs,
        'DurationInMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      other is TileShareLockedTimeLine &&
      other.startMs == startMs &&
      other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(startMs, durationMs);

  @override
  String toString() => 'TileShareLockedTimeLine($startMs, $durationMs ms)';
}

int? _ms(Object? value) => value is num ? value.toInt() : null;

String? _text(Object? value) => value?.toString();

/// Where the task's session ended up in the forecast.
enum PreviewPlacement {
  scheduled,
  outsideWindow,
  unscheduled,
  conflict,

  /// A value this app does not know.
  unknown,
}

PreviewPlacement? _placement(Object? raw) {
  if (raw == null) return null;
  switch (raw.toString().toLowerCase()) {
    case 'scheduled':
      return PreviewPlacement.scheduled;
    case 'outsidewindow':
      return PreviewPlacement.outsideWindow;
    case 'unscheduled':
      return PreviewPlacement.unscheduled;
    case 'conflict':
      return PreviewPlacement.conflict;
  }
  return PreviewPlacement.unknown;
}

/// One tile on the schedule, or one session of the task being previewed.
class PreviewBlock {
  final String id;
  final String? name;
  final int startMs;
  final int endMs;

  /// Part of the task being previewed (as opposed to the user's schedule).
  final bool isProposed;
  final bool viable;
  final bool isFixed;

  /// Identifies a session of the task in options / revise requests.
  final String? sessionKey;
  final int durationMs;
  final PreviewPlacement? placement;

  /// The tile's colour as the server sends it, `#RRGGBB`; `null` when it has
  /// none (the task being previewed has none yet).
  final String? color;

  /// The range the work may be placed in; `null` when not given.
  final int? allowedStartMs;
  final int? allowedEndMs;

  const PreviewBlock({
    required this.id,
    this.name,
    required this.startMs,
    required this.endMs,
    this.isProposed = false,
    this.viable = false,
    this.isFixed = false,
    this.sessionKey,
    required this.durationMs,
    this.placement,
    this.color,
    this.allowedStartMs,
    this.allowedEndMs,
  });

  /// [color] as an opaque ARGB integer (`0xFFRRGGBB`), or `null` when there is
  /// no colour or it is not six hex digits.
  int? get colorArgb {
    final String? raw = color;
    if (raw == null) return null;
    final String hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return 0xFF000000 | int.parse(hex, radix: 16);
  }

  factory PreviewBlock.fromJson(Map<String, dynamic> json) {
    final int start = _ms(json['start']) ?? 0;
    final int end = _ms(json['end']) ?? start;
    return PreviewBlock(
      id: _text(json['id']) ?? '',
      name: _text(json['name']),
      startMs: start,
      endMs: end,
      isProposed: json['isProposed'] == true,
      viable: json['viable'] == true,
      isFixed: json['isFixed'] == true,
      sessionKey: _text(json['sessionKey']),
      durationMs: _ms(json['duration']) ?? (end - start),
      placement: _placement(json['placement']),
      color: _text(json['color']),
      allowedStartMs: _ms(json['allowedStart']),
      allowedEndMs: _ms(json['allowedEnd']),
    );
  }
}

/// What the client may do with this preview. **Per response**: the server
/// reports all `true` for a preview it stored (viable, with a token) and all
/// `false` otherwise.
class PreviewCapabilities {
  final bool alternatives;
  final bool fixedSessions;
  final bool reviewedAcceptance;

  const PreviewCapabilities({
    this.alternatives = false,
    this.fixedSessions = false,
    this.reviewedAcceptance = false,
  });

  static const PreviewCapabilities none = PreviewCapabilities();

  factory PreviewCapabilities.fromJson(Object? json) {
    if (json is! Map) return none;
    return PreviewCapabilities(
      alternatives: json['alternatives'] == true,
      fixedSessions: json['fixedSessions'] == true,
      reviewedAcceptance: json['reviewedAcceptance'] == true,
    );
  }
}

/// Why the server did not even try.
enum PreviewUnsupportedReason {
  alreadyAccepted,
  missingFutureDeadline,
  unsupportedConstraints,

  /// A reason this app does not know; see
  /// [TileSharePreview.unsupportedReasonText].
  other,
}

PreviewUnsupportedReason? _reason(Object? raw) {
  if (raw == null) return null;
  final String text = raw.toString();
  if (text.trim().isEmpty) return null;
  for (final PreviewUnsupportedReason reason in PreviewUnsupportedReason.values) {
    if (reason != PreviewUnsupportedReason.other &&
        reason.name.toLowerCase() == text.toLowerCase()) {
      return reason;
    }
  }
  return PreviewUnsupportedReason.other;
}

/// The forecast of accepting one assignment.
class TileSharePreview {
  final String assignmentId;
  final String? tiletteId;
  final String? clusterId;
  final String? definition;
  final String? name;
  final String? description;
  final String? inviterName;
  final int? durationMs;
  final int? deadlineMs;
  final int? generatedAtMs;
  final String? timeZone;

  /// Set when the server did not try (already accepted, no future deadline,
  /// constraints the preview cannot honour).
  final PreviewUnsupportedReason? unsupportedReason;
  final String? unsupportedReasonText;

  /// Every session could be placed before the deadline.
  final bool isViable;

  /// The window the blocks cover.
  final int? rangeStartMs;
  final int? rangeEndMs;
  final PreviewCapabilities capabilities;

  /// The user's schedule, and the schedule with the task placed.
  final List<PreviewBlock> current;
  final List<PreviewBlock> proposed;

  /// The task's own sessions, and whatever is in the way.
  final List<PreviewBlock> sessions;
  final List<PreviewBlock> conflicts;
  final String? scheduleRevision;

  /// Which arrangement of the user's flexible tiles this forecast used (each
  /// alternative is a different one).
  final int? shuffleSeed;

  /// Names this exact preview for options / revise / accept; issued only for a
  /// viable preview, and only valid until [expiresAtMs].
  final String? previewToken;
  final int? expiresAtMs;

  const TileSharePreview({
    required this.assignmentId,
    this.tiletteId,
    this.clusterId,
    this.definition,
    this.name,
    this.description,
    this.inviterName,
    this.durationMs,
    this.deadlineMs,
    this.generatedAtMs,
    this.timeZone,
    this.unsupportedReason,
    this.unsupportedReasonText,
    this.isViable = false,
    this.rangeStartMs,
    this.rangeEndMs,
    this.capabilities = PreviewCapabilities.none,
    this.current = const <PreviewBlock>[],
    this.proposed = const <PreviewBlock>[],
    this.sessions = const <PreviewBlock>[],
    this.conflicts = const <PreviewBlock>[],
    this.scheduleRevision,
    this.shuffleSeed,
    this.previewToken,
    this.expiresAtMs,
  });

  factory TileSharePreview.fromJson(Map<String, dynamic> json) {
    List<PreviewBlock> blocks(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => PreviewBlock.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <PreviewBlock>[];
    final Object? reasonRaw = json['unsupportedReason'];
    return TileSharePreview(
      assignmentId: _text(json['assignmentId']) ?? '',
      tiletteId: _text(json['tiletteId']),
      clusterId: _text(json['clusterId']),
      definition: _text(json['definition']),
      name: _text(json['name']),
      description: _text(json['description']),
      inviterName: _text(json['inviterName']),
      durationMs: _ms(json['duration']),
      deadlineMs: _ms(json['deadline']),
      generatedAtMs: _ms(json['generatedAt']),
      timeZone: _text(json['timeZone']),
      unsupportedReason: _reason(reasonRaw),
      unsupportedReasonText: _reason(reasonRaw) == null ? null : _text(reasonRaw),
      isViable: json['isViable'] == true,
      rangeStartMs: _ms(json['rangeStart']),
      rangeEndMs: _ms(json['rangeEnd']),
      capabilities: PreviewCapabilities.fromJson(json['capabilities']),
      current: blocks(json['current']),
      proposed: blocks(json['proposed']),
      sessions: blocks(json['sessions']),
      conflicts: blocks(json['conflicts']),
      scheduleRevision: _text(json['scheduleRevision']),
      shuffleSeed: _ms(json['shuffleSeed']),
      previewToken: _text(json['previewToken']),
      expiresAtMs: _ms(json['expiresAt']),
    );
  }

  bool get isUnsupported => unsupportedReason != null;

  /// Accepting exactly this preview: it works out, the server stored it (a
  /// token), and the server says reviewed acceptance is allowed.
  bool get canAccept =>
      isViable && previewToken != null && capabilities.reviewedAcceptance;

  /// Other times can be asked for: there is a token to ask about and the server
  /// says alternatives are allowed.
  bool get canFindOtherTimes =>
      previewToken != null && capabilities.alternatives;

  bool isExpiredAt(DateTime now) =>
      expiresAtMs != null && now.millisecondsSinceEpoch >= expiresAtMs!;

  /// The task's sessions that were placed, to draw as the proposed blocks. An
  /// unplaced session is never drawn as a tile.
  List<PreviewBlock> get proposedSessionBlocks =>
      sessions.where((b) => b.isProposed && b.viable).toList();
}

/// One alternative: a different arrangement that places the task at
/// [startMs]..[endMs]. It normally brings its whole [preview] (whose token is
/// [optionId]), so choosing it needs no further request; a server that sends
/// only the id and the times leaves [preview] `null` and the option is chosen
/// with a revise instead.
class PreviewOption {
  final String optionId;
  final int startMs;
  final int endMs;
  final TileSharePreview? preview;

  const PreviewOption({
    required this.optionId,
    required this.startMs,
    required this.endMs,
    this.preview,
  });

  factory PreviewOption.fromJson(Map<String, dynamic> json) {
    final Object? embedded = json['preview'];
    return PreviewOption(
      optionId: _text(json['optionId']) ?? '',
      startMs: _ms(json['start']) ?? 0,
      endMs: _ms(json['end']) ?? 0,
      preview: embedded is Map
          ? TileSharePreview.fromJson(Map<String, dynamic>.from(embedded))
          : null,
    );
  }
}

/// A page of alternatives; [nextOffset] is where "Find another time" goes on
/// from, `null` when there are no more.
class PreviewOptionsPage {
  final List<PreviewOption> options;
  final int? nextOffset;

  const PreviewOptionsPage({required this.options, this.nextOffset});

  factory PreviewOptionsPage.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['options'];
    return PreviewOptionsPage(
      options: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => PreviewOption.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <PreviewOption>[],
      nextOffset: _ms(json['nextOffset']),
    );
  }

  bool get hasMore => nextOffset != null;
}

enum OperationState {
  preview,
  queued,
  applied,
  completed,
  rejected,
  needsReview,

  /// A state this app does not know; never treated as finished.
  unknown,
}

OperationState _operationState(Object? raw) {
  final String normalized = (raw?.toString() ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]'), '');
  switch (normalized) {
    case 'preview':
      return OperationState.preview;
    case 'queued':
      return OperationState.queued;
    case 'applied':
      return OperationState.applied;
    case 'completed':
      return OperationState.completed;
    case 'rejected':
      return OperationState.rejected;
    case 'needsreview':
      return OperationState.needsReview;
  }
  return OperationState.unknown;
}

/// An accept that was queued on the server; poll it until it is final.
class TileShareOperation {
  final String operationId;
  final String assignmentId;
  final OperationState state;
  final String? calendarId;
  final String? reason;

  const TileShareOperation({
    required this.operationId,
    required this.assignmentId,
    required this.state,
    this.calendarId,
    this.reason,
  });

  factory TileShareOperation.fromJson(Map<String, dynamic> json) =>
      TileShareOperation(
        operationId: _text(json['operationId']) ?? '',
        assignmentId: _text(json['assignmentId']) ?? '',
        state: _operationState(json['state']),
        calendarId: _text(json['calendarId']),
        reason: _text(json['reason']),
      );

  /// No more changes are coming. An unknown state is never final.
  bool get isFinal =>
      state == OperationState.completed ||
      state == OperationState.rejected ||
      state == OperationState.needsReview;

  bool get succeeded => state == OperationState.completed;
}

/// What a recipient can recover about an assignment after the fact.
class TileShareAssignmentResponse {
  final String id;
  final String? tiletteId;
  final String? clusterId;
  final String? invitationStatus;
  final double? completionPercent;
  final String? calendarId;

  const TileShareAssignmentResponse({
    required this.id,
    this.tiletteId,
    this.clusterId,
    this.invitationStatus,
    this.completionPercent,
    this.calendarId,
  });

  factory TileShareAssignmentResponse.fromJson(Map<String, dynamic> json) =>
      TileShareAssignmentResponse(
        id: _text(json['id']) ?? '',
        tiletteId: _text(json['tiletteId']),
        clusterId: _text(json['clusterId']),
        invitationStatus: _text(json['invitationStatus']),
        completionPercent: (json['completionPercent'] as num?)?.toDouble(),
        calendarId: _text(json['calendarId']),
      );

  bool get isAccepted =>
      (invitationStatus ?? '').toLowerCase().endsWith('accepted');
}
