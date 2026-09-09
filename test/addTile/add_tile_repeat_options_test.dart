// Step 4.2 — the Repeat option model.
//
// Decisions this encodes:
//   D22  Yearly is kept, even though the mockup omits it.
//   D23  "Weekdays" is a PRESET (weekly + Mon-Fri), not a frequency, and the
//        mockup's "Custom" row is dropped — Weekly already exposes day
//        selection, so Custom would be the same state under another name.
//   D25  `RepeatWeeklyData` indices are 0-based from SUNDAY.
//   D26  A range is offered; the default is now + 180 days, except yearly,
//        which `RepetitionData` defaults to now + 3650.
//
// The picker's state is `(RepetitionFrequency, Set<int> days)` and the six
// rows are views onto it. Keeping that mapping pure means the mockup's
// contradiction — active weekday chips beside a selected "Does not repeat" —
// cannot be represented at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repeatOptions.dart';
import 'l10n_fixture.dart';

final DateTime now = DateTime(2026, 9, 6, 9, 0);

RepetitionData repetition(RepetitionFrequency f, {Set<int>? days}) =>
    RepetitionData(
      frequency: f,
      weeklyRepetition: days,
      repetitionEnd: DateTime(2026, 12, 31),
      isEnabled: true,
    );

void main() {
  group('The row set (D22, D52)', () {
    test('offers five rows: no Weekdays, no Custom, Yearly kept', () {
      // Weekdays was a PRESET for weekly + Mon-Fri, not a frequency, and one
      // tap apart from Weekly it produced an identical state. There is now
      // exactly one way to say weekly (D52).
      expect(RepeatOption.values, [
        RepeatOption.doesNotRepeat,
        RepeatOption.daily,
        RepeatOption.weekly,
        RepeatOption.monthly,
        RepeatOption.yearly,
      ]);
    });

    test('labels avoid engine wording', () {
      expect(repeatOptionLabel(testL10n, RepeatOption.doesNotRepeat),
          'Does not repeat');
      expect(repeatOptionLabel(testL10n, RepeatOption.weekly), 'Weekly');
      expect(repeatOptionLabel(testL10n, RepeatOption.yearly), 'Yearly');
    });
  });

  group('Option -> repetition', () {
    test('Does not repeat produces no repetition at all', () {
      expect(
        buildRepetition(
            option: RepeatOption.doesNotRepeat, days: const {}, now: now),
        isNull,
      );
    });

    test('Weekly with NO days chosen carries no days (D52)', () {
      // An empty selection is a real answer: weekly, no particular day. The
      // mapper omits `RepeatWeeklyData` entirely for it, so the backend
      // decides — which is not the same as pre-ticking Mon-Fri on the user's
      // behalf and sending five choices they never made.
      final built = buildRepetition(
          option: RepeatOption.weekly, days: const {}, now: now)!;
      expect(built.frequency, RepetitionFrequency.weekly);
      expect(built.weeklyRepetition, isEmpty);
      expect(built.isEnabled, isTrue);
    });

    test('Weekly carries the user-selected days', () {
      final built = buildRepetition(
          option: RepeatOption.weekly, days: const {1, 3, 5}, now: now)!;
      expect(built.frequency, RepetitionFrequency.weekly);
      expect(built.weeklyRepetition, <int>{1, 3, 5});
    });

    test('day-less frequencies carry no weekly data', () {
      for (final option in [
        RepeatOption.daily,
        RepeatOption.monthly,
        RepeatOption.yearly
      ]) {
        final built =
            buildRepetition(option: option, days: const {1, 3}, now: now)!;
        expect(built.weeklyRepetition, isEmpty,
            reason: '$option has no day dimension, so stale chips must not '
                'reach the wire');
      }
    });

    test('each option maps to its frequency', () {
      expect(
          buildRepetition(option: RepeatOption.daily, days: const {}, now: now)!
              .frequency,
          RepetitionFrequency.daily);
      expect(
          buildRepetition(
                  option: RepeatOption.monthly, days: const {}, now: now)!
              .frequency,
          RepetitionFrequency.monthly);
      expect(
          buildRepetition(
                  option: RepeatOption.yearly, days: const {}, now: now)!
              .frequency,
          RepetitionFrequency.yearly);
    });
  });

  group('Repetition -> option', () {
    test('absent or disabled reads as Does not repeat', () {
      expect(repeatOptionOf(null), RepeatOption.doesNotRepeat);
      final disabled = RepetitionData(frequency: RepetitionFrequency.weekly);
      expect(disabled.isEnabled, isFalse);
      expect(repeatOptionOf(disabled), RepeatOption.doesNotRepeat);
    });

    test('EVERY weekly day set reads back as Weekly (D52)', () {
      // Mon-Fri used to read back as a separate `weekdays` row, which meant
      // the same frequency answered to two different names depending on the
      // days. One frequency, one row.
      for (final Set<int> days in <Set<int>>[
        <int>{},
        <int>{1, 3, 5},
        <int>{1, 2, 3, 4, 5},
        <int>{1, 2, 3, 4, 5, 6},
        <int>{0, 6},
      ]) {
        expect(
          repeatOptionOf(repetition(RepetitionFrequency.weekly, days: days)),
          RepeatOption.weekly,
          reason: '$days must read as Weekly',
        );
      }
    });

    test('the other frequencies read back as themselves', () {
      expect(repeatOptionOf(repetition(RepetitionFrequency.daily)),
          RepeatOption.daily);
      expect(repeatOptionOf(repetition(RepetitionFrequency.monthly)),
          RepeatOption.monthly);
      expect(repeatOptionOf(repetition(RepetitionFrequency.yearly)),
          RepeatOption.yearly);
      expect(repeatOptionOf(repetition(RepetitionFrequency.none)),
          RepeatOption.doesNotRepeat);
    });

    test('every option round-trips', () {
      for (final option in RepeatOption.values) {
        final Set<int> days =
            option == RepeatOption.weekly ? const {1, 3, 5} : const {};
        final built = buildRepetition(option: option, days: days, now: now);
        expect(repeatOptionOf(built), option, reason: '$option must survive');
      }
    });

    test('Weekly round-trips with no days too (D52)', () {
      // The default state. It has to survive the round trip, or reopening
      // the picker would silently move the user to another row.
      final built = buildRepetition(
          option: RepeatOption.weekly, days: const {}, now: now);
      expect(repeatOptionOf(built), RepeatOption.weekly);
      expect(built!.weeklyRepetition, isEmpty);
    });
  });

  group('Which rows show day chips', () {
    test('only Weekly has a day dimension', () {
      expect(optionHasDays(RepeatOption.weekly), isTrue);
      for (final option in [
        RepeatOption.doesNotRepeat,
        RepeatOption.daily,
        RepeatOption.monthly,
        RepeatOption.yearly,
      ]) {
        expect(optionHasDays(option), isFalse);
      }
    });

    test('the chosen days reach the repetition verbatim (D52)', () {
      // No preset to edit away from any more: whatever is ticked is what is
      // sent, including a set that happens to be Mon-Fri.
      final built = buildRepetition(
          option: RepeatOption.weekly, days: const {2, 3, 4, 5}, now: now);
      expect(repeatOptionOf(built), RepeatOption.weekly);
      expect(built!.weeklyRepetition, <int>{2, 3, 4, 5});
    });
  });

  group('Default range (D26)', () {
    test('most frequencies default to now + 180 days', () {
      for (final f in [
        RepetitionFrequency.daily,
        RepetitionFrequency.weekly,
        RepetitionFrequency.monthly,
      ]) {
        expect(defaultRepetitionEnd(f, now), now.add(const Duration(days: 180)),
            reason: '$f');
      }
    });

    test('yearly defaults to now + 3650 days', () {
      // RepetitionData gives yearly a far longer window; the range control has
      // to show that rather than assume 180.
      expect(defaultRepetitionEnd(RepetitionFrequency.yearly, now),
          now.add(const Duration(days: 3650)));
    });

    test('a built repetition carries the default when none is supplied', () {
      final built = buildRepetition(
          option: RepeatOption.weekly, days: const {1}, now: now)!;
      expect(built.repetitionEnd, isNotNull);
    });

    test('an explicit range is kept', () {
      final built = buildRepetition(
        option: RepeatOption.weekly,
        days: const {1},
        now: now,
        end: DateTime(2026, 12, 31),
      )!;
      expect(built.repetitionEnd, DateTime(2026, 12, 31));
    });
  });

  group('Day labels start on Sunday (D25)', () {
    test('index 0 is Sunday and 6 is Saturday', () {
      expect(weekdayShortLabel(testL10n, 0), 'S');
      expect(weekdayShortLabel(testL10n, 1), 'M');
      expect(weekdayShortLabel(testL10n, 6), 'S');
      expect(weekdayFullLabel(testL10n, 0), 'Sunday');
      expect(weekdayFullLabel(testL10n, 1), 'Monday');
      expect(weekdayFullLabel(testL10n, 6), 'Saturday');
    });
  });
}
