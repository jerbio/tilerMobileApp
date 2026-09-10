import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';

void main() {
  group('DayGridController', () {
    test('initial state: default zoom 80px/h, idle mode, 15-min snap seed', () {
      final controller = DayGridController();
      expect(controller.pxPerHour, 80);
      expect(controller.mode, DayGridMode.idle);
      // Seeded at 15 min for the default zoom.
      expect(controller.snapInterval, const Duration(minutes: 15));
      expect(controller.hasExplicitZoom, isFalse);
      controller.dispose();
    });

    group('pxPerHour clamping ([40, 240])', () {
      test('values inside the range are applied unchanged', () {
        final controller = DayGridController();
        controller.setPxPerHour(120);
        expect(controller.pxPerHour, 120);
        controller.dispose();
      });

      test('values below the range clamp to 40', () {
        final controller = DayGridController();
        controller.setPxPerHour(10);
        expect(controller.pxPerHour, 40);
        controller.dispose();
      });

      test('values above the range clamp to 240', () {
        final controller = DayGridController();
        controller.setPxPerHour(500);
        expect(controller.pxPerHour, 240);
        controller.dispose();
      });
    });

    group('snapInterval bands', () {
      test('pxPerHour below 80 snaps to 30 min', () {
        final controller = DayGridController();
        controller.setPxPerHour(79);
        expect(controller.snapInterval, const Duration(minutes: 30));
        controller.dispose();
      });

      test('pxPerHour 80 snaps to 15 min', () {
        final controller = DayGridController();
        controller.setPxPerHour(80);
        expect(controller.snapInterval, const Duration(minutes: 15));
        controller.dispose();
      });

      test('pxPerHour 159 snaps to 15 min', () {
        final controller = DayGridController();
        controller.setPxPerHour(159);
        expect(controller.snapInterval, const Duration(minutes: 15));
        controller.dispose();
      });

      test('pxPerHour 160 snaps to 5 min', () {
        final controller = DayGridController();
        controller.setPxPerHour(160);
        expect(controller.snapInterval, const Duration(minutes: 5));
        controller.dispose();
      });
    });

    group('auto-fit seed', () {
      test('auto-fits viewportHeight / 4 when no explicit zoom exists', () {
        final controller = DayGridController();
        controller.autoFit(600);
        expect(controller.pxPerHour, 150);
        // Auto-fit is not an explicit user zoom — a later restore of a stored
        // value must still be able to win.
        expect(controller.hasExplicitZoom, isFalse);
        controller.dispose();
      });

      test('auto-fit clamps at the lower bound for tiny viewports', () {
        final controller = DayGridController();
        controller.autoFit(100);
        expect(controller.pxPerHour, 40);
        controller.dispose();
      });

      test('auto-fit clamps at the upper bound for huge viewports', () {
        final controller = DayGridController();
        controller.autoFit(2000);
        expect(controller.pxPerHour, 240);
        controller.dispose();
      });

      test('auto-fit is a no-op once the user has set an explicit zoom', () {
        final controller = DayGridController();
        controller.setPxPerHour(200);
        controller.autoFit(600);
        expect(controller.pxPerHour, 200);
        expect(controller.hasExplicitZoom, isTrue);
        controller.dispose();
      });

      test('restoring a stored zoom marks it explicit and wins over auto-fit',
          () {
        final controller = DayGridController();
        controller.restoreStoredPxPerHour(180);
        expect(controller.pxPerHour, 180);
        expect(controller.hasExplicitZoom, isTrue);
        controller.autoFit(600);
        expect(controller.pxPerHour, 180);
        controller.dispose();
      });
    });

    group('change notification', () {
      test('notifies only when the value actually changes', () {
        final controller = DayGridController();
        int notifications = 0;
        controller.addListener(() => notifications++);

        controller.setPxPerHour(80); // same value
        expect(notifications, 0);

        controller.setPxPerHour(100);
        expect(notifications, 1);

        controller.setPxPerHour(100); // same value again
        expect(notifications, 1);

        // Clamping to the current value is also a no-op.
        controller.setPxPerHour(500);
        expect(controller.pxPerHour, 240);
        expect(notifications, 2);
        controller.setPxPerHour(900); // clamps to the same 240
        expect(notifications, 2);

        controller.dispose();
      });

      test('mode transitions notify; re-setting the same mode does not', () {
        final controller = DayGridController();
        int notifications = 0;
        controller.addListener(() => notifications++);

        controller.mode = DayGridMode.zooming;
        expect(notifications, 1);
        controller.mode = DayGridMode.zooming;
        expect(notifications, 1);
        controller.mode = DayGridMode.dragging;
        expect(notifications, 2);
        controller.mode = DayGridMode.idle;
        expect(notifications, 3);
        expect(controller.mode, DayGridMode.idle);
        controller.dispose();
      });
    });
  });
}