// Tile Detail redesign — Step 6.1: the draft.
//
// The single source of truth for the redesigned Tile Detail (calendar
// event) screen. Seeded once from the loaded `CalendarEvent`, change-
// notified, read by stateless widgets — the same shape as `EditTileDraft`.
//
// Tile Detail edits the SERIES (D19): its name, the length of each
// occurrence, how many sessions, where, how it repeats, its priority and
// colour. Sent back exactly as loaded (D14): the series window, deadline
// automation, the restriction profile, identity, the note (which persists
// itself through the Notes API, D13).
//
// The rules are the legacy screen's, pinned in
// `test/editTile/edit_tile_series_payload_baseline_test.dart` (the map) and
// `test/tileDetail/tile_detail_draft_test.dart` (the model):
//
//   * dirtiness is per field against the ORIGINAL, using the comparisons
//     `Utility.isEditTileEventEquivalentToCalendarEvent` makes — duration
//     by minutes, location by address + description, repetition by rule;
//   * `isValid` is `EditCalendarEvent.isValid` on the editable fields, but
//     names the failing rule;
//   * `canSave` is `TileDetail.updateProceed`: valid and not equivalent to
//     what was loaded (its procrastinate shortcut moved the window, which
//     this screen does not edit — see `canSave`);
//   * `mode` is derived from ownership first, lifecycle second.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart'
    show EditTileDraft, EditTileMode;

/// The fields a user can change, for dirtiness tracking.
enum TileDetailField {
  name,
  duration,
  split,
  location,
  repetition,
  priority,
  color,
  restriction,
}

/// Why a draft cannot be saved, for the CTA's disabled hint. Ordered as
/// `EditCalendarEvent.isValid` checks them; the first failure is reported.
enum TileDetailInvalidReason { nameRequired, splitRequired }

class TileDetailDraft extends ChangeNotifier {
  /// [location] is the separately loaded location the legacy screen edits
  /// (`LocationBloc` by calendar-event id); when given it is the original,
  /// otherwise the event's own.
  TileDetailDraft.fromLoaded(this.original, {Location? location})
      : _name = original.name ?? '',
        _duration = original.tileDuration,
        _split = original.split ?? 1,
        _location = _present(location ?? original.location),
        _repetition = original.repetition?.toRepetitionData(),
        _priority = original.priority,
        _color = original.uiConfig?.tileColor?.toColor,
        _restriction = original.restrictionProfile {
    _originalName = _name;
    _originalDuration = _duration;
    _originalSplit = _split;
    _originalLocation = _location;
    _originalRepetition = _repetition;
    _originalPriority = _priority;
    _originalColor = _color;
    _originalRestriction = _restriction;
  }

  /// The calendar event as loaded. Never mutated.
  final CalendarEvent original;

  // --------------------------------------------------------------- identity

  String? get id => original.id;
  String? get thirdPartyId => original.thirdpartyId;
  String? get thirdPartyUserId => original.thirdPartyUserId;
  String get thirdPartyType =>
      original.thirdpartyType?.name.toLowerCase() ?? '';

  // ------------------------------------------------------------ passthrough

  /// The series window. Not edited here; sent as loaded (D14).
  DateTime get windowStart => original.startTime;
  DateTime get windowEnd => original.endTime;

  /// Deadline automation. Not surfaced; sent as loaded (D14). Note that
  /// `isAutoDeadline` is never parsed from the wire today, so it is null.
  bool? get isAutoDeadline => original.isAutoDeadline;
  bool? get isAutoReviseDeadline => original.isAutoReviseDeadline;

  /// The note, or null when there is none (an empty note or the legacy
  /// literal "null"). Notes persist themselves through the Notes API
  /// (D13): a persisted value is MIRRORED here so the row and the next save
  /// carry it, and it never counts as a change.
  String? get note => EditTileDraft.presentNote(rawNote);

  /// What the wire gets for `Notes`: the mirrored note, else the loaded
  /// one, else '' — the legacy seed for an event with no note object.
  String? get rawNote =>
      _noteMirror ?? (original.noteData == null ? '' : original.noteData!.note);

  String? _noteMirror;
  void mirrorNote(String value) => _update(() => _noteMirror = value);

  /// A Block (rigid) rather than a Flexible tile. Displayed, never edited
  /// (D3).
  bool get isRigid => original.isRigid ?? false;

  // ----------------------------------------------------------- working copy

  String _name;
  Duration? _duration;
  int _split;
  Location? _location;
  RepetitionData? _repetition;
  TilePriority _priority;
  Color? _color;
  RestrictionProfile? _restriction;

  late final String _originalName;
  late final Duration? _originalDuration;
  late final int _originalSplit;
  late final Location? _originalLocation;
  late final RepetitionData? _originalRepetition;
  late final TilePriority _originalPriority;
  late final Color? _originalColor;
  late final RestrictionProfile? _originalRestriction;

  String get name => _name;

  /// The length of each occurrence (`tileDuration` / `Duration` on the
  /// wire). Null when the server sent none.
  Duration? get duration => _duration;

  /// Sessions (`splitCount` / `Split`).
  int get split => _split;

  /// The place, or null when there is none. A location with no content is
  /// held as null (the legacy `isNotNullAndNotDefault` rule).
  Location? get location => _location;

