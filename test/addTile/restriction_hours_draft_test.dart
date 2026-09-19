// Step 6.1 — the Time restrictions contract and the hours editor's state
// model (D67–D73). Pure Dart: nothing here pumps a widget.
//
// The model mirrors the legacy `customTimeRestrictions.dart` where the
// product said to (D69): Sunday-first indices, 9:00 AM – 6:00 PM when a day
// is switched on, a disabled day is `null` in `daySelection`, all days
// disabled is NO profile. It departs where the product said to (D70): an end
// that is not after its start is invalid, where legacy shipped a negative
// window.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';

const TimeOfDay nine = TimeOfDay(hour: 9, minute: 0);
const TimeOfDay five = TimeOfDay(hour: 17, minute: 0);
const TimeOfDay six = TimeOfDay(hour: 18, minute: 0);
const TimeOfDay ten = TimeOfDay(hour: 10, minute: 0);
const TimeOfDay four = TimeOfDay(hour: 16, minute: 0);
const TimeOfDay sixPm = TimeOfDay(hour: 18, minute: 0);
const TimeOfDay tenPm = TimeOfDay(hour: 22, minute: 0);

RestrictionDay day(int weekday, TimeOfDay start, TimeOfDay end) {
  // Equal start and end is the whole day (D74); an earlier end wraps to the
  // next day (D75).
  int minutes = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  if (minutes <= 0) minutes += 24 * 60;
  return RestrictionDay(
      weekday: weekday,
      restrictionTimeLine: RestrictionTimeLine(
          start: start,
          duration: Duration(minutes: minutes),
          weekDay: weekday));
}

/// Mon–Fri [start]–[end], as the server sends a Work profile.
RestrictionProfile weekdays(
    {TimeOfDay start = nine, TimeOfDay end = six, String? id = 'work-1'}) {
  final RestrictionProfile p =
      RestrictionProfile(daySelection: <RestrictionDay?>[
    null,
    for (int d = 1; d <= 5; d++) day(d, start, end),
    null,
  ]);
  p.id = id;
  p.timeZone = 'America/Denver';
  return p;
}

