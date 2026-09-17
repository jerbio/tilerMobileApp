// daily_carousel_remount_test.dart
//
// Regression for the "Loading upcoming days..." page stuck under the home
// tour (product-tour-onboarding-redesign.md, stage 3.5 cycle 2).
//
// The daily view's day carousel keeps its widget key across schedule
// reloads unless the load carries a new `evaluationId`. `carousel_slider`
// re-creates its PageController at the *current* page on every widget
// update (it ignores `initialPage` once mounted), so when a reload shrinks
// the page set below the current page the carousel is clamped to its last
// page — the future-edge "Loading upcoming days..." placeholder.
//
// That is exactly what the home tour does: the real schedule renders a
// 7-day window (today at page 4), then `injectDummyTiles` reloads a
// single-day window with a bare `ScheduleStatus()` (no evaluationId).
// Since the schedule is now prefetched during onboarding (stage 3.5) the
// 7-day carousel is reliably on screen before the tour starts, so the
// tour stranded the carousel on the placeholder and could not find the
// current tile for its "Control Your Tiles" step.
//
// Rule under test: the carousel must be remounted whenever the rendered
// day span changes, not only when the status changes.

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/data/timeline.dart';

Timeline _days(DateTime start, int days) =>
    Timeline.fromDateTimeAndDuration(start, Duration(days: days));

void main() {
  final now = DateTime(2026, 9, 12, 15, 33);
  final sevenDayWindow = _days(now.subtract(const Duration(days: 3)), 7);
  final todayOnly = _days(DateTime(now.year, now.month, now.day), 1);

  group('carouselDaySpanId', () {
    test('identifies a window by its first and last day index', () {
      expect(carouselDaySpanId(sevenDayWindow),
          isNot(carouselDaySpanId(todayOnly)));
      expect(carouselDaySpanId(sevenDayWindow),
          carouselDaySpanId(_days(now.subtract(const Duration(days: 3)), 7)),
          reason: 'Same days -> same span id, regardless of time of day.');
    });
  });

  group('shouldRemountCarousel', () {
    test('tour dummy reload: 7-day window -> single day, no status -> remount',
        () {
      expect(
        shouldRemountCarousel(
          previousSpanId: carouselDaySpanId(sevenDayWindow),
          spanId: carouselDaySpanId(todayOnly),
          statusId: null,
        ),
        isTrue,
        reason: 'The page set shrank below the current page; keeping the '
            'carousel would strand it on the future-edge placeholder.',
      );
    });

    test('same span, no status (pure local refresh) -> keep the carousel', () {
      expect(
        shouldRemountCarousel(
          previousSpanId: carouselDaySpanId(sevenDayWindow),
          spanId: carouselDaySpanId(sevenDayWindow),
          statusId: null,
        ),
        isFalse,
        reason: 'Nothing about the page set changed; a remount would reset '
            'the user\'s scroll position for no reason.',
      );
    });

    test('a new evaluation id always remounts (existing behavior)', () {
      expect(
        shouldRemountCarousel(
          previousSpanId: carouselDaySpanId(sevenDayWindow),
          spanId: carouselDaySpanId(sevenDayWindow),
          statusId: 'eval-1',
        ),
        isTrue,
      );
    });

    test('first load (no previous span) remounts', () {
      expect(
        shouldRemountCarousel(
          previousSpanId: null,
          spanId: carouselDaySpanId(sevenDayWindow),
          statusId: null,
        ),
        isTrue,
      );
    });

    test('tour end: single day -> 7-day window remounts too', () {
      expect(
        shouldRemountCarousel(
          previousSpanId: carouselDaySpanId(todayOnly),
          spanId: carouselDaySpanId(sevenDayWindow),
          statusId: null,
        ),
        isTrue,
        reason: 'Growing back must land on today, not on whatever page '
            'index the dummy carousel was showing.',
      );
    });
  });
}
