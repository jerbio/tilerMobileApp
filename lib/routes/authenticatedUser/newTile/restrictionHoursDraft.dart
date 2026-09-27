// Time restrictions — the contract and the hours editor's state (Step 6.1,
// D67–D73).
//
// Two things live here, both pure Dart:
//
//   * [TimeRestrictionChoice] — which row of the Time restrictions screen a
//     tile's profile stands for (Anytime / Work / Personal / Custom), and
//     [describeRestrictionProfile], the grouped summary the rows print.
//   * [RestrictionHoursDraft] — the Custom hours editor's seven rows, with
//     the legacy editor's semantics where the product kept them (D69: 9:00 AM
//     – 6:00 PM on enable, a disabled day is `null`, all disabled is no
//     profile). No window is invalid (D75): an end BEFORE its start wraps
//     into the next day — Monday 9 PM – 2 AM ends Tuesday 2 AM — so night
//     shifts are expressible; a window never covers more than one day. An
//     end EQUAL to its start is the whole day (D74) — 24 hours on the wire.
//     Durations are always kept in (0, 24 h]; the legacy editor stored the
//     raw end - start, so an overnight window arrived as a NEGATIVE
//     duration, which the reader normalises.
//
// The hours editor's request/result contract lives here too, so the Time
// restrictions screen and the editor depend on this file, not on each other.
//
// `daySelection` is Sunday-first (0..6), the same indices the server and
// `RestrictionDay.weekday` use.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, TimeOfDay;
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';

/// The rows of the Time restrictions screen.
enum TimeRestrictionChoice {
  anytime,
  work,
  personal,
  custom;

  /// Which row [profile] stands for. A named profile is matched by id first
  /// (the draft holds the very object the source loaded), then by hours (a
  /// tile loaded from the server carries its own copy). A profile the mapper
  /// would not send — disabled or empty — is Anytime (D73).
  static TimeRestrictionChoice of(
    RestrictionProfile? profile, {
    required RestrictionProfile? work,
    required RestrictionProfile? personal,
  }) {
    if (!isUsableRestrictionProfile(profile)) return anytime;
    if (_isNamed(profile!, work)) return TimeRestrictionChoice.work;
    if (_isNamed(profile, personal)) return TimeRestrictionChoice.personal;
    return custom;
  }

  static bool _isNamed(RestrictionProfile profile, RestrictionProfile? named) {
    if (!isUsableRestrictionProfile(named)) return false;
    final String? id = named!.id;
    if (id != null && id.isNotEmpty && id == profile.id) return true;
    return sameRestrictionHours(profile, named);
  }
}

/// Whether two profiles spell the same hours — by CLOCKS, not by stored
/// duration. `RestrictionProfile.isEquivalent` compares durations, and the
/// legacy editor stored an overnight window as a negative one (9 PM – 2 AM
/// as -19 h) where this model stores +5 h; both mean the same hours (D75).
bool sameRestrictionHours(RestrictionProfile? a, RestrictionProfile? b) {
  final List<RestrictionHoursDay> x = RestrictionHoursDraft.fromProfile(a).days;
  final List<RestrictionHoursDay> y = RestrictionHoursDraft.fromProfile(b).days;
  for (int i = 0; i < 7; i++) {
    if (x[i].enabled != y[i].enabled) return false;
    if (x[i].enabled && x[i] != y[i]) return false;
  }
  return true;
}

/// What the screen asks of the hours editor: the hours to start from and,
/// in profile mode, WHICH shared profile a save writes (D67). Ad-hoc mode
/// has no [profileType].
class HoursEditorRequest {
  const HoursEditorRequest({required this.seed, this.profileType});

  final RestrictionProfile? seed;
  final NamedRestrictionProfileType? profileType;

  bool get isProfileMode => profileType != null;
}

/// The editor's answer. A null [profile] means every day was switched off —
/// Anytime. Backing out of the editor returns no result at all.
class HoursEditorResult {
  const HoursEditorResult(this.profile);

  final RestrictionProfile? profile;
}

typedef OpenHoursEditor = Future<HoursEditorResult?> Function(
    BuildContext context, HoursEditorRequest request);

/// A profile the request mapper would actually send: enabled with at least
/// one day. Anything else means Anytime on the wire.
bool isUsableRestrictionProfile(RestrictionProfile? profile) =>
    profile != null && profile.isEnabled && profile.isAnyDayNotNull;

/// A run of consecutive enabled days sharing one window — "Mon – Fri ·
/// 9:00 AM – 6:00 PM" before formatting.
@immutable
class RestrictionHoursGroup {
  const RestrictionHoursGroup(
      {required this.days, required this.start, required this.end});

  /// Sunday-first weekday indices, ascending and consecutive.
  final List<int> days;
  final TimeOfDay start;
  final TimeOfDay end;

  /// D74: equal start and end is the whole day.
  bool get isAllDay => start == end;

