import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// Semantic status of a single row on the Today Status screen.
///
/// Per the design spec §2.1 these are deliberately distinct from tile
/// *completion*: `placed` means Tiler found a valid slot for the tile, not that
/// the user finished it.
enum PlanItemStatus { placed, needsAttention, late }

/// Why a tile could not be placed (spec §8.2), ordered by display priority.
///
/// The backend does not supply these yet; [AttentionReasonCode.fromCode] exists
/// so the UI can consume them without a second migration once it does.
enum AttentionReasonCode {
  hardDeadlineConflict('HARD_DEADLINE_CONFLICT', 1),
  noFeasibleSlot('NO_FEASIBLE_SLOT', 2),
  travelInfeasible('TRAVEL_INFEASIBLE', 3),
  outsideAllowedHours('OUTSIDE_ALLOWED_HOURS', 4),
  dependencyBlocked('DEPENDENCY_BLOCKED', 5),
  durationExceedsGap('DURATION_EXCEEDS_GAP', 6),
  manualHold('MANUAL_HOLD', 7),
  unknown('UNKNOWN', 8);

  const AttentionReasonCode(this.wireValue, this.displayPriority);

  final String wireValue;
  final int displayPriority;

  /// Returns null for absent data so the row omits its chip entirely, rather
  /// than claiming an [unknown] reason the backend never sent (spec §17).
  static AttentionReasonCode? fromCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String normalized = raw.trim().toUpperCase();
    for (final AttentionReasonCode code in AttentionReasonCode.values) {
      if (code.wireValue == normalized) {
        return code;
      }
    }
    return AttentionReasonCode.unknown;
  }
}

/// One row of the Today Status screen, normalized so widgets never inspect raw
/// scheduling objects (spec §15.1).
class PlanItemViewModel {
  const PlanItemViewModel({
    required this.id,
    required this.status,
    required this.source,
    this.title,
    this.parentId,
    this.scheduledStart,
    this.displayDate,
    this.durationMinutes,
    this.reasonCode,
    this.priority = TilePriority.medium,
    this.isProcrastinate = false,
  });

  final String id;
  final PlanItemStatus status;

  /// Retained so the row can navigate to tile detail and so the existing
  /// multi-select completion flow keeps its third-party id/type arguments.
  final TilerEvent source;

  /// Id of the parent calendar event. Sub-events of one tile share this, which
  /// is what lets the section card collapse them into a single group. Null when
  /// the payload carried no parent, in which case the item stands alone.
  final String? parentId;

  /// Null when the tile has no name; the widget layer owns the localized
  /// "Untitled tile" fallback (spec §17).
  final String? title;
  final DateTime? scheduledStart;
  final DateTime? displayDate;
  final int? durationMinutes;
  final AttentionReasonCode? reasonCode;
  final TilePriority priority;
  final bool isProcrastinate;

  factory PlanItemViewModel.fromTilerEvent(
    TilerEvent event, {
    required PlanItemStatus status,
    AttentionReasonCode? reasonCode,
  }) {
    final String? name = event.name?.trim();
    return PlanItemViewModel(
      id: event.uniqueId.isNotEmpty ? event.uniqueId : (event.id ?? ''),
      status: status,
      source: event,
      title: (name == null || name.isEmpty) ? null : name,
      parentId: _parentIdOf(event),
      scheduledStart: _startOf(event),
      displayDate: _displayDateOf(event),
      durationMinutes: _durationMinutesOf(event),
      reasonCode: reasonCode,
      priority: event.priority,
      isProcrastinate: event.isProcrastinate == true,
    );
  }

  static String? _parentIdOf(TilerEvent event) {
    if (event is SubCalendarEvent) {
      final String? parentId = event.calendarEvent?.id;
      return (parentId == null || parentId.isEmpty) ? null : parentId;
    }
    return null;
  }

  static DateTime? _startOf(TilerEvent event) {
    final int? start = event.start?.toInt();
    if (start == null || start <= 0) {
      return null;
    }
    return event.startTime;
  }

  /// Prefers the parent calendar event's end date, matching the date the
  /// previous summary screen surfaced, and falls back to the scheduled start.
  static DateTime? _displayDateOf(TilerEvent event) {
    if (event is SubCalendarEvent) {
      return event.calendarEventEndTime ?? _startOf(event);
    }
    return _startOf(event);
  }

  /// Zero-length ranges report null so the UI omits the duration rather than
  /// rendering a meaningless "0 min" (spec §17).
  static int? _durationMinutesOf(TilerEvent event) {
    final int? start = event.start?.toInt();
    final int? end = event.end?.toInt();
    if (start == null || end == null) {
      return null;
    }
    final int minutes = Duration(milliseconds: end - start).inMinutes;
    return minutes > 0 ? minutes : null;
  }
}
