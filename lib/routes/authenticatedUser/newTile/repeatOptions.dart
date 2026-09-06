// Step 4.2 — the Repeat option model.
//
// The picker's state is `(RepetitionFrequency, Set<int> days)`, and the rows a
// user sees are VIEWS onto it. Keeping the mapping pure has a useful side
// effect: the mockup's contradiction — active weekday chips beside a selected
// "Does not repeat" — is not expressible, because chips are derived from the
// selected option rather than held alongside it.
//
// Decisions encoded here:
//   D22  Yearly is kept, though the Repeat mockup omits it.
//   D23  "Weekdays" is a PRESET (weekly + Mon-Fri), not a frequency. The
//        mockup's "Custom" row is dropped: Weekly already exposes day
//        selection, so Custom would be the same state under a second name and
//        the two would be indistinguishable.
//   D25  `RepeatWeeklyData` indices are 0-based from SUNDAY, so Mon-Fri is
//        {1,2,3,4,5} and the captured payload "1,3,5" is Mon/Wed/Fri.
//   D26  A range is offered; the default comes from `RepetitionData` itself.
import 'package:characters/characters.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The rows the Repeat picker offers, in display order.
enum RepeatOption { doesNotRepeat, daily, weekdays, weekly, monthly, yearly }

/// Mon-Fri, 0-based from Sunday (D25). The Weekdays preset is exactly this
/// set — no more, no less.
const Set<int> weekdayPresetDays = <int>{1, 2, 3, 4, 5};

/// Label functions take [AppLocalizations] rather than reading it from a
/// `BuildContext`, so they stay pure, stay unit-testable without pumping a
/// widget, and remain usable from any flow (D29).
String repeatOptionLabel(AppLocalizations l10n, RepeatOption option) {
  switch (option) {
    case RepeatOption.doesNotRepeat:
      return l10n.addTileRepeatNever;
    case RepeatOption.daily:
      return l10n.daily;
    case RepeatOption.weekdays:
      return l10n.addTileRepeatWeekdays;
    case RepeatOption.weekly:
      return l10n.weekly;
    case RepeatOption.monthly:
      return l10n.monthly;
    case RepeatOption.yearly:
      return l10n.yearly;
  }
}

/// Whether [option] has a day dimension at all. Chips are hidden for the rest,
/// so a stale selection can never sit beside an option it means nothing for.
bool optionHasDays(RepeatOption option) =>
    option == RepeatOption.weekdays || option == RepeatOption.weekly;

// NOTE: there is deliberately no `optionDaysAreEditable`. An earlier revision
// made the Weekdays chips read-only, which on device read as "cannot unselect
// the week days" — an inert control with nothing to say why. Chips are now
// always editable: touching one while on Weekdays drops the selection to
// Weekly and applies the edit, and landing back on exactly Mon-Fri returns to
// Weekdays. The preset stays a shortcut instead of becoming a dead end.

/// Short chip label for a 0-based-from-Sunday index.
///
/// Derived from the localized full name rather than a hardcoded letter table:
/// the English initials happen to be the first letters, but that is a property
/// of English, not of weekday names generally.
String weekdayShortLabel(AppLocalizations l10n, int index) {
  final String full = weekdayFullLabel(l10n, index);
  return full.isEmpty ? '' : full.characters.first.toUpperCase();
}

/// Full weekday name, for assistive technology — short labels repeat within a
/// week in many languages ('S'/'T' in English), so they cannot carry the
/// meaning alone.
String weekdayFullLabel(AppLocalizations l10n, int index) {
  switch (index % 7) {
    case 0:
      return l10n.sunday;
    case 1:
      return l10n.monday;
    case 2:
      return l10n.tuesday;
    case 3:
      return l10n.wednesday;
    case 4:
      return l10n.thursday;
    case 5:
      return l10n.friday;
    default:
      return l10n.saturday;
  }
}

/// The recurrence end applied when the user does not choose one.
///
/// Mirrors the window `RepetitionData`'s constructor would pick — 180 days,
/// or 3650 for yearly — but anchored to the supplied [now] so the value is
/// deterministic rather than tied to a wall clock.
///
/// The numbers are duplicated from `RepetitionData` deliberately: the picker
/// must SHOW the same window it will send, and reading it back out of a probe
/// instance would be indirect without being any safer. `defaultWindowFor` is
/// the one place to change if the constructor's defaults ever move.
DateTime defaultRepetitionEnd(RepetitionFrequency frequency, DateTime now) =>
    now.add(defaultWindowFor(frequency));

Duration defaultWindowFor(RepetitionFrequency frequency) =>
    frequency == RepetitionFrequency.yearly
        ? const Duration(days: 3650)
        : const Duration(days: 180);

/// Which row [repetition] currently represents.
///
/// An absent, disabled, or `none` repetition is "Does not repeat". Weekly
/// reads back as Weekdays only for EXACTLY the Mon-Fri set; anything else —
/// including Mon-Fri plus a weekend day — is Weekly.
RepeatOption repeatOptionOf(RepetitionData? repetition) {
  if (repetition == null ||
      !repetition.isEnabled ||
      repetition.frequency == RepetitionFrequency.none) {
    return RepeatOption.doesNotRepeat;
  }
  switch (repetition.frequency) {
    case RepetitionFrequency.daily:
      return RepeatOption.daily;
    case RepetitionFrequency.weekly:
      final Set<int> days = repetition.weeklyRepetition ?? const <int>{};
      return _sameDays(days, weekdayPresetDays)
          ? RepeatOption.weekdays
          : RepeatOption.weekly;
    case RepetitionFrequency.monthly:
      return RepeatOption.monthly;
    case RepetitionFrequency.yearly:
      return RepeatOption.yearly;
    case RepetitionFrequency.none:
      return RepeatOption.doesNotRepeat;
  }
}

bool _sameDays(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);

/// Builds the [RepetitionData] for a chosen row.
///
/// Returns `null` for "Does not repeat" — the absence of a repetition, not a
/// disabled one, so the draft simply carries no recurrence.
///
/// [days] is honoured only for Weekly. Weekdays substitutes its fixed preset,
/// and the day-less frequencies drop it entirely, so chips left over from a
/// previous selection can never reach the wire.
RepetitionData? buildRepetition({
  required RepeatOption option,
  required Set<int> days,
  required DateTime now,
  DateTime? end,
}) {
  if (option == RepeatOption.doesNotRepeat) return null;

  final RepetitionFrequency frequency = switch (option) {
    RepeatOption.daily => RepetitionFrequency.daily,
    RepeatOption.weekdays => RepetitionFrequency.weekly,
    RepeatOption.weekly => RepetitionFrequency.weekly,
    RepeatOption.monthly => RepetitionFrequency.monthly,
    RepeatOption.yearly => RepetitionFrequency.yearly,
    RepeatOption.doesNotRepeat => RepetitionFrequency.none,
  };

  final Set<int> effectiveDays = switch (option) {
    RepeatOption.weekdays => Set<int>.from(weekdayPresetDays),
    RepeatOption.weekly => Set<int>.from(days),
    _ => <int>{},
  };

  return RepetitionData(
    frequency: frequency,
    weeklyRepetition: effectiveDays,
    repetitionEnd: end ?? defaultRepetitionEnd(frequency, now),
    isEnabled: true,
  );
}
