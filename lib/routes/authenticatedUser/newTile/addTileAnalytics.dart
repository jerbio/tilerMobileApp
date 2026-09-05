// Add Tile redesign — funnel analytics and diagnostic envelope.
//
// Implements docs/add-tile-analytics-schema.md: the Section 2 funnel events,
// the Section 3 envelope, the Section 4 field ids, and the Section 5 reason
// codes. Section 6 is the constraint that shapes the whole file — NO
// user-entered content is ever emitted. Only enumerated categories, booleans,
// presence flags, and coarse duration buckets leave this class.
//
// The privacy property is structural, not a matter of care at each call site:
// every method below takes an `AddTileDraft` (or nothing) and derives only
// categorical values from it. No method accepts a free-form string from the
// form, and nothing serializes a draft, a snapshot, or a `NewTile`.
//
// KNOWN GAP (schema finding O1): the production sink `AnalysticsSignal.send`
// returns on its first line, so nothing actually reaches Firebase today. That
// is an app-wide condition affecting every existing signal, not something this
// module introduces or can fix on its own — wiring here is still correct and
// becomes live the moment O1 is resolved. Tests inject their own sink and are
// unaffected either way.
import 'dart:math';

import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/services/analyticsSignal.dart';

/// Schema Section 3 `flow_version` values. Single source of truth — the
/// feature-flag class defers to these so the emitted variant string cannot
/// drift from the flag that selects it. Underscore-separated, matching every
/// other enumerated value in the schema.
const String addTileRedesignFlowVersion = 'redesign_v1';
const String addTileLegacyFlowVersion = 'legacy';

/// Schema Section 4 — enumerated field ids. The ONLY tokens allowed in
/// `missing_fields` / `last_completed_field`.
const Set<String> addTileFieldIds = <String>{
  'name',
  'duration',
  'complete_by',
  'preferred_time',
  'location',
  'repeat',
  'priority',
  'color',
  'split_sessions',
  'flexible_completion',
  'date',
  'start',
};

/// Schema Section 5 — the allow-listed `reason_code` values.
const Set<String> addTileReasonCodes = <String>{
  'duration_invalid',
  'name_missing',
  'date_invalid',
  'start_invalid',
  'recurrence_conflict',
  'repeat_deadline_ordering',
  'network_timeout',
  'api_rejected',
  'picker_result_malformed',
  'stale_suggestion_ignored',
  'location_permission_denied',
  'suggestion_timeout',
  'route_interrupted',
  'duplicate_submit_blocked',
  'unexpected_mapper_state',
};

/// Maps a validation reason code from [AddTileDraft.validate] to the schema's
/// enumerated FIELD id. The draft's codes and the schema's ids are different
/// vocabularies; this is the single translation point.
const Map<String, String> _validationFieldIds = <String, String>{
  'name_empty': 'name',
  'duration_invalid': 'duration',
};

/// Coarse elapsed bucket — schema Section 3 forbids raw timestamps.
String elapsedBucket(Duration elapsed) {
  if (elapsed.inSeconds < 30) return 'lt_30s';
  if (elapsed.inMinutes < 2) return '30s_2m';
  return 'gt_2m';
}

/// The sink an [AddTileAnalytics] emits through. Injected in tests; defaults
/// to the app's existing signal service.
typedef AddTileAnalyticsSend = void Function(
    String tag, Map<String, Object?> properties);

void _defaultSend(String tag, Map<String, Object?> properties) {
  // The existing service takes an untyped map; the envelope is already
  // sanitized by construction here.
  AnalysticsSignal.send(tag, additionalInfo: properties);
}

/// Emits the Add Tile redesign funnel with a consistent diagnostic envelope.
///
/// One instance per Add flow: it owns the ephemeral `session_id` that
/// correlates the events of a single creation attempt. That id is random and
/// per-flow — it is NOT a user identifier (schema Section 3).
class AddTileAnalytics {
  AddTileAnalytics({
    AddTileAnalyticsSend? send,
    this.entryPoint,
    String? sessionId,
    DateTime Function()? clock,
  })  : _send = send ?? _defaultSend,
        _clock = clock ?? DateTime.now,
        sessionId = sessionId ?? _newSessionId() {
    _openedAt = _clock();
  }

  static final Random _random = Random();