  /// D75: the end is on the following day.
  bool get wrapsToNextDay =>
      RestrictionHoursDay._minutes(end) < RestrictionHoursDay._minutes(start);
}

/// Groups a profile's enabled days by window, in weekday order. Empty for a
/// profile that is null, disabled or has no days.
List<RestrictionHoursGroup> describeRestrictionProfile(
    RestrictionProfile? profile) {
  if (!isUsableRestrictionProfile(profile))
    return const <RestrictionHoursGroup>[];
  final List<RestrictionHoursGroup> groups = <RestrictionHoursGroup>[];
  List<int> run = <int>[];
  TimeOfDay? runStart;
  TimeOfDay? runEnd;
  void flush() {
    if (run.isNotEmpty) {
      groups.add(RestrictionHoursGroup(
          days: List<int>.unmodifiable(run), start: runStart!, end: runEnd!));
    }
    run = <int>[];
  }

  for (int i = 0; i < 7 && i < profile!.daySelection.length; i++) {
    final RestrictionHoursDay? row = RestrictionHoursDay._fromRestrictionDay(
        profile.daySelection[i],
        weekday: i);
    if (row == null) {
      flush();
      continue;
    }
    // A gap is always a null row, which flushed above; consecutiveness is
    // therefore implied and only the window is compared.
    final bool continues =
        run.isNotEmpty && row.start == runStart && row.end == runEnd;
    if (!continues) {
      flush();
      runStart = row.start;
      runEnd = row.end;
    }
    run.add(i);
  }
  flush();
  return groups;
}

/// The quick presets on the Custom hours screen. Shortcuts that write the
/// seven rows; nothing is stored (D69).
enum RestrictionHoursPreset {
  weekdays9to6,
  weekdays9to5,
  evenings6to10,
  weekends10to4;

  static const List<int> _weekdays = <int>[1, 2, 3, 4, 5];
  static const List<int> _weekend = <int>[0, 6];
  static const List<int> _every = <int>[0, 1, 2, 3, 4, 5, 6];

  List<int> get days => switch (this) {
        weekdays9to6 || weekdays9to5 => _weekdays,
        evenings6to10 => _every,
        weekends10to4 => _weekend,
      };

  TimeOfDay get start => switch (this) {
        weekdays9to6 || weekdays9to5 => const TimeOfDay(hour: 9, minute: 0),
        evenings6to10 => const TimeOfDay(hour: 18, minute: 0),
        weekends10to4 => const TimeOfDay(hour: 10, minute: 0),
      };

  TimeOfDay get end => switch (this) {
        weekdays9to6 => const TimeOfDay(hour: 18, minute: 0),
        weekdays9to5 => const TimeOfDay(hour: 17, minute: 0),
        evenings6to10 => const TimeOfDay(hour: 22, minute: 0),
        weekends10to4 => const TimeOfDay(hour: 16, minute: 0),
      };
}

/// One row of the editor. Disabled rows keep their hours so a toggle back
/// restores them; only enabled rows reach the profile.
@immutable
class RestrictionHoursDay {
  const RestrictionHoursDay(
      {required this.enabled, required this.start, required this.end});

  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  RestrictionHoursDay copyWith(
          {bool? enabled, TimeOfDay? start, TimeOfDay? end}) =>
      RestrictionHoursDay(
          enabled: enabled ?? this.enabled,
          start: start ?? this.start,
          end: end ?? this.end);

  /// D74: equal start and end means all day — a 24-hour window.
  bool get isAllDay => start == end;

  /// D75: an end before its start is on the FOLLOWING day (Monday 9 PM –
  /// 2 AM ends Tuesday 2 AM). Never more than one day.
  bool get wrapsToNextDay => _minutes(end) < _minutes(start);

  /// The window's length, always in (0, 24 h]: (end - start) mod 24 h, with
  /// equal times as the whole day (D74).
  Duration get window {
    final int minutes = (_minutes(end) - _minutes(start)) % _dayMinutes;
    return Duration(minutes: minutes == 0 ? _dayMinutes : minutes);
  }

  static const int _dayMinutes = 24 * 60;

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// The legacy editor's reading of a server day: start + duration → end.
  static RestrictionHoursDay? _fromRestrictionDay(RestrictionDay? day,
      {required int weekday}) {
    final RestrictionTimeLine? line = day?.restrictionTimeLine;
    final TimeOfDay? start = line?.start;
    final Duration? duration = line?.duration;
    if (day == null || start == null || duration == null) return null;
    // Clock arithmetic mod 24 h on the TOTAL, so a 24-hour window comes
    // back as an end equal to its start (D74) and a legacy NEGATIVE
    // duration (-19 h for 9 PM – 2 AM) lands on the clock the user meant
    // (D75). Dart's `%` is non-negative for a positive modulus.
    final int endMinutes = (_minutes(start) + duration.inMinutes) % _dayMinutes;
    return RestrictionHoursDay(
        enabled: true,
        start: start,
        end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60));
  }

  RestrictionDay _toRestrictionDay(int weekday) => RestrictionDay(
      weekday: weekday,
      restrictionTimeLine: RestrictionTimeLine(
          start: start, duration: window, weekDay: weekday));

  @override
  bool operator ==(Object other) =>
      other is RestrictionHoursDay &&
      other.enabled == enabled &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(enabled, start, end);
}

