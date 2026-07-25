import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/subEventPaging.dart';

SubCalendarEvent _sub(
  String id,
  int start, {
  bool complete = false,
  bool enabled = true,
}) {
  return SubCalendarEvent.fromJson({
    'id': id,
    'start': start,
    'end': start + 1000,
    'isComplete': complete,
    'isEnabled': enabled,
  });
}

void main() {
  group('SubEventPaging.setInitial', () {
    test('full batch establishes cursors and marks both edges as having more',
        () {
      final paging = SubEventPaging(batchSize: 2);

      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      expect(paging.leftCursorId, 'a');
      expect(paging.rightCursorId, 'b');
      expect(paging.hasMoreAfter, isTrue);
      expect(paging.hasMoreBefore, isTrue);
      expect(paging.isEmpty, isFalse);
      expect(paging.orderedItems.map((e) => e.id), ['a', 'b']);
    });

    test('partial batch marks both edges exhausted', () {
      final paging = SubEventPaging(batchSize: 3);

      paging.setInitial([_sub('a', 1000)]);

      expect(paging.hasMoreAfter, isFalse);
      expect(paging.hasMoreBefore, isFalse);
      expect(paging.leftCursorId, 'a');
      expect(paging.rightCursorId, 'a');
    });

    test('empty page leaves cursors null and both edges exhausted', () {
      final paging = SubEventPaging(batchSize: 2);

      paging.setInitial([]);

      expect(paging.isEmpty, isTrue);
      expect(paging.leftCursorId, isNull);
      expect(paging.rightCursorId, isNull);
      expect(paging.hasMoreAfter, isFalse);
      expect(paging.hasMoreBefore, isFalse);
    });

    test('re-seeding clears previous items', () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      paging.setInitial([_sub('c', 3000)]);

      expect(paging.orderedItems.map((e) => e.id), ['c']);
    });
  });

  group('SubEventPaging ordering and filtering', () {
    test('orderedItems sorts by start ascending then id', () {
      final paging = SubEventPaging(batchSize: 5);

      paging.setInitial([
        _sub('b', 2000),
        _sub('a', 1000),
        _sub('d', 2000),
        _sub('c', 2000),
      ]);

      expect(paging.orderedItems.map((e) => e.id), ['a', 'b', 'c', 'd']);
    });

    test('visibleItems hides completed and disabled unless showCompleted', () {
      final paging = SubEventPaging(batchSize: 5);

      paging.setInitial([
        _sub('a', 1000),
        _sub('b', 2000, complete: true),
        _sub('c', 3000, enabled: false),
      ]);

      expect(paging.visibleItems().map((e) => e.id), ['a']);
      expect(paging.visibleItems(showCompleted: true).map((e) => e.id),
          ['a', 'b', 'c']);
    });
  });

  group('SubEventPaging.appendPage (trailing edge)', () {
    test('appends unique items and advances the right cursor', () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      paging.appendPage([_sub('c', 3000), _sub('d', 4000)]);

      expect(paging.orderedItems.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(paging.rightCursorId, 'd');
      expect(paging.hasMoreAfter, isTrue);
    });

    test('a short page exhausts the trailing edge', () {
      final paging = SubEventPaging(batchSize: 3);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000), _sub('c', 3000)]);

      paging.appendPage([_sub('d', 4000)]);

      expect(paging.hasMoreAfter, isFalse);
      expect(paging.rightCursorId, 'd');
    });

    test('overlapping ids are de-duplicated', () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      paging.appendPage([_sub('b', 2000), _sub('c', 3000)]);

      expect(paging.orderedItems.map((e) => e.id), ['a', 'b', 'c']);
    });
  });

  group('SubEventPaging.prependPage (leading edge)', () {
    test('prepends unique items and rewinds the left cursor', () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('c', 3000), _sub('d', 4000)]);

      paging.prependPage([_sub('a', 1000), _sub('b', 2000)]);

      expect(paging.orderedItems.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(paging.leftCursorId, 'a');
      expect(paging.hasMoreBefore, isTrue);
    });

    test('a short page exhausts the leading edge', () {
      final paging = SubEventPaging(batchSize: 3);
      paging.setInitial([_sub('c', 3000), _sub('d', 4000), _sub('e', 5000)]);

      paging.prependPage([_sub('b', 2000)]);

      expect(paging.hasMoreBefore, isFalse);
      expect(paging.leftCursorId, 'b');
    });
  });

  group('SubEventPaging load guards', () {
    test('canLoadAfter requires a cursor, more data, and not already loading',
        () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      expect(paging.canLoadAfter, isTrue);

      paging.isLoadingAfter = true;
      expect(paging.canLoadAfter, isFalse);

      paging.isLoadingAfter = false;
      paging.hasMoreAfter = false;
      expect(paging.canLoadAfter, isFalse);
    });

    test('canLoadBefore requires a cursor, more data, and not already loading',
        () {
      final paging = SubEventPaging(batchSize: 2);
      paging.setInitial([_sub('a', 1000), _sub('b', 2000)]);

      expect(paging.canLoadBefore, isTrue);

      // Single-flight: a trailing-edge fetch also blocks the leading edge.
      paging.isLoadingAfter = true;
      expect(paging.isLoadingMore, isTrue);
      expect(paging.canLoadBefore, isFalse);
      paging.isLoadingAfter = false;

      paging.isLoadingBefore = true;
      expect(paging.canLoadBefore, isFalse);
      paging.isLoadingBefore = false;

      paging.hasMoreBefore = false;
      expect(paging.canLoadBefore, isFalse);
    });
  });
}
