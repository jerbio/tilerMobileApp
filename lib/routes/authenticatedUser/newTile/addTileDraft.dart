import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// Explicit add-flow type, replacing the legacy `isAppointment` boolean.
/// `false`==flexible, `true`==fixed in the legacy mapping; the request
/// mapper keeps that equivalence.
enum AddTileType { flexible, fixed }

/// Fields the app's auto-suggestion service may populate.
enum AddTileSuggestedField {
  name,
  duration,
  location,
  endTime,
  restrictionProfile,
}

/// Outcome for the Repeat value when the user changes type.
enum RepeatSwitchDecision { preserve, confirmBeforeClear }

/// Which fields a suggestion/dirty check concerns, internally.
enum _Field {
  name,
  duration,
  startTime,
  endTime,
  restrictionProfile,
  isAutoRevisable,
  priority,
  splitCount,
  repetitionData,
  color,
  location,
}

/// Immutable snapshot of [AddTileDraft] — the single input to the request
/// mapper. Value-equality so tests can compare snapshots.
class AddTileDraftSnapshot {
  const AddTileDraftSnapshot({
    required this.type,
    required this.name,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.restrictionProfile,
    required this.isAutoRevisable,
    required this.priority,
    required this.splitCount,
    required this.color,
    required this.repetitionData,
    required this.calculatedEnd,
  });

  final AddTileType type;
  final String name;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final Location? location;
  final RestrictionProfile? restrictionProfile;
  final bool isAutoRevisable;
  final TilePriority priority;
  final int splitCount;
  final Color? color;
  final RepetitionData? repetitionData;

  /// Always `startTime + duration`; the wire `End` for both types (legacy
  /// behavior). Display-only for Fixed Blocks.
  final DateTime calculatedEnd;

  @override
  bool operator ==(Object other) =>
      other is AddTileDraftSnapshot &&
      other.type == type &&
      other.name == name &&
      other.duration == duration &&
      other.startTime == startTime &&
      other.endTime == endTime &&
      identical(other.location, location) &&
      identical(other.restrictionProfile, restrictionProfile) &&
      other.isAutoRevisable == isAutoRevisable &&
      other.priority == priority &&
      other.splitCount == splitCount &&
      other.color == color &&
      identical(other.repetitionData, repetitionData) &&
      other.calculatedEnd == calculatedEnd;

  @override
  int get hashCode => Object.hash(
        type,
        name,
        duration,
        startTime,
        endTime,
        identityHashCode(location),
        identityHashCode(restrictionProfile),
        isAutoRevisable,
        priority,
        splitCount,
        color,
        identityHashCode(repetitionData),
        calculatedEnd,
      );

  /// Diagnostics only. Deliberately omits the user-entered name (privacy:
  /// never serialize draft content into logs).
  @override
  String toString() => 'AddTileDraftSnapshot(type:$type,duration:$duration,'
      'hasDeadline:${endTime != null},priority:$priority,split:$splitCount)';
}

/// Widget-independent draft state for the Add Tile flow.
///
/// Owns shared + mode-specific values, validation, dirty state,
/// suggestion-application rules, and mode-switch preservation. Keeping this
/// out of the widget makes validation and switching unit-testable and gives
/// the shell a local notifier without a new app-wide bloc.
class AddTileDraft extends ChangeNotifier {
  AddTileDraft.flexible({
    required DateTime now,
    PreTile? preTile,
    String? name,
    Duration? duration,
    Location? location,
    DateTime? endTime,
    RestrictionProfile? restrictionProfile,
    bool? isAutoRevisable,
    TilePriority? priority,
    int? splitCount,
    Color? color,
    RepetitionData? repetitionData,
  }) : this._(
          type: AddTileType.flexible,
          now: now,
          preTile: preTile,
          name: name,
          duration: duration,
          location: location,
          endTime: endTime,
          restrictionProfile: restrictionProfile,
          isAutoRevisable: isAutoRevisable,
          priority: priority,
          splitCount: splitCount,
          color: color,
          repetitionData: repetitionData,
        );

  AddTileDraft.fixed({
    required DateTime now,
    PreTile? preTile,
    String? name,
    Duration? duration,
    Location? location,
    DateTime? endTime,
    RestrictionProfile? restrictionProfile,
    bool? isAutoRevisable,
    TilePriority? priority,
    int? splitCount,
    Color? color,
    RepetitionData? repetitionData,
  }) : this._(
          type: AddTileType.fixed,
          now: now,
          preTile: preTile,
          name: name,
          duration: duration,
          location: location,
          endTime: endTime,
          restrictionProfile: restrictionProfile,
          isAutoRevisable: isAutoRevisable,
          priority: priority,
          splitCount: splitCount,
          color: color,
          repetitionData: repetitionData,
        );