void main() {
  group('fromProfile / toProfile round trip (D69)', () {
    test('a null profile is seven disabled days at the default window', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      expect(d.days.length, 7);
      for (final RestrictionHoursDay row in d.days) {
        expect(row.enabled, isFalse);
        expect(row.start, RestrictionHoursDraft.defaultStart);
        expect(row.end, RestrictionHoursDraft.defaultEnd);
      }
      expect(d.hasEnabledDay, isFalse);
      expect(d.toProfile(), isNull, reason: 'all disabled is no profile');
    });

    test('a loaded profile fills the rows, Sunday first', () {
      final RestrictionHoursDraft d =
          RestrictionHoursDraft.fromProfile(weekdays(start: nine, end: five));
      expect(d.days[0].enabled, isFalse, reason: 'Sunday');
      expect(d.days[6].enabled, isFalse, reason: 'Saturday');
      for (int i = 1; i <= 5; i++) {
        expect(d.days[i].enabled, isTrue);
        expect(d.days[i].start, nine);
        expect(d.days[i].end, five);
      }
    });

    test('toProfile keeps the server id and time zone, nulls disabled days',
        () {
      final RestrictionProfile loaded = weekdays();
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(loaded);
      d.setEnabled(6, true);
      d.setStart(6, ten);
      d.setEnd(6, four);
      final RestrictionProfile out = d.toProfile()!;
      expect(out.id, 'work-1');
      expect(out.timeZone, 'America/Denver');
      expect(out.isEnabled, isTrue);
      expect(out.daySelection[0], isNull);
      expect(out.daySelection[6]!.weekday, 6);
      expect(out.daySelection[6]!.restrictionTimeLine!.start, ten);
      expect(out.daySelection[6]!.restrictionTimeLine!.duration,
          const Duration(hours: 6));
      expect(out.daySelection[3]!.restrictionTimeLine!.duration,
          const Duration(hours: 9));
      expect(identical(out, loaded), isFalse, reason: 'never mutates the seed');
    });

    test('an ad-hoc profile is a fresh RestrictionProfile like legacy built',
        () {
      // No seed: no id, exactly what the legacy editor's
      // `RestrictionProfile(daySelection:)` produced (`TilerObj({this.id})`
      // leaves the field null), so the mapper sends the week and a null
      // `RestrictionProfileId` as before (D68).
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(2, true);
      final RestrictionProfile out = d.toProfile()!;
      expect(out.id, isNull);
      expect(out.isAnyDayNotNull, isTrue);
      expect(out.daySelection.whereType<RestrictionDay>().length, 1);
    });

    test('a disabled server profile loads as its days, still editable', () {
      // Tile Preferences flips `isEnabled` to false for "anytime"; the rows
      // still carry the last hours so the editor can bring them back.
      final RestrictionProfile p = weekdays()..isEnabled = false;
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(p);
      expect(d.days[1].enabled, isTrue);
      expect(d.toProfile()!.isEnabled, isTrue,
          reason: 'saving from the editor re-enables the profile');
    });
  });

  group('Enabling a day (D69)', () {
    test('a newly enabled day is 9:00 AM – 6:00 PM', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(0, true);
      expect(d.days[0].start, const TimeOfDay(hour: 9, minute: 0));
      expect(d.days[0].end, const TimeOfDay(hour: 18, minute: 0));
    });

    test('disabling keeps the hours so re-enabling restores them', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(0, true);
      d.setStart(0, ten);
      d.setEnabled(0, false);
      expect(d.toProfile(), isNull);
      d.setEnabled(0, true);
      expect(d.days[0].start, ten);
    });
  });

  group('Presets (D69)', () {
    test('each preset writes the seven rows and is then the match', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      for (final RestrictionHoursPreset preset
          in RestrictionHoursPreset.values) {
        d.applyPreset(preset);
        expect(d.matchingPreset, preset, reason: preset.name);
      }
    });

    test('Weekdays 9–6 is Mon–Fri 9:00–18:00, weekend off', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null)
        ..applyPreset(RestrictionHoursPreset.weekdays9to6);
      expect(d.days[0].enabled, isFalse);
      expect(d.days[6].enabled, isFalse);
      for (int i = 1; i <= 5; i++) {
        expect(d.days[i].enabled, isTrue);
        expect(d.days[i].start, nine);
        expect(d.days[i].end, six);
      }
    });

    test('Evenings is every day 6 PM – 10 PM; Weekends is Sat+Sun 10–4', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null)
        ..applyPreset(RestrictionHoursPreset.evenings6to10);
      for (final RestrictionHoursDay row in d.days) {
        expect(row.enabled, isTrue);
        expect(row.start, sixPm);
        expect(row.end, tenPm);
      }
      d.applyPreset(RestrictionHoursPreset.weekends10to4);
      expect(d.days.where((r) => r.enabled).length, 2);
      expect(d.days[0].start, ten);
      expect(d.days[6].end, four);
      expect(d.days[3].enabled, isFalse);
    });

    test('the highlight is derived: any edit off a preset clears it', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null)
        ..applyPreset(RestrictionHoursPreset.weekdays9to5);
      d.setEnd(3, six);
      expect(d.matchingPreset, isNull);
      d.setEnd(3, five);
      expect(d.matchingPreset, RestrictionHoursPreset.weekdays9to5,
          reason: 'and comes back when the rows match again');
    });

    test('a loaded Work profile of Mon–Fri 9–6 already matches', () {
      expect(RestrictionHoursDraft.fromProfile(weekdays()).matchingPreset,
          RestrictionHoursPreset.weekdays9to6);
    });
  });

  group('Copy and paste (D71)', () {
    test('copy marks the source; paste writes hours onto another row', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(1, true);
      d.setStart(1, ten);
      d.setEnd(1, four);
      expect(d.copiedDay, isNull);
      d.copyDay(1);
      expect(d.copiedDay, 1);
      d.pasteTo(4);
      expect(d.days[4].start, ten);
      expect(d.days[4].end, four);
      expect(d.days[4].enabled, isTrue,
          reason: 'pasting onto a day enables it');
      expect(d.copiedDay, 1, reason: 'the clipboard survives a paste');
    });

    test('copying the source again clears the clipboard', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null)
        ..setEnabled(2, true)
        ..copyDay(2);
      d.copyDay(2);
      expect(d.copiedDay, isNull);
    });

    test('pasting onto the source, or with nothing copied, is a no-op', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null)
        ..setEnabled(2, true)
        ..setStart(2, ten);
      int n = 0;
      d.addListener(() => n++);
      d.pasteTo(4);
      expect(n, 0, reason: 'nothing copied');
      expect(d.days[4].enabled, isFalse);
      d.copyDay(2);
      d.pasteTo(2);
      expect(n, 1, reason: 'only the copy notified');
      expect(d.days[2].start, ten);
      expect(d.copiedDay, 2);
    });
  });

  group('All day (D74): start equal to end', () {
    test('an equal start and end is valid and means the whole day', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(1, true);
      d.setEnd(1, nine);
      expect(d.days[1].isAllDay, isTrue);
      expect(d.days[2].isAllDay, isFalse, reason: 'disabled day');
      final RestrictionProfile out = d.toProfile()!;
      expect(out.daySelection[1]!.restrictionTimeLine!.start, nine);
      expect(out.daySelection[1]!.restrictionTimeLine!.duration,
          const Duration(hours: 24));
    });

    test('a 24-hour window on the wire loads as equal start and end', () {
      final RestrictionProfile p =
          RestrictionProfile(daySelection: <RestrictionDay?>[
        null,
        RestrictionDay(
            weekday: 1,
            restrictionTimeLine: RestrictionTimeLine(
                start: nine, duration: const Duration(hours: 24), weekDay: 1)),
        null,
        null,
        null,
        null,
        null,
      ]);
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(p);
      expect(d.days[1].start, nine);
      expect(d.days[1].end, nine);
      expect(d.days[1].isAllDay, isTrue);
      expect(d.isDirty, isFalse);
    });

    test('describeRestrictionProfile marks an all-day group', () {
      final RestrictionProfile p = weekdays(start: nine, end: nine);
      final List<RestrictionHoursGroup> g = describeRestrictionProfile(p);
      expect(g.single.isAllDay, isTrue);
      expect(describeRestrictionProfile(weekdays()).single.isAllDay, isFalse);
    });
  });

  group(
      'Overnight windows (D75): an end before its start wraps to the next day',
      () {
    test('nothing is invalid; the window is (end - start) mod 24 h', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(1, true);
      d.setStart(1, const TimeOfDay(hour: 21, minute: 0));
      d.setEnd(1, const TimeOfDay(hour: 2, minute: 0));
      expect(d.days[1].wrapsToNextDay, isTrue);
      expect(d.days[1].isAllDay, isFalse);
      expect(d.days[1].window, const Duration(hours: 5));
      final RestrictionProfile out = d.toProfile()!;
      final RestrictionTimeLine line =
          out.daySelection[1]!.restrictionTimeLine!;
      expect(line.start, const TimeOfDay(hour: 21, minute: 0));
      expect(line.duration, const Duration(hours: 5),
          reason: 'never negative — the legacy editor sent -19h here');
    });

    test('a same-day window does not wrap; all day is 24 h', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(1, true);
      expect(d.days[1].wrapsToNextDay, isFalse);
      expect(d.days[1].window, const Duration(hours: 9));
      d.setEnd(1, nine);
      expect(d.days[1].wrapsToNextDay, isFalse);
      expect(d.days[1].window, const Duration(hours: 24));
    });

    test('a window can never cover more than one day', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      d.setEnabled(1, true);
      d.setStart(1, const TimeOfDay(hour: 9, minute: 0));
      d.setEnd(1, const TimeOfDay(hour: 8, minute: 59));
      expect(d.days[1].window, const Duration(hours: 23, minutes: 59));
    });

    test('a legacy NEGATIVE duration on the wire loads as the same clocks', () {
      // The legacy editor computed end - start without wrapping, so 9 PM –
      // 2 AM was stored as -19 h. The clocks are what the user meant.
      final RestrictionProfile p =
          RestrictionProfile(daySelection: <RestrictionDay?>[
        RestrictionDay(
            weekday: 0,
            restrictionTimeLine: RestrictionTimeLine(
                start: const TimeOfDay(hour: 21, minute: 0),
                duration: const Duration(hours: -19),
                weekDay: 0)),
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(p);
      expect(d.days[0].start, const TimeOfDay(hour: 21, minute: 0));
      expect(d.days[0].end, const TimeOfDay(hour: 2, minute: 0));
      expect(d.days[0].window, const Duration(hours: 5));
      expect(d.toProfile()!.daySelection[0]!.restrictionTimeLine!.duration,
          const Duration(hours: 5),
          reason: 'saving normalises the duration');
    });

    test('describeRestrictionProfile marks a wrapping group', () {
      final RestrictionProfile p = weekdays(
          start: const TimeOfDay(hour: 21, minute: 0),
          end: const TimeOfDay(hour: 2, minute: 0));
      expect(describeRestrictionProfile(p).single.wrapsToNextDay, isTrue);
      expect(describeRestrictionProfile(weekdays()).single.wrapsToNextDay,
          isFalse);
    });

    test('sameRestrictionHours compares clocks, not durations', () {
      // A legacy -19 h profile and the same hours saved by the new editor
      // (+5 h) must still be recognised as the same Work profile.
      final RestrictionProfile legacy =
          RestrictionProfile(daySelection: <RestrictionDay?>[
        null,
        RestrictionDay(
            weekday: 1,
            restrictionTimeLine: RestrictionTimeLine(
                start: const TimeOfDay(hour: 21, minute: 0),
                duration: const Duration(hours: -19),
                weekDay: 1)),
        null,
        null,
        null,
        null,
        null,
      ]);
      final RestrictionProfile fresh =
          RestrictionProfile(daySelection: <RestrictionDay?>[
        null,
        day(1, const TimeOfDay(hour: 21, minute: 0),
            const TimeOfDay(hour: 2, minute: 0)),
        null,
        null,
        null,
        null,
        null,
      ]);
      expect(legacy.isEquivalent(fresh), isFalse, reason: 'the old comparison');
      expect(sameRestrictionHours(legacy, fresh), isTrue);
      expect(sameRestrictionHours(legacy, weekdays()), isFalse);
      expect(TimeRestrictionChoice.of(legacy, work: fresh, personal: null),
          TimeRestrictionChoice.work);
    });
  });

  group('Dirty tracking', () {
    test('clean after load; dirty after any edit; clean again when reverted',
        () {
      final RestrictionHoursDraft d =
          RestrictionHoursDraft.fromProfile(weekdays());
      expect(d.isDirty, isFalse);
      d.setEnabled(0, true);
      expect(d.isDirty, isTrue);
      d.setEnabled(0, false);
      expect(d.isDirty, isFalse);
    });

    test('a listener fires once per edit', () {
      final RestrictionHoursDraft d = RestrictionHoursDraft.fromProfile(null);
      int n = 0;
      d.addListener(() => n++);
      d.setEnabled(0, true);
      d.applyPreset(RestrictionHoursPreset.weekdays9to6);
      d.copyDay(1);
      expect(n, 3);
    });
  });

  group('TimeRestrictionChoice.of', () {
    final RestrictionProfile work = weekdays(id: 'work-1');
    final RestrictionProfile personal =
        weekdays(start: sixPm, end: tenPm, id: 'personal-1');

    test('null is Anytime', () {
      expect(TimeRestrictionChoice.of(null, work: work, personal: personal),
          TimeRestrictionChoice.anytime);
    });

    test('matches a named profile by id first', () {
      final RestrictionProfile sameId = weekdays(start: ten, end: four)
        ..id = 'work-1';
      expect(TimeRestrictionChoice.of(sameId, work: work, personal: personal),
          TimeRestrictionChoice.work);
      expect(TimeRestrictionChoice.of(personal, work: work, personal: personal),
          TimeRestrictionChoice.personal);
    });

    test('falls back to equivalent hours when the id differs', () {
      // A tile loaded from the server carries its own copy of the profile.
      final RestrictionProfile copy = weekdays(id: 'tile-copy');
      expect(TimeRestrictionChoice.of(copy, work: work, personal: personal),
          TimeRestrictionChoice.work);
    });

    test('anything else is Custom; a disabled/empty profile is Anytime', () {
      final RestrictionProfile adHoc = weekdays(start: ten, end: four, id: 'x');
      expect(TimeRestrictionChoice.of(adHoc, work: work, personal: personal),
          TimeRestrictionChoice.custom);
      final RestrictionProfile off = weekdays(id: 'work-1')..isEnabled = false;
      expect(TimeRestrictionChoice.of(off, work: work, personal: personal),
          TimeRestrictionChoice.anytime);
      expect(
          TimeRestrictionChoice.of(RestrictionProfile.noRestriction(),
              work: null, personal: null),
          TimeRestrictionChoice.anytime);
    });
  });

  group('describeRestrictionProfile', () {
    test('groups consecutive days that share a window', () {
      final List<RestrictionHoursGroup> g =
          describeRestrictionProfile(weekdays());
      expect(g.length, 1);
      expect(g.single.days, <int>[1, 2, 3, 4, 5]);
      expect(g.single.start, nine);
      expect(g.single.end, six);
    });

    test('splits on a different window and skips disabled days', () {
      final RestrictionProfile p =
          RestrictionProfile(daySelection: <RestrictionDay?>[
        day(0, ten, four),
        day(1, nine, six),
        day(2, nine, six),
        null,
        day(4, nine, six),
        null,
        day(6, ten, four),
      ]);
      final List<RestrictionHoursGroup> g = describeRestrictionProfile(p);
      expect(g.map((x) => x.days).toList(), <List<int>>[
        <int>[0],
        <int>[1, 2],
        <int>[4],
        <int>[6],
      ]);
    });

    test('an empty, null or disabled profile describes nothing', () {
      expect(describeRestrictionProfile(null), isEmpty);
      expect(describeRestrictionProfile(RestrictionProfile.noRestriction()),
          isEmpty);
      expect(
          describeRestrictionProfile(weekdays()..isEnabled = false), isEmpty);
    });
  });

  group('isUsableProfile (D73)', () {
    test('needs isEnabled and at least one day', () {
      expect(isUsableRestrictionProfile(null), isFalse);
      expect(isUsableRestrictionProfile(RestrictionProfile.noRestriction()),
          isFalse);
      expect(
          isUsableRestrictionProfile(weekdays()..isEnabled = false), isFalse);
      expect(isUsableRestrictionProfile(weekdays()), isTrue);
    });
  });
}
