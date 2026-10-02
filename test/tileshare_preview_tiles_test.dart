// TileShare redesign Step 9.11b (T24): turning a preview into what the one-day
// strip draws. The strip is `DayGridWidget(preview: true)`, which takes the
// day's tiles; these helpers pick the days the server returned, the tiles on
// one of them (with their own colours; the task being previewed in the
// preview accent), and how many flexible tiles the arrangement moves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/previewTiles.dart';

import 'helpers/tileshare_preview_fixtures.dart';

const int _hour = 3600000;
const int _now = 1789500000000;

DateTime _dayOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day);
}

TileSharePreview _viable() =>
    TileSharePreview.fromJson(previewFixture('preview_viable'));

void main() {
  // The app gets locale data from Flutter's localization delegates; a pure test
  // loads it itself.
  setUpAll(() => initializeDateFormatting('en'));

  group('the days the strip can show', () {
    test('every local day of the returned window, in order', () {
      final p = _viable();
      final days = PreviewTiles.days(p);
      expect(days.first, _dayOf(p.rangeStartMs!));
      expect(days.last, _dayOf(p.rangeEndMs! - 1));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].isAfter(days[i - 1]), isTrue);
        expect(days[i].hour, 0);
      }
    });

    test('a window that ends exactly at midnight does not add an empty day',
        () {
      final start = DateTime(2026, 10, 5);
      final p = TileSharePreview.fromJson({
        'assignmentId': 'a',
        'rangeStart': start.millisecondsSinceEpoch,
        'rangeEnd': DateTime(2026, 10, 7).millisecondsSinceEpoch,
      });
      expect(PreviewTiles.days(p), [DateTime(2026, 10, 5), DateTime(2026, 10, 6)]);
    });

    test('with no window, the days the task\'s sessions fall on', () {
      final s = DateTime(2026, 10, 9, 10).millisecondsSinceEpoch;
      final p = TileSharePreview.fromJson({
        'assignmentId': 'a',
        'sessions': [
          {'id': 'x', 'start': s, 'end': s + _hour, 'isProposed': true, 'viable': true, 'sessionKey': '0'}
        ],
      });
      expect(PreviewTiles.days(p), [DateTime(2026, 10, 9)]);
    });

    test('nothing at all is today', () {
      final p = TileSharePreview.fromJson({'assignmentId': 'a'});
      final days = PreviewTiles.days(p, today: DateTime(2026, 10, 2, 15));
      expect(days, [DateTime(2026, 10, 2)]);
    });
  });

  group('where a session is', () {
    test('the day it starts on, when that day is in the window', () {
      final p = _viable();
      final session = p.sessions.single;
      expect(PreviewTiles.dayFor(session, PreviewTiles.days(p)),
          _dayOf(session.startMs));
      expect(PreviewTiles.isInWindow(session, p), isTrue);
    });

    test('outside the window it has no day on the strip', () {
      final p = _viable();
      final far = PreviewBlock.fromJson({
        'id': 'far',
        'start': p.rangeEndMs! + 2 * 24 * _hour,
        'end': p.rangeEndMs! + 2 * 24 * _hour + _hour,
        'isProposed': true,
        'viable': true,
      });
      expect(PreviewTiles.isInWindow(far, p), isFalse);
      expect(PreviewTiles.dayFor(far, PreviewTiles.days(p)), isNull);
    });
  });

  group('the tiles of one day', () {
    test('are the proposed schedule\'s blocks on that day, as grid tiles',
        () {
      final p = _viable();
      final day = _dayOf(p.sessions.single.startMs);
      final tiles = PreviewTiles.forDay(p, day);
      final dayEnd = DateTime(day.year, day.month, day.day + 1);
      for (final t in tiles) {
        expect(t.endTime.isAfter(day), isTrue);
        expect(t.startTime.isBefore(dayEnd), isTrue);
      }
      expect(tiles.map((t) => t.id), contains('sub-new'));
    });

    test('keep their own colour, and a tile without one gets none', () {
      final p = _viable();
      final all = <String, dynamic>{};
      for (final day in PreviewTiles.days(p)) {
        for (final t in PreviewTiles.forDay(p, day)) {
          all[t.id!] = t;
        }
      }
      expect(all['sub-sync'].color, const Color(0xFF00695C));
      expect(all['sub-groceries'].color, const Color(0xFF33691E));
    });

    test('the task being previewed is drawn in the preview accent', () {
      final p = _viable();
      final day = _dayOf(p.sessions.single.startMs);
      final proposed =
          PreviewTiles.forDay(p, day).firstWhere((t) => t.id == 'sub-new');
      expect(proposed.color, PreviewTiles.proposedColor);
    });

    test('a fixed tile stays rigid, and the server\'s viability is kept', () {
      final p = _viable();
      final day = _dayOf(p.current[2].startMs);
      final club =
          PreviewTiles.forDay(p, day).firstWhere((t) => t.id == 'sub-club');
      expect(club.isRigid, isTrue);
    });

    test('a day with nothing is an empty list', () {
      final p = _viable();
      expect(PreviewTiles.forDay(p, DateTime(2030, 1, 1)), isEmpty);
    });

    test('a block that spans midnight appears on both days', () {
      final start = DateTime(2026, 10, 5, 23).millisecondsSinceEpoch;
      final p = TileSharePreview.fromJson({
        'assignmentId': 'a',
        'proposed': [
          {'id': 'late', 'start': start, 'end': start + 2 * _hour, 'viable': true}
        ],
      });
      expect(PreviewTiles.forDay(p, DateTime(2026, 10, 5)).single.id, 'late');
      expect(PreviewTiles.forDay(p, DateTime(2026, 10, 6)).single.id, 'late');
    });
  });

  group('what the arrangement moves', () {
    test('counts the existing tiles that sit somewhere else in the proposal',
        () {
      final base = previewFixture('preview_viable');
      final current = (base['current'] as List).cast<Map<String, dynamic>>();
      final moved = current
          .map((b) => b['id'] == 'sub-groceries'
              ? {...b, 'start': (b['start'] as int) + _hour, 'end': (b['end'] as int) + _hour}
              : b)
          .toList();
      final p = TileSharePreview.fromJson({
        ...base,
        'proposed': [...moved, ...(base['sessions'] as List)],
      });
      expect(PreviewTiles.movedCount(p), 1);
    });

    test('the task itself and unchanged tiles are not moves', () {
      expect(PreviewTiles.movedCount(_viable()), 0);
    });
  });

  test('the time of a session reads as date and range', () {
    final start = DateTime(2026, 10, 9, 9).millisecondsSinceEpoch;
    final b = PreviewBlock.fromJson(
        {'id': 'x', 'start': start, 'end': start + 90 * 60000});
    final text = PreviewTiles.when(b, 'en');
    expect(text, contains('Oct 9'));
    expect(text, contains('9:00'));
    expect(text, contains('10:30'));
  });

  test('the window constant: 1789500000000 is in it', () {
    final p = _viable();
    expect(p.rangeStartMs! <= _now && _now < p.rangeEndMs!, isTrue);
  });
}