  AddTileDraft._({
    required AddTileType type,
    required DateTime now,
    PreTile? preTile,
    String? name,
    Duration? duration,
    Location? location,
    DateTime? endTime,
    RestrictionProfile? restrictionProfile,
    bool? isAutoRevisable,
    TilePriority? priority,
    int? splitCount,
    Color? color,
    RepetitionData? repetitionData,
  })  : _type = type,
        _name = name ?? preTile?.description ?? '',
        // Explicit value > prefill > type default. Flexible has NO default
        // duration (visibly required, never silently guessed); Fixed
        // defaults to 30 minutes only without prefill/suggestion.
        _duration = duration ??
            preTile?.duration ??
            (type == AddTileType.fixed
                ? const Duration(minutes: 30)
                : Duration.zero),
        _startTime = preTile?.startTime ?? now,
        _endTime = endTime ?? preTile?.endTime,
        _location = location ??
            (preTile != null ? preTile.location : Location.fromDefault()),
        _restrictionProfile = restrictionProfile,
        _isAutoRevisable = isAutoRevisable ?? true,
        _priority = priority ?? TilePriority.medium,
        _splitCount = splitCount ?? 1,
        _color = color,
        _repetitionData = repetitionData {
    // Baseline for the dirty check = initial/prefilled state.
    _initial = snapshot;
  }

  late AddTileDraftSnapshot _initial;
  final Set<_Field> _userEdited = {};
  bool _disposed = false;

  AddTileType _type;
  String _name;
  Duration _duration;
  DateTime _startTime;
  DateTime? _endTime;
  Location? _location;
  RestrictionProfile? _restrictionProfile;
  bool _isAutoRevisable;
  TilePriority _priority;
  int _splitCount;
  Color? _color;
  RepetitionData? _repetitionData;

  // ------------------------------------------------------------------
  // Read access
  // ------------------------------------------------------------------

  AddTileType get type => _type;
  String get name => _name;
  Duration get duration => _duration;
  DateTime get startTime => _startTime;
  DateTime? get endTime => _endTime;

  /// Nullable to mirror the legacy widget exactly (addTile.dart): the
  /// ghost `Location.fromDefault()` is held when no preTile is supplied, but
  /// a `PreTile` without a location yields `null` (not a ghost), which changes
  /// the wire `LocationIsVerified` field. Wire parity depends on this.
  Location? get location => _location;
  RestrictionProfile? get restrictionProfile => _restrictionProfile;
  bool get isAutoRevisable => _isAutoRevisable;
  TilePriority get priority => _priority;
  int get splitCount => _splitCount;
  Color? get color => _color;
  RepetitionData? get repetitionData => _repetitionData;

  /// Fixed Block end = start + duration, always derived (read-only in v1;
  /// API semantics remain start + duration).
  DateTime get calculatedEnd => _startTime.add(_duration);

  AddTileDraftSnapshot get snapshot => AddTileDraftSnapshot(
        type: _type,
        name: _name,
        duration: _duration,
        startTime: _startTime,
        endTime: _endTime,
        location: _location,
        restrictionProfile: _restrictionProfile,
        isAutoRevisable: _isAutoRevisable,
        priority: _priority,
        splitCount: _splitCount,
        color: _color,
        repetitionData: _repetitionData,
        calculatedEnd: calculatedEnd,
      );

  // ------------------------------------------------------------------
  // User mutation (marks a field as user-edited for the dirty check)
  // ------------------------------------------------------------------

  set name(String value) {
    _name = value;
    _userEdited.add(_Field.name);
    _notify();
  }

  /// User-driven duration change (picker / keyboard). App suggestions must
  /// go through [applySuggestedDuration] so they never count as edits.
  void setUserDuration(Duration value) {
    _duration = value;
    _userEdited.add(_Field.duration);
    _notify();
  }

  void setUserStartTime(DateTime value) {
    _startTime = value;
    _userEdited.add(_Field.startTime);
    _notify();
  }

  set endTime(DateTime? value) {
    _endTime = value;
    _userEdited.add(_Field.endTime);
    _notify();
  }

  void setLocation(Location value) {
    _location = value;
    _userEdited.add(_Field.location);
    _notify();
  }

  void setRestrictionProfile(RestrictionProfile? value) {
    _restrictionProfile = value;
    _userEdited.add(_Field.restrictionProfile);
    _notify();
  }

  void setAutoRevisable(bool value) {
    _isAutoRevisable = value;
    _userEdited.add(_Field.isAutoRevisable);
    _notify();
  }

  void setPriority(TilePriority value) {
    _priority = value;
    _userEdited.add(_Field.priority);
    _notify();
  }

  void setSplitCount(int value) {
    _splitCount = value;
    _userEdited.add(_Field.splitCount);
    _notify();
  }

  void setColor(Color? value) {
    _color = value;
    _userEdited.add(_Field.color);
    _notify();
  }

