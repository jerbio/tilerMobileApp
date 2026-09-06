// Phase 2.2 — Preferred time day-part mapping helper.
//
// The Flexible form's "Preferred time" control offers four simple choices:
//   Anytime / Morning / Afternoon / Evening
//
// A non-Anytime choice maps to a [RestrictionProfile] with exactly one
// all-week window (7 days of week, same start/duration every day, enabled,
// default timezone). The wire payload is what the request mapper ships via
// `RestrictionProfile.toRestrictionWeekConfig()` (Start/End as
// `DateFormat.jm()`, Index per weekday) — the payload-parity tests pin it.
//
// The inverse mapping only recognizes profiles built from these exact
// windows. Anything else (named work/personal profiles, custom time
// restrictions, server-suggested profiles) is "advanced" and is NEVER
// replaced by a simple day-part selection — `applyPreferredTimeSelection`
// preserves it. Advanced profiles change through the advanced editor
// (later phase), never silently from this simple control.
//
// Day-part time windows are canonical app values (local time); the legacy
// flow only handled day-part strings server-side, so these windows are the
// client-side definition pinned by the parity tests.
library;

import 'package:flutter/material.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The four simple Preferred time choices offered by the control.
enum PreferredTimeOfDay { anytime, morning, afternoon, evening }

/// Canonical day-part windows: start of day-part (local time).
const Map<PreferredTimeOfDay, TimeOfDay> preferredTimeStart = {
  PreferredTimeOfDay.morning: TimeOfDay(hour: 6, minute: 0),
  PreferredTimeOfDay.afternoon: TimeOfDay(hour: 12, minute: 0),
  PreferredTimeOfDay.evening: TimeOfDay(hour: 17, minute: 0),
};

/// Canonical day-part windows: length of day-part.
/// Morning 06:00–12:00, Afternoon 12:00–17:00, Evening 17:00–22:00.
const Map<PreferredTimeOfDay, Duration> preferredTimeDuration = {
  PreferredTimeOfDay.morning: Duration(hours: 6),
  PreferredTimeOfDay.afternoon: Duration(hours: 5),
  PreferredTimeOfDay.evening: Duration(hours: 5),
};

/// Builds the [RestrictionProfile] payload for a simple day-part choice.
///
/// `anytime` maps to `null` — the legacy "Anytime" state is the ABSENCE of a
/// restriction profile (the request mapper then ships `isRestricted='false'`
/// and no `RestrictiveWeek`, exactly as the legacy flow did).
///
/// Each non-Anytime part produces one enabled profile: all 7 weekdays carry
/// the part's window (start + duration on the [RestrictionTimeLine], weekday
/// on the [RestrictionDay]); `timeZone` stays the default `'utc'` and the
/// profile gets a fresh id (like every locally constructed profile).
RestrictionProfile? restrictionProfileForPreferredTime(
    PreferredTimeOfDay part) {
  if (part == PreferredTimeOfDay.anytime) return null;
  final TimeOfDay start = preferredTimeStart[part]!;
  final Duration duration = preferredTimeDuration[part]!;
  final List<RestrictionDay?> days = <RestrictionDay?>[];
  for (int i = 0; i < 7; i++) {
    days.add(
      RestrictionDay(
        weekday: i,
        restrictionTimeLine: RestrictionTimeLine(
          start: start,
          duration: duration,
          weekDay: i,
        ),
      ),
    );
  }
  return RestrictionProfile(daySelection: days);
}

/// Inverse mapping: which simple day-part does [profile] represent?
///
/// Returns [PreferredTimeOfDay.anytime] for the "no effective restriction"
/// states (null profile, disabled profile, or a profile with no days — the
/// request mapper ships none of them as restricted).
///
/// Returns the part only for an EXACT simple profile: enabled, all 7
/// weekdays populated, every day matching the part's window. Returns `null`
/// for advanced/custom profiles (named work/personal hours, custom
/// per-day windows, partial weeks, server-suggested profiles) — the UI must
/// not present those as one of the four simple choices.
PreferredTimeOfDay? preferredTimeOfProfile(RestrictionProfile? profile) {
  if (profile == null || !profile.isEnabled || !profile.isAnyDayNotNull) {
    return PreferredTimeOfDay.anytime;
  }
  const List<PreferredTimeOfDay> parts = [
    PreferredTimeOfDay.morning,
    PreferredTimeOfDay.afternoon,
    PreferredTimeOfDay.evening,
  ];
  for (final PreferredTimeOfDay part in parts) {
    final TimeOfDay start = preferredTimeStart[part]!;
    final Duration duration = preferredTimeDuration[part]!;
    var matches = true;
    for (int i = 0; i < 7; i++) {
      final RestrictionDay? day = profile.daySelection[i];
      final RestrictionTimeLine? line = day?.restrictionTimeLine;
      if (day == null ||
          line == null ||
          line.start != start ||
          line.duration != duration ||
          day.weekday != i) {
        matches = false;
        break;
      }
    }
    if (matches) return part;
  }
  return null;
}

/// The profile to store after the user selects [part] while [current] is the
/// draft's current profile.
///
/// - `current` is absent/Anytime/simple → the selection applies
///   (`anytime` → `null`, part → that part's payload).
/// - `current` is advanced/custom (not expressible as one of the four
///   choices) → it is PRESERVED, returned unchanged. A simple day-part
///   selection must never silently overwrite advanced values; changing them
///   requires the advanced editor (later phase).
RestrictionProfile? applyPreferredTimeSelection(
  RestrictionProfile? current,
  PreferredTimeOfDay part,
) {
  if (current != null && preferredTimeOfProfile(current) == null) {
    return current;
  }
  return restrictionProfileForPreferredTime(part);
}

/// Localized display label for a day part.
///
/// Takes [AppLocalizations] rather than a `BuildContext` so it stays pure and
/// callable from unit tests and from other flows (D29).
String preferredTimeLabel(AppLocalizations l10n, PreferredTimeOfDay part) {
  switch (part) {
    case PreferredTimeOfDay.anytime:
      return l10n.anytime;
    case PreferredTimeOfDay.morning:
      return l10n.morning;
    case PreferredTimeOfDay.afternoon:
      return l10n.afternoon;
    case PreferredTimeOfDay.evening:
      return l10n.evening;
  }
}