/// The Custom hours editor's state: seven rows, a copy clipboard, validity
/// and dirty tracking. Notifies once per edit.
class RestrictionHoursDraft extends ChangeNotifier {
  RestrictionHoursDraft.fromProfile(RestrictionProfile? profile)
      : _seed = profile,
        _days = List<RestrictionHoursDay>.generate(7, (int i) {
          final RestrictionDay? day =
              profile != null && i < profile.daySelection.length
                  ? profile.daySelection[i]
                  : null;
          return RestrictionHoursDay._fromRestrictionDay(day, weekday: i) ??
              const RestrictionHoursDay(
                  enabled: false, start: defaultStart, end: defaultEnd);
        }) {
    _loaded = List<RestrictionHoursDay>.unmodifiable(_days);
  }

  /// D69: the legacy `_DayOfWeekRestriction` defaults.
  static const TimeOfDay defaultStart = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay defaultEnd = TimeOfDay(hour: 18, minute: 0);

  final RestrictionProfile? _seed;
  final List<RestrictionHoursDay> _days;
  late final List<RestrictionHoursDay> _loaded;
  int? _copiedDay;

  /// Sunday-first.
  List<RestrictionHoursDay> get days =>
      List<RestrictionHoursDay>.unmodifiable(_days);

  bool get hasEnabledDay => _days.any((RestrictionHoursDay d) => d.enabled);

  bool get isDirty {
    for (int i = 0; i < 7; i++) {
      if (_days[i] != _loaded[i]) return true;
    }
    return false;
  }

  /// The preset the rows currently spell, or null (D69: derived, not stored).
  RestrictionHoursPreset? get matchingPreset {
    for (final RestrictionHoursPreset p in RestrictionHoursPreset.values) {
      if (_matches(p)) return p;
    }
    return null;
  }

  bool _matches(RestrictionHoursPreset p) {
    for (int i = 0; i < 7; i++) {
      final bool on = p.days.contains(i);
      if (_days[i].enabled != on) return false;
      if (on && (_days[i].start != p.start || _days[i].end != p.end)) {
        return false;
      }
    }
    return true;
  }

  /// The day whose hours are on the clipboard (D71), or null.
  int? get copiedDay => _copiedDay;

  void setEnabled(int day, bool enabled) =>
      _edit(day, _days[day].copyWith(enabled: enabled));

  void setStart(int day, TimeOfDay start) =>
      _edit(day, _days[day].copyWith(start: start));

  void setEnd(int day, TimeOfDay end) =>
      _edit(day, _days[day].copyWith(end: end));

  void applyPreset(RestrictionHoursPreset preset) {
    for (int i = 0; i < 7; i++) {
      final bool on = preset.days.contains(i);
      _days[i] = on
          ? RestrictionHoursDay(
              enabled: true, start: preset.start, end: preset.end)
          : _days[i].copyWith(enabled: false);
    }
    notifyListeners();
  }

  /// Tap on the source again clears the clipboard.
  void copyDay(int day) {
    _copiedDay = _copiedDay == day ? null : day;
    notifyListeners();
  }

  /// Writes the copied hours onto [day] and enables it. A no-op without a
  /// clipboard or onto the source itself.
  void pasteTo(int day) {
    final int? from = _copiedDay;
    if (from == null || from == day) return;
    _edit(
        day,
        _days[day].copyWith(
            enabled: true, start: _days[from].start, end: _days[from].end));
  }

  void _edit(int day, RestrictionHoursDay value) {
    _days[day] = value;
    notifyListeners();
  }

  /// The profile these rows spell: null when no day is enabled (Anytime);
  /// otherwise a NEW object carrying the seed's id and time zone — the seed
  /// itself is never mutated — with `isEnabled` true. No window is invalid
  /// (D75), so this always succeeds.
  RestrictionProfile? toProfile() {
    if (!hasEnabledDay) return null;
    final RestrictionProfile out =
        RestrictionProfile(daySelection: <RestrictionDay?>[
      for (int i = 0; i < 7; i++)
        if (_days[i].enabled) _days[i]._toRestrictionDay(i) else null,
    ]);
    final RestrictionProfile? seed = _seed;
    if (seed != null) {
      out.id = seed.id;
      out.timeZone = seed.timeZone;
      out.userId = seed.userId;
    }
    return out;
  }
}