  void setRepetitionData(RepetitionData? value) {
    _repetitionData = value;
    _userEdited.add(_Field.repetitionData);
    _notify();
  }

  // ------------------------------------------------------------------
  // Suggestion application: never overwrite manual edits; stale
  // responses after disposal are ignored.
  // ------------------------------------------------------------------

  bool canAcceptSuggestion(AddTileSuggestedField field) {
    if (_disposed) return false;
    final f = switch (field) {
      AddTileSuggestedField.name => _Field.name,
      AddTileSuggestedField.duration => _Field.duration,
      AddTileSuggestedField.location => _Field.location,
      AddTileSuggestedField.endTime => _Field.endTime,
      AddTileSuggestedField.restrictionProfile => _Field.restrictionProfile,
    };
    return !_userEdited.contains(f);
  }

  /// Applies a debounced name-based duration suggestion. Returns `false`
  /// (and leaves the field untouched) when the user already edited duration
  /// or the draft was disposed.
  bool applySuggestedDuration(Duration value) {
    if (!canAcceptSuggestion(AddTileSuggestedField.duration)) return false;
    _duration = value;
    _notify();
    return true;
  }

  // ------------------------------------------------------------------
  // Validation — stable reason codes per the analytics schema
  // ------------------------------------------------------------------

  /// Field-id -> stable reason code. Legacy equivalence: name must be
  /// non-empty; duration must be > 0 minutes (legacy rejected
  /// `inMinutes <= 0`).
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (_name.trim().isEmpty) errors['name'] = 'name_empty';
    if (_duration.inMinutes <= 0) errors['duration'] = 'duration_invalid';
    return errors;
  }

  bool get isValid => validate().isEmpty;

  // ------------------------------------------------------------------
  // Dirty state: confirm discard only after a
  // meaningful USER edit — i.e. a user-edited field that differs from its
  // initial/prefilled value. Suggestion-applied values are not dirty.
  // ------------------------------------------------------------------

  bool get isDirty {
    final i = _initial;
    return (_userEdited.contains(_Field.name) && _name != i.name) ||
        (_userEdited.contains(_Field.duration) && _duration != i.duration) ||
        (_userEdited.contains(_Field.startTime) && _startTime != i.startTime) ||
        (_userEdited.contains(_Field.endTime) && _endTime != i.endTime) ||
        (_userEdited.contains(_Field.restrictionProfile) &&
            !identical(_restrictionProfile, i.restrictionProfile)) ||
        (_userEdited.contains(_Field.isAutoRevisable) &&
            _isAutoRevisable != i.isAutoRevisable) ||
        (_userEdited.contains(_Field.priority) && _priority != i.priority) ||
        (_userEdited.contains(_Field.splitCount) &&
            _splitCount != i.splitCount) ||
        (_userEdited.contains(_Field.repetitionData) &&
            !identical(_repetitionData, i.repetitionData)) ||
        (_userEdited.contains(_Field.color) && _color != i.color) ||
        (_userEdited.contains(_Field.location) &&
            !identical(_location, i.location));
  }

  bool get needsCloseConfirmation => isDirty;

  // ------------------------------------------------------------------
  // Type switching — deterministic, nothing silently discarded.
  // ------------------------------------------------------------------

  /// Characterized in `add_tile_request_mapping_baseline_test.dart`:
  /// `RepetitionData` maps identically for rigid and flexible payloads, so
  /// repeat semantics are identical across modes in v1.
  static const bool repeatSemanticsIdenticalAcrossModes = true;

  /// Preserve only when semantics are identical, otherwise the UI must confirm
  /// before clearing. Exposed as a decision so the shell can prompt; v1
  /// resolves to [RepeatSwitchDecision.preserve].
  RepeatSwitchDecision get repeatSwitchDecision {
    if (_repetitionData == null) return RepeatSwitchDecision.preserve;
    return repeatSemanticsIdenticalAcrossModes
        ? RepeatSwitchDecision.preserve
        : RepeatSwitchDecision.confirmBeforeClear;
  }

  void switchToFixed() {
    if (_type == AddTileType.fixed) return;
    _type = AddTileType.fixed;
    // Preserve duration if valid; otherwise adopt the 30-minute
    // Fixed default. This is an app-driven fill, not a user edit.
    if (_duration.inMinutes <= 0) {
      _duration = const Duration(minutes: 30);
    }
    // Mode-specific values (endTime, restriction, auto-revisable, priority,
    // split) go dormant but are retained and restore on switch-back.
    _notify();
  }

  void switchToFlexible() {
    if (_type == AddTileType.flexible) return;
    _type = AddTileType.flexible;
    // Dormant flexible-only values are restored by existing on them —
    // they were never discarded.
    _notify();
  }

  // ------------------------------------------------------------------

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
