import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/preview/day_preview_metrics.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/preview_sentence.dart';

/// Deterministic labels used by tests so we can assert on exact substrings
/// without depending on a real `AppLocalizations` instance.
PreviewLabels _labels() => PreviewLabels(
      greeting: 'Hello.',
      tilesClause: (n) => '$n tiles',
      blocksClause: (n) => '$n blocks',
      tileSharesClause: (n) => '$n shares',
      workClause: (hours) => '$hours hours work',
      transitClause: (mins) => '$mins min transit',
      clearsByClause: (time) => 'clears $time',
      countsPrefix: 'Today has',
      countsSuffix: 'waiting.',
      andSeparator: 'and',
      sentenceJoiner: '. ',
      noTiles: 'No tiles today.',
      formatHours: (h) => h.toStringAsFixed(1),
      formatClearTime: (dt) => '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}',
    );

DayPreviewMetrics _metrics({
  int tiles = 0,
  int blocks = 0,
  int shares = 0,
  Duration work = Duration.zero,
  Duration transit = Duration.zero,
  DateTime? clearsBy,
}) {
  return DayPreviewMetrics(
    tilesCount: tiles,
    blocksCount: blocks,
    tileSharesCount: shares,
    nonViableCount: 0,
    workDuration: work,
    transitDuration: transit,
    dayClearsBy: clearsBy,
    distance: null,
    distanceUnit: 'meters',
    locationsCount: 0,
    sleepDuration: null,
    completionPct: null,
  );
}

void main() {
  group('buildPreviewSentence', () {
    test('falls back to no-tiles message when day has nothing', () {
      final s = buildPreviewSentence(
        metrics: _metrics(),
        labels: _labels(),
      );
      expect(s, 'No tiles today.');
    });

    test('includes all clauses when every metric is present', () {
      final s = buildPreviewSentence(
        metrics: _metrics(
          tiles: 5,
          blocks: 3,
          shares: 2,
          work: const Duration(hours: 4, minutes: 12),
          transit: const Duration(minutes: 22),
          clearsBy: DateTime.utc(2026, 6, 21, 17, 0),
        ),
        labels: _labels(),
      );

      expect(s, contains('Hello.'));
      expect(s, contains('Today has'));
      expect(s, contains('5 tiles'));
      expect(s, contains('3 blocks'));
      expect(s, contains('2 shares'));
      expect(s, contains('waiting.'));
      expect(s, contains('4.2 hours work'));
      expect(s, contains('22 min transit'));
      expect(s, contains('clears 17:00'));
    });

    test('omits blocks clause when blocks count is zero', () {
      final s = buildPreviewSentence(
        metrics: _metrics(tiles: 5, shares: 2),
        labels: _labels(),
      );
      expect(s, isNot(contains('blocks')));
      expect(s, contains('5 tiles'));
      expect(s, contains('2 shares'));
    });

    test('omits tileshares clause when share count is zero', () {
      final s = buildPreviewSentence(
        metrics: _metrics(tiles: 5, blocks: 3),
        labels: _labels(),
      );
      expect(s, isNot(contains('shares')));
      expect(s, contains('5 tiles'));
      expect(s, contains('3 blocks'));
    });

    test('omits transit clause when transit is zero', () {
      final s = buildPreviewSentence(
        metrics: _metrics(
          tiles: 5,
          work: const Duration(hours: 4),
        ),
        labels: _labels(),
      );
      expect(s, isNot(contains('transit')));
      expect(s, contains('4.0 hours work'));
    });

    test('omits clears-by clause when dayClearsBy is null', () {
      final s = buildPreviewSentence(
        metrics: _metrics(
          tiles: 5,
          work: const Duration(hours: 4),
        ),
        labels: _labels(),
      );
      expect(s, isNot(contains('clears')));
    });

    test('omits work clause when work duration is zero', () {
      final s = buildPreviewSentence(
        metrics: _metrics(tiles: 0, blocks: 3),
        labels: _labels(),
      );
      expect(s, isNot(contains('hours work')));
      expect(s, contains('3 blocks'));
    });

    test('skips counts sentence entirely when only secondary clauses exist',
        () {
      final s = buildPreviewSentence(
        metrics: _metrics(
          work: const Duration(hours: 2),
          transit: const Duration(minutes: 15),
        ),
        labels: _labels(),
      );
      expect(s, isNot(contains('Today has')));
      expect(s, isNot(contains('waiting.')));
      expect(s, contains('2.0 hours work'));
      expect(s, contains('15 min transit'));
    });
  });
}
