// Edit Tile redesign — Step 1.1 / 6.0: the draft.
//
// The single source of truth for the redesigned Edit Tile screen. Seeded
// once from the loaded `SubCalendarEvent`, change-notified, read by
// stateless widgets. Nothing on this screen keeps state in a widget field
// (the legacy screen's defining defect, plan §1.1).
//
// Edit Tile edits ONE occurrence (D19): its title, when it happens, and its
// deadline. Everything that belongs to the calendar event — repetition,
// priority, location, colour, sessions — lives in `TileDetailDraft`.
//
// The rules it carries are the legacy rules, pinned in
// `test/editTile/edit_tile_rules_baseline_test.dart` before this file
// existed:
//
//   * `isDirty` is per field against the ORIGINAL, so a value set back to
//     what was loaded is not a change;
//   * `isValid` is `EditTilerEvent.isValid`, but names the failing rule;
//   * `canSave` is `editTileCanProceed`: a blocked-out tile whose time moved
//     saves even when otherwise invalid, everything else needs dirty+valid;
//   * `mode` is derived from ownership first, lifecycle second.
//
// Notes are deliberately NOT here: they persist themselves through the Notes
// API and never count as a change (D13).
import 'package:flutter/foundation.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

/// `ApplicableOccurence` on the sub-event update (D10). Edit Tile edits one
/// occurrence, so it only ever sends [single]; [all] is kept for the wire
/// vocabulary.
enum ApplicableOccurrence {
  single('Single'),
  all('All');

  const ApplicableOccurrence(this.wireValue);

  /// The backend's spelling, exactly.
  final String wireValue;
}

/// What the screen may do with the tile (plan §5.2).
enum EditTileMode {
  /// A live, Tiler-owned tile: the full form.
  editable,

  /// Completed or disabled: every row locked, actions limited.
  readOnly,

  /// Owned by a calendar provider: RSVP and Delete; rows locked.
  thirdParty,

  /// A blocked-out ("procrastinate") tile: name fixed, time editable.
  procrastinate,
}

/// The fields a user can change, for dirtiness tracking.
enum EditTileField { name, startTime, endTime, deadline }

/// Why a draft cannot be saved, for the CTA's disabled hint. Ordered as the
/// legacy `isValid` checks them; the first failure is the one reported.
enum EditTileInvalidReason { nameRequired, endNotAfterStart }

class EditTileDraft extends ChangeNotifier {
  EditTileDraft.fromLoaded(this.original)
      : _name = original.name ?? '',
        _startTime = original.startTime,
        _endTime = original.endTime,
        // Local, like every other time the draft holds: the sub-event's
        // getter builds this one in UTC, and a picker seeded with it would
        // open on the wrong day near midnight.
        _deadline = original.calendarEventEndTime?.toLocal() {
    _originalName = _name;
    _originalStart = _startTime;
    _originalEnd = _endTime;
    _originalDeadline = _deadline;
  }

  /// The sub-event as loaded. Never mutated.
  final SubCalendarEvent original;

  // --------------------------------------------------------------- identity

  /// The id the update is addressed to: a provider-owned tile is addressed
  /// by its provider id, as the legacy screen seeds it.
  String? get id => original.isFromTiler ? original.id : original.thirdpartyId;
  String? get thirdPartyId => original.thirdpartyId;
  String? get thirdPartyUserId => original.thirdPartyUserId;
  String get thirdPartyType =>
      original.thirdpartyType?.name.toLowerCase() ?? '';

  /// The note as loaded. Read-only here: notes persist themselves.
  String? get note => original.noteData?.note;

  DateTime? get calStartTime => original.calendarEventStartTime;

  /// The sessions count as loaded, sent back unchanged (`Split` is a
  /// required field of the legacy map; it is edited on Tile Detail, D19).
  int get split => original.split ?? 1;

  // ----------------------------------------------------------- working copy

  String _name;
  DateTime _startTime;
  DateTime _endTime;
  DateTime? _deadline;

  late final String _originalName;
  late final DateTime _originalStart;
  late final DateTime _originalEnd;
  late final DateTime? _originalDeadline;

  String get name => _name;
  DateTime get startTime => _startTime;
  DateTime get endTime => _endTime;

  /// The occurrence's deadline (`calEndTime` on the wire).
  DateTime? get deadline => _deadline;

  void setName(String value) => _update(() => _name = value);
  void setStartTime(DateTime value) => _update(() => _startTime = value);
  void setEndTime(DateTime value) => _update(() => _endTime = value);
  void setDeadline(DateTime? value) => _update(() => _deadline = value);

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  // ---------------------------------------------------------------- dirtiness

  static bool _sameInstant(DateTime? a, DateTime? b) =>
      a?.millisecondsSinceEpoch == b?.millisecondsSinceEpoch;

  /// The fields whose working value differs from what was loaded.
  Set<EditTileField> get dirtyFields => <EditTileField>{
        if (_name != _originalName) EditTileField.name,
        if (!_sameInstant(_startTime, _originalStart)) EditTileField.startTime,
        if (!_sameInstant(_endTime, _originalEnd)) EditTileField.endTime,
        if (!_sameInstant(_deadline, _originalDeadline)) EditTileField.deadline,
      };

  bool get isDirty => dirtyFields.isNotEmpty;

  /// A time or deadline moved — what the what-if preview reacts to.
  bool get timeIsDirty => dirtyFields.any(const <EditTileField>{
        EditTileField.startTime,
        EditTileField.endTime,
        EditTileField.deadline,
      }.contains);

  // ----------------------------------------------------------------- validity

  /// The first failing rule, in the legacy `isValid` order, or null.
  EditTileInvalidReason? get invalidReason {
    if (_name.trim().isEmpty) return EditTileInvalidReason.nameRequired;
    if (!_startTime.isBefore(_endTime)) {
      return EditTileInvalidReason.endNotAfterStart;
    }
    return null;
  }

  bool get isValid => invalidReason == null;

  // --------------------------------------------------------------------- mode

  /// Ownership first, then lifecycle, then kind (§5.2).
  EditTileMode get mode {
    if (!original.isFromTiler) return EditTileMode.thirdParty;
    if (!original.isActive) return EditTileMode.readOnly;
    if (original.isProcrastinate ?? false) return EditTileMode.procrastinate;
    return EditTileMode.editable;
  }

  /// A Block (rigid) rather than a Flexible tile. Displayed, never edited
  /// (D3).
  bool get isRigid => original.isRigid ?? false;

  // ------------------------------------------------------------------ canSave

  /// `editTileCanProceed`, reproduced: a blocked-out tile whose time moved
  /// saves when the frame is still positive, whatever else is wrong;
  /// otherwise a draft saves when it is dirty and valid.
  bool get canSave {
    if (mode == EditTileMode.procrastinate) {
      final bool timeMoved = !_sameInstant(_startTime, _originalStart) ||
          !_sameInstant(_endTime, _originalEnd);
      if (timeMoved && _startTime.isBefore(_endTime)) return true;
    }
    return isDirty && isValid;
  }

  /// Always this occurrence (D19).
  ApplicableOccurrence get effectiveScope => ApplicableOccurrence.single;
}