  /// The place as loaded (the loader-supplied one when given), for the
  /// mapper's unchanged-address rule (6.2).
  Location? get originalLocation => _originalLocation;
  RepetitionData? get repetition => _repetition;
  TilePriority get priority => _priority;
  Color? get color => _color;

  /// The preferred-time (restriction) profile; null is Anytime.
  RestrictionProfile? get restrictionProfile => _restriction;

  void setName(String value) => _update(() => _name = value);
  void setDuration(Duration? value) => _update(() => _duration = value);
  void setSplit(int value) => _update(() => _split = value);
  void setLocation(Location? value) =>
      _update(() => _location = _present(value));
  void clearLocation() => _update(() => _location = null);
  void setRepetition(RepetitionData? value) =>
      _update(() => _repetition = value);
  void setPriority(TilePriority value) => _update(() => _priority = value);
  void setColor(Color? value) => _update(() => _color = value);
  void setRestrictionProfile(RestrictionProfile? value) =>
      _update(() => _restriction = value);

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  /// Null for a location with nothing in it, so "no place" has one
  /// spelling.
  static Location? _present(Location? location) {
    if (location == null) return null;
    final bool hasContent = (location.address ?? '').trim().isNotEmpty ||
        (location.description ?? '').trim().isNotEmpty;
    return hasContent ? location : null;
  }

  // ---------------------------------------------------------------- dirtiness

  static bool _sameMinutes(Duration? a, Duration? b) =>
      a?.inMinutes == b?.inMinutes;

  /// The legacy equivalence compares the address and its description and
  /// nothing else about a place.
  static bool _samePlace(Location? a, Location? b) {
    if (a == null || b == null) return a == b;
    return (a.address ?? '') == (b.address ?? '') &&
        (a.description ?? '') == (b.description ?? '');
  }

  static bool _sameInstant(DateTime? a, DateTime? b) =>
      a?.millisecondsSinceEpoch == b?.millisecondsSinceEpoch;

  /// `Repetition.isEquivalent`, on the picker's shape of the rule.
  static bool _sameRule(RepetitionData? a, RepetitionData? b) {
    if (a == null || b == null) return a == b;
    return a.frequency == b.frequency &&
        a.isEnabled == b.isEnabled &&
        a.isForever == b.isForever &&
        _sameInstant(a.repetitionStart, b.repetitionStart) &&
        _sameInstant(a.repetitionEnd, b.repetitionEnd) &&
        setEquals(a.weeklyRepetition ?? const <int>{},
            b.weeklyRepetition ?? const <int>{});
  }

  /// The legacy equivalence: both present → `isEquivalent`, else identity.
  static bool _sameProfile(RestrictionProfile? a, RestrictionProfile? b) {
    if (a != null && b != null) return a.isEquivalent(b);
    return a == b;
  }

  /// The fields whose working value differs from what was loaded.
  Set<TileDetailField> get dirtyFields => <TileDetailField>{
        if (_name != _originalName) TileDetailField.name,
        if (!_sameMinutes(_duration, _originalDuration))
          TileDetailField.duration,
        if (_split != _originalSplit) TileDetailField.split,
        if (!_samePlace(_location, _originalLocation)) TileDetailField.location,
        if (!_sameRule(_repetition, _originalRepetition))
          TileDetailField.repetition,
        if (_priority != _originalPriority) TileDetailField.priority,
        if (_color != _originalColor) TileDetailField.color,
        if (!_sameProfile(_restriction, _originalRestriction))
          TileDetailField.restriction,
      };

  bool get isDirty => dirtyFields.isNotEmpty;

  /// A place was loaded and the user removed it — what the wire's
  /// `IsLocationCleared` flag means (6.2).
  bool get locationCleared => _originalLocation != null && _location == null;

  // ----------------------------------------------------------------- validity

  /// The first failing rule, in the legacy `isValid` order, or null. The
  /// identity and window checks of that rule hold by construction for a
  /// loaded event and are not repeated here.
  TileDetailInvalidReason? get invalidReason {
    if (_name.trim().isEmpty) return TileDetailInvalidReason.nameRequired;
    if (_split < 1) return TileDetailInvalidReason.splitRequired;
    return null;
  }

  bool get isValid => invalidReason == null;

  // --------------------------------------------------------------------- mode

  /// Owned by a calendar provider. Only an EXPLICIT non-Tiler source counts:
  /// `api/CalendarEvent` omits `thirdPartyType` for Tiler's own events, so
  /// `isFromTiler` (which needs the field) would lock every series.
  bool get isProviderOwned =>
      original.thirdpartyType != null &&
      original.thirdpartyType != TileSource.tiler;

  /// Ownership first, then lifecycle, then kind (§5.2), as Edit Tile.
  EditTileMode get mode {
    if (isProviderOwned) return EditTileMode.thirdParty;
    if (!original.isActive) return EditTileMode.readOnly;
    if (original.isProcrastinate ?? false) return EditTileMode.procrastinate;
    return EditTileMode.editable;
  }

  // ------------------------------------------------------------------ canSave

  /// `TileDetail.updateProceed`, reproduced: a draft saves when it is valid
  /// and not equivalent to what was loaded. The legacy shortcut for a
  /// blocked-out tile whose window moved is unreachable here — the window
  /// is sent as loaded (D14) — so the plain rule is the whole rule.
  bool get canSave => isDirty && isValid;
}