  static String _newSessionId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 32).toRadixString(36)}';

  final AddTileAnalyticsSend _send;
  final DateTime Function() _clock;

  /// Ephemeral correlation id for ONE Add flow. Not a user id.
  final String sessionId;

  /// Schema Section 3 `entry_point`, supplied by whichever route opened the
  /// form. Null until entry points are wired through in Phase 3.
  final String? entryPoint;

  late final DateTime _openedAt;

  /// Time since the form opened, as a coarse bucket.
  String get _elapsed => elapsedBucket(_clock().difference(_openedAt));

  String _itemType(AddTileType type) =>
      type == AddTileType.flexible ? 'flexible' : 'fixed';

  /// Builds the Section 3 envelope shared by every event.
  Map<String, Object?> _envelope(AddTileType type, {String? step}) {
    return <String, Object?>{
      'flow_version': addTileRedesignFlowVersion,
      'session_id': sessionId,
      'item_type': _itemType(type),
      if (entryPoint != null) 'entry_point': entryPoint,
      if (step != null) 'step': step,
    };
  }

  void _emit(String tag, Map<String, Object?> properties) {
    _send(tag, properties);
  }

  /// `ADD_ITEM_OPENED` — once per Add flow, at construction.
  void opened(AddTileType type, {required bool hasPrefill}) {
    _emit('ADD_ITEM_OPENED', <String, Object?>{
      ..._envelope(type, step: 'form'),
      'has_prefill': hasPrefill,
    });
  }

  /// `ADD_ITEM_TYPE_CHANGED` — the segmented control changed the type.
  void typeChanged({
    required AddTileType from,
    required AddTileType to,
    required bool fieldsEdited,
  }) {
    _emit('ADD_ITEM_TYPE_CHANGED', <String, Object?>{
      ..._envelope(to, step: 'form'),
      'from': _itemType(from),
      'to': _itemType(to),
      'fields_edited': fieldsEdited,
    });
  }

  /// `ADD_ITEM_ADVANCED_OPENED` — More options was EXPANDED. Collapsing is
  /// not an "opened" event.
  void advancedOpened(AddTileType type) {
    _emit('ADD_ITEM_ADVANCED_OPENED', _envelope(type, step: 'more_options'));
  }

  /// `ADD_ITEM_SUBMIT_TAPPED` — the CTA was tapped, valid or not.
  ///
  /// [missingFieldIds] must already be enumerated ids; it is derived from the
  /// draft by [missingFieldsOf] so no caller can pass field content.
  void submitTapped(
    AddTileType type, {
    required bool valid,
    required List<String> missingFieldIds,
  }) {
    _emit('ADD_ITEM_SUBMIT_TAPPED', <String, Object?>{
      ..._envelope(type, step: 'submit'),
      'valid': valid,
      'missing_fields': missingFieldIds.join(','),
      'outcome': valid ? 'success' : 'validation_error',
    });
  }

  /// `ADD_ITEM_SUBMIT_RESULT` — the outcome of an attempted submission.
  void submitResult(
    AddTileType type, {
    required String outcome,
    String? reasonCode,
  }) {
    assert(
      reasonCode == null || addTileReasonCodes.contains(reasonCode),
      'reason_code "$reasonCode" is not in the schema allow-list',
    );
    _emit('ADD_ITEM_SUBMIT_RESULT', <String, Object?>{
      ..._envelope(type, step: 'submit'),
      'outcome': outcome,
      if (reasonCode != null) 'reason_code': reasonCode,
      'elapsed_bucket': _elapsed,
    });
  }

  /// `ADD_ITEM_DISMISSED` — the root Close was used.
  void dismissed(AddTileType type, {required bool dirty}) {
    _emit('ADD_ITEM_DISMISSED', <String, Object?>{
      ..._envelope(type, step: 'form'),
      'dirty': dirty,
      'elapsed_bucket': _elapsed,
    });
  }
}

/// Enumerated ids of the draft's currently-invalid fields, in a stable order.
///
/// Derived from [AddTileDraft.validate]'s reason codes, so telemetry can never
/// carry a field VALUE — only which field ids were incomplete. An unmapped
/// code is dropped rather than guessed: emitting an unknown token would
/// silently miss every dashboard filter.
List<String> missingFieldsOf(AddTileDraft draft) {
  final List<String> ids = <String>[];
  for (final MapEntry<String, String> entry in draft.validate().entries) {
    final String? id = _validationFieldIds[entry.value];
    if (id != null && addTileFieldIds.contains(id) && !ids.contains(id)) {
      ids.add(id);
    }
  }
  return ids;
}

/// Whether the draft carries prefilled content at open time. A presence flag
/// only — never what was prefilled.
bool draftHasPrefill(AddTileDraft draft) =>
    draft.name.trim().isNotEmpty ||
    draft.duration.inMinutes > 0 ||
    draft.endTime != null;

/// Kept for the priority option-category events in a later slice; declared
/// here so the vocabulary lives with the rest of the schema.
String priorityCategory(TilePriority priority) => priority.name;
