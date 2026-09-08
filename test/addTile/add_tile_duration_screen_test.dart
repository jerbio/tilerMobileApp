// Step 4.3c — the Duration picker.
//
// The legacy `/DurationDial` was not merely restyled away, it was BROKEN in
// this flow: it seeds from `params['initialDuration']` while the redesign's
// adapter wrote `params['duration']`, so it always opened at zero and
// confirming without touching it wrote a zero duration back. That failed
// validation and disabled the CTA with nothing on screen explaining why.
//
// So the properties worth pinning are seeding, bounds, and the step — the
// three things that were unenforced.
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'package:tiler_app/theme/today_status_tokens.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

Duration? _picked;

Future<void> pumpDuration(
  WidgetTester tester, {
  Duration initial = const Duration(minutes: 30),
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  _picked = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileDurationScreen(
      initialDuration: initial,
      onSelected: (d) => _picked = d,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> pumpDurationDark(
  WidgetTester tester, {
  Duration initial = const Duration(minutes: 30),
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.narrow);
  addTearDown(tester.view.reset);
  _picked = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.darkTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileDurationScreen(
      initialDuration: initial,
      onSelected: (d) => _picked = d,
    ),
  ));
  await tester.pumpAndSettle();
}

/// The [DialPainter] actually mounted in the tree.
///
/// Asserting the arguments this screen PASSES proves only that the screen
/// is well behaved — it stays green if the package quietly ignores them.
/// This reaches the painter itself, so a dropped value fails.
///
/// It still cannot prove the painter USES a colour in `paint()`; only a
/// golden could. See D46.
DialPainter mountedPainter(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DialPainter,
    ),
  );
  return paint.painter! as DialPainter;
}

/// Scrolls [finder] into view, then taps it.
///
/// The custom control and its Done sit below the fold on the standard test
/// viewport, so a bare `tap()` silently misses — which is how the "stepping
/// never commits on its own" assertion below first passed for the wrong
/// reason.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Duration model — bounds and stepping', () {
    test('clamping keeps a duration inside the supported range', () {
      expect(clampAddTileDuration(Duration.zero), minAddTileDuration);
      expect(clampAddTileDuration(const Duration(minutes: -30)),
          minAddTileDuration);
      expect(clampAddTileDuration(const Duration(days: 3)), maxAddTileDuration);
      expect(clampAddTileDuration(const Duration(hours: 2)),
          const Duration(hours: 2));
    });

    test('snapping ROUNDS rather than truncates', () {
      // Truncation always shortens, which walks a duration downward over
      // repeated edits.
      expect(snapAddTileDuration(const Duration(minutes: 43)),
          const Duration(minutes: 45));
      expect(snapAddTileDuration(const Duration(minutes: 41)),
          const Duration(minutes: 40));
      expect(snapAddTileDuration(const Duration(minutes: 30)),
          const Duration(minutes: 30));
    });

    test('a zero duration can never survive snapping', () {
      // The exact value the broken dial wrote back.
      expect(snapAddTileDuration(Duration.zero), minAddTileDuration);
    });

    test('a detent is crossed once per five minutes', () {
      // The wheel reports continuously while a finger is down, so the click
      // has to be driven by the SNAPPED value changing — otherwise a single
      // slow drag would buzz on every frame.
      expect(
        crossesDurationDetent(
            const Duration(minutes: 30), const Duration(minutes: 31)),
        isFalse,
        reason: '31 still snaps to 30',
      );
      expect(
        crossesDurationDetent(
            const Duration(minutes: 30), const Duration(minutes: 33)),
        isTrue,
        reason: '33 snaps to 35, a new detent',
      );
      expect(
        crossesDurationDetent(
            const Duration(minutes: 33), const Duration(minutes: 34)),
        isFalse,
        reason: 'both snap to 35, so the detent was already reported',
      );
    });

    test('a five-minute sweep clicks exactly once per step', () {
      // Counted rather than spot-checked: an off-by-one here is the
      // difference between a detent and a rattle.
      int clicks = 0;
      Duration previous = const Duration(minutes: 30);
      for (int minute = 31; minute <= 60; minute++) {
        final Duration next = Duration(minutes: minute);
        if (crossesDurationDetent(previous, next)) clicks++;
        previous = next;
      }
      expect(clicks, 6, reason: '30 -> 60 crosses 35, 40, 45, 50, 55 and 60');
    });

    test('every preset is expressible by the control that follows it', () {
      // A preset the stepper could not reach would be a value the user could
      // choose but never adjust to.
      for (final Duration preset in addTileDurationPresets) {
        expect(snapAddTileDuration(preset), preset,
            reason: '$preset is not on the step grid');
        expect(preset >= minAddTileDuration && preset <= maxAddTileDuration,
            isTrue,
            reason: '$preset is outside the supported range');
      }
    });

    test('summaries read compactly', () {
      expect(formatDurationSummary(testL10n, const Duration(minutes: 45)),
          '45 min');
      expect(formatDurationSummary(testL10n, const Duration(hours: 2)), '2 hr');
      expect(
          formatDurationSummary(
              testL10n, const Duration(hours: 1, minutes: 30)),
          '1 hr 30 min');
      expect(formatDurationSummary(testL10n, Duration.zero), isNull);
    });
  });

  group('Duration picker — selection', () {
    testWidgets('a preset commits on tap', (tester) async {
      await pumpDuration(tester);
      await tester.tap(find.byKey(const ValueKey('durationPreset_2')));
      await tester.pumpAndSettle();

      expect(_picked, addTileDurationPresets[2]);
    });

    testWidgets('the current duration reads as the selected preset',
        (tester) async {
      const Duration oneHour = Duration(hours: 1);
      final int index = addTileDurationPresets.indexOf(oneHour);
      expect(index, isNonNegative, reason: '1 hr must remain a preset');

      await pumpDuration(tester, initial: oneHour);
      final DurationPresetChip chip = tester.widget<DurationPresetChip>(
        find.byKey(ValueKey('durationPreset_$index')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('turning the wheel clears the preset highlight',
        (tester) async {
      // The screen must never claim two different current durations. It
      // used to highlight the COMMITTED preset beside a wheel showing
      // something else, leaving no way to tell which one Done meant.
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      final int index =
          addTileDurationPresets.indexOf(const Duration(minutes: 30));
      final Finder chip = find.byKey(ValueKey('durationPreset_$index'));
      expect(tester.widget<DurationPresetChip>(chip).selected, isTrue,
          reason: 'precondition: the seeded value starts selected');

      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(hours: 3, minutes: 10));
      await tester.pumpAndSettle();

      expect(tester.widget<DurationPresetChip>(chip).selected, isFalse);
      for (int i = 0; i < addTileDurationPresets.length; i++) {
        expect(
          tester
              .widget<DurationPresetChip>(
                  find.byKey(ValueKey('durationPreset_$i')))
              .selected,
          isFalse,
          reason: 'no preset matches 3:10, so none may read as selected',
        );
      }
    });

    testWidgets('turning the wheel BACK onto a preset re-selects it',
        (tester) async {
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      final int index =
          addTileDurationPresets.indexOf(const Duration(hours: 1));
      final DurationWheel wheel = tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')));

      wheel.onChanged(const Duration(hours: 3, minutes: 10));
      await tester.pumpAndSettle();
      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(hours: 1));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationPresetChip>(
                find.byKey(ValueKey('durationPreset_$index')))
            .selected,
        isTrue,
      );
    });

    test('the shortcut row stays short enough to glance at', () {
      // Eight chips took two rows and turned the shortcut into a list to
      // read. The wheel is the control for arbitrary values.
      expect(addTileDurationPresets.length, lessThanOrEqualTo(4));
    });

    testWidgets('the wheel SEEDS from the current duration', (tester) async {
      // The legacy dial's defect, stated as a test: it opened at zero
      // regardless of the draft because it read a key nobody wrote.
      await pumpDuration(tester, initial: const Duration(hours: 2));
      final DurationWheel wheel = tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')));
      expect(wheel.value, const Duration(hours: 2));
    });

    testWidgets('EVERY dial colour comes from the redesign tokens',
        (tester) async {
      // The previous version of this test asserted `ColorScheme.secondary`
      // alone, which is the arc — and passed happily while the knob, disc,
      // shadow and markers stayed hardcoded in the painter. A dark teal
      // handle on a grey disc was shipping under a green test.
      await pumpDuration(tester);

      final BuildContext ctx = tester.element(find.byType(DurationPicker));
      final tokens = TodayStatusTokens.of(ctx);
      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));

      final DialPainter painter = mountedPainter(tester);
      expect(painter.accentColor, tokens.brand, reason: 'the elapsed arc');
      expect(painter.trackColor, tokens.surfaceSubtle,
          reason: 'the unfilled ring');
      expect(painter.handleColor, tokens.brand, reason: 'the drag knob');
      expect(painter.innerCircleColor, tokens.surface, reason: 'the disc');
      expect(painter.innerShadowColor, tokens.cardBorder,
          reason: "the disc's shadow");
      expect(picker.markerColor, tokens.textSecondary,
          reason: 'the five-minute markers');
    });

    testWidgets('the readout is sized for the screen it dominates',
        (tester) async {
      await pumpDuration(tester);
      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));
      expect(picker.fontStyle, isNotNull,
          reason: 'left null it falls back to the package body default, '
              'which reads as small inside a large disc');
    });

    testWidgets('omitting the colours leaves the package unchanged',
        (tester) async {
      // The legacy dial shares this package and passes none of these, so
      // every default must still be the literal it replaced.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DurationPicker(
            duration: const Duration(minutes: 30),
            onChange: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));
      expect(picker.handleColor, isNull);
      expect(picker.innerCircleColor, isNull);
      expect(picker.innerShadowColor, isNull);
      expect(picker.markerColor, isNull);
      expect(picker.dialSize, 300.0,
          reason: 'the size the legacy dial has always drawn at');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unset draft opens on a usable value, not zero',
        (tester) async {
      await pumpDuration(tester, initial: Duration.zero);
      final DurationWheel wheel = tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')));
      expect(wheel.value, const Duration(minutes: 30));
    });

    testWidgets('Done commits the wheel value', (tester) async {
      await pumpDuration(tester, initial: const Duration(minutes: 45));
      await tapVisible(tester, find.byKey(const ValueKey('durationDone')));

      expect(_picked, const Duration(minutes: 45));
    });

    testWidgets('turning the wheel never commits on its own', (tester) async {
      // The wheel is the one control that confirms; a preset tap is the only
      // thing that returns immediately.
      await pumpDuration(tester);
      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(minutes: 55));
      await tester.pumpAndSettle();

      // Guard against passing for the wrong reason: the turn must register.
      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        const Duration(minutes: 55),
        reason: 'the change did not register, so the assertion below would '
            'pass whether or not turning commits',
      );
      expect(_picked, isNull);
    });

    testWidgets('the wheel cannot display a value it would rewrite on Done',
        (tester) async {
      // Clamped as it turns, not only at commit — otherwise it would show a
      // duration that silently became something else.
      await pumpDuration(tester);
      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(hours: 40));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        maxAddTileDuration,
      );
    });
  });

  group('Layout at a real phone width', () {
    // Everything here was wrong on device and green in the suite, because
    // the tests only ever asserted widget PROPERTIES on an 800pt viewport.
    // These assert geometry at the narrowest supported width instead.

    testWidgets('the quick presets form a grid, not eight stacked rows',
        (tester) async {
      // A `Center` inside the chip expanded it to the full line width, so
      // the Wrap had room for exactly one chip per row.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      final Rect first =
          tester.getRect(find.byKey(const ValueKey('durationPreset_0')));
      final Rect second =
          tester.getRect(find.byKey(const ValueKey('durationPreset_1')));

      expect(second.top, closeTo(first.top, 0.5),
          reason: 'the first two presets must share a row');
      expect(second.left, greaterThan(first.right - 1),
          reason: 'the second preset must sit beside the first');
      expect(first.width, lessThan(AddTileTestMatrix.narrow.width / 2),
          reason: 'a chip that fills the line is not a chip');
    });

    testWidgets('the preset row is centred, not left-hugging', (tester) async {
      // The chips size to their own text and "1 hr" is far narrower than
      // "15 min", so with Wrap's default `start` alignment all the slack
      // collected on the right and the row read as unfinished.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.largePhone);

      // Measured on the FIRST ROW only. How many chips share a row depends
      // on font metrics and text scale, and an earlier version of this test
      // asserted all four were on one row — which is true on the device and
      // false in the test environment. Centring is a per-row property, so
      // the row is what gets measured.
      final List<Rect> rects = <Rect>[
        for (int i = 0; i < addTileDurationPresets.length; i++)
          tester.getRect(find.byKey(ValueKey('durationPreset_$i'))),
      ];
      final double topRow = rects.first.top;
      final List<Rect> row =
          rects.where((r) => (r.top - topRow).abs() < 0.5).toList();
      expect(row.length, greaterThan(1),
          reason: 'a single-chip row says nothing about alignment');

      final Rect card = tester.getRect(find.ancestor(
        of: find.byKey(const ValueKey('durationPreset_0')),
        matching: find.byType(Wrap),
      ));
      final double leadingGap = row.first.left - card.left;
      final double trailingGap = card.right - row.last.right;

      expect(leadingGap, closeTo(trailingGap, 1),
          reason: 'left gap $leadingGap vs right gap $trailingGap');
      expect(leadingGap, greaterThan(0),
          reason: 'a zero leading gap means it is still hugging the left');
    });

    testWidgets('the wheel RESERVES exactly the space it paints',
        (tester) async {
      // The defect that survived two attempts to fix it: `DialPainter`
      // draws a circle of `size.shortestSide * 0.75` from the centre and
      // does not clip, so the visible wheel is 1.5x its layout box. Layout
      // assertions alone could never see it — the box was well behaved while
      // the paint covered the screen. This asserts the RELATIONSHIP instead:
      // the reserved space must equal the painted diameter.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));
      final Rect reserved = tester.getRect(wheel);
      final double painted = picker.dialSize * 1.5;

      expect(reserved.width, closeTo(painted, 1),
          reason: 'the wheel paints 1.5x its box, so reserving only the box '
              'lets it spill over everything around it');
    });

    testWidgets('the painted wheel fits the screen', (tester) async {
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));
      final Rect reserved = tester.getRect(wheel);
      final double painted = picker.dialSize * 1.5;
      final double centre = reserved.center.dx;

      expect(centre - painted / 2, greaterThanOrEqualTo(-0.5));
      expect(centre + painted / 2,
          lessThanOrEqualTo(AddTileTestMatrix.narrow.width + 0.5));
      expect(tester.takeException(), isNull,
          reason: 'the wheel must fit, not overflow');
    });

    testWidgets('the wheel does not reach the controls around it',
        (tester) async {
      // What the device screenshot actually showed: the wheel painted over
      // the preset grid above it and the Done button below.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));
      final Rect reserved = tester.getRect(wheel);
      final double painted = picker.dialSize * 1.5;
      final Rect done =
          tester.getRect(find.byKey(const ValueKey('durationDone')));

      expect(
          reserved.center.dy + painted / 2, lessThanOrEqualTo(done.top + 0.5),
          reason: 'the wheel painted over the Done button');
    });

    testWidgets('nothing overflows at the narrowest supported width',
        (tester) async {
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);
      await tester.ensureVisible(find.byKey(const ValueKey('durationDone')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('The wheel can only express five-minute values', () {
    testWidgets('an off-grid report from the wheel is snapped', (tester) async {
      // The vendored package accepts `snapToMins` and ignores it — the
      // implementation is commented out behind a TODO — so the wheel could
      // sit on 3:49 while advertising a five-minute grid.
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(hours: 3, minutes: 49));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        const Duration(hours: 3, minutes: 50),
      );
    });

    testWidgets('and so is the value Done commits', (tester) async {
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(minutes: 47));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('durationDone')));

      expect(_picked!.inMinutes % durationStepMinutes, 0);
      expect(_picked, const Duration(minutes: 45));
    });
  });

  group('Done is pinned to the screen', () {
    testWidgets('it is a sibling of the scroll view, not a child',
        (tester) async {
      // It used to sit inside the wheel's card, which read as belonging to
      // the wheel alone — misleading, since it commits whatever the screen
      // currently holds, a tapped preset included.
      //
      // Asserted STRUCTURALLY. The obvious version — drag the list and check
      // Done did not move — passes whether or not the fix is present,
      // because at this viewport the content already fits and the drag does
      // nothing at all.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      expect(
        find.descendant(
          of: find.byType(Scrollable),
          matching: find.byKey(const ValueKey('durationDone')),
        ),
        findsNothing,
        reason: 'a pinned CTA cannot be inside the thing that scrolls',
      );
    });

    testWidgets('it stays put when the content actually scrolls',
        (tester) async {
      // A viewport short enough to guarantee overflow, so the drag is real.
      await pumpDuration(tester, viewSize: const Size(320, 420));

      final Finder done = find.byKey(const ValueKey('durationDone'));
      final Rect before = tester.getRect(done);
      final Rect contentBefore =
          tester.getRect(find.byKey(const ValueKey('durationPreset_0')));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(const ValueKey('durationPreset_0'))).top,
        lessThan(contentBefore.top),
        reason: 'the content did not move, so this proves nothing about Done',
      );
      expect(tester.getRect(done), before);
    });

    testWidgets('it is reachable without scrolling', (tester) async {
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);

      final Rect done =
          tester.getRect(find.byKey(const ValueKey('durationDone')));
      expect(done.bottom,
          lessThanOrEqualTo(AddTileTestMatrix.narrow.height + 0.5));
      expect(done.top, greaterThanOrEqualTo(0));
    });

    testWidgets('the screen carries no helper tip', (tester) async {
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });

  group('Turning the wheel is not stolen by the list', () {
    /// The list's physics right now.
    ScrollPhysics? listPhysics(WidgetTester tester) =>
        tester.widget<ListView>(find.byType(ListView)).physics;

    testWidgets('the list stops scrolling while the wheel is held',
        (tester) async {
      // Circling the wheel is a pan, and its vertical component is
      // contested by the list's drag recognizer. When the list wins, the
      // gesture becomes a scroll — on a page whose content already fits,
      // that is the rubber-band bounce rather than rotation.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);
      expect(listPhysics(tester), isNot(isA<NeverScrollableScrollPhysics>()),
          reason: 'the list must scroll normally when the wheel is idle');

      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(wheel));
      await tester.pump();
      expect(listPhysics(tester), isA<NeverScrollableScrollPhysics>(),
          reason: 'while a finger is on the wheel the list must not scroll');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(listPhysics(tester), isNot(isA<NeverScrollableScrollPhysics>()),
          reason: 'the lock must lift when the finger comes up');
    });

    testWidgets('a cancelled pointer still releases the list', (tester) async {
      // A lock that could stick would leave the page permanently frozen.
      await pumpDuration(tester, viewSize: AddTileTestMatrix.narrow);
      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(wheel));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(listPhysics(tester), isNot(isA<NeverScrollableScrollPhysics>()));
    });

    testWidgets('dragging around the wheel changes the duration',
        (tester) async {
      // The point of the lock, asserted end to end: a real drag on the dial
      // must reach the dial and move the value, not scroll the page.
      await pumpDuration(tester,
          initial: const Duration(minutes: 30),
          viewSize: AddTileTestMatrix.narrow);

      final Finder wheel = find.byKey(const ValueKey('durationWheel'));
      await tester.ensureVisible(wheel);
      await tester.pumpAndSettle();

      // Measured against the GESTURE area, not the painted one: the dial
      // listens inside a box of painted/1.5, so points taken from the
      // painted rect can land outside the detector entirely.
      final Rect gestureBox = tester.getRect(find.descendant(
        of: wheel,
        matching: find.byType(GestureDetector),
      ));
      final Offset centre = gestureBox.center;
      final double r = gestureBox.width / 3;

      // Sweep from the bottom of the ring round to the left side.
      final TestGesture gesture =
          await tester.startGesture(centre + Offset(0, r));
      await gesture.moveTo(centre + Offset(-r * 0.7, r * 0.7));
      await tester.pump();
      await gesture.moveTo(centre + Offset(-r, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        isNot(const Duration(minutes: 30)),
        reason: 'the drag reached the list instead of the dial',
      );
    });
  });

  group('Dark theme', () {
    testWidgets('the wheel is not a white donut on a dark surface',
        (tester) async {
      // The unfilled ring was a radial gradient hardcoded to `Colors.white`,
      // so the wheel rendered light no matter what the palette said. The
      // colour-token test alone could not catch this: it asserted the values
      // this screen PASSES, and the track was not one of them.
      await pumpDurationDark(tester);

      final DialPainter painter = mountedPainter(tester);
      expect(painter.trackColor.computeLuminance(), lessThan(0.5),
          reason: 'the ring must be dark in the dark theme');
    });

    testWidgets('every dial colour still comes from the tokens',
        (tester) async {
      await pumpDurationDark(tester);

      final BuildContext ctx = tester.element(find.byType(DurationPicker));
      final tokens = TodayStatusTokens.of(ctx);
      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));

      final DialPainter painter = mountedPainter(tester);
      expect(painter.trackColor, tokens.surfaceSubtle);
      expect(painter.handleColor, tokens.brand);
      expect(painter.innerCircleColor, tokens.surface);
      expect(picker.markerColor, tokens.textSecondary);
    });

    testWidgets('the readout reads against the disc it sits on',
        (tester) async {
      // Light text on a light disc was the other half of the same bug.
      await pumpDurationDark(tester);

      final BuildContext ctx = tester.element(find.byType(DurationPicker));
      final tokens = TodayStatusTokens.of(ctx);
      final DurationPicker picker =
          tester.widget<DurationPicker>(find.byType(DurationPicker));

      final double disc =
          mountedPainter(tester).innerCircleColor.computeLuminance();
      final double text = picker.fontStyle!.color!.computeLuminance();
      expect((text - disc).abs(), greaterThan(0.3),
          reason: 'the readout must contrast with the disc behind it');
    });

    testWidgets('nothing overflows in the dark theme either', (tester) async {
      await pumpDurationDark(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('durationDone')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('The wheel clicks at every five minutes', () {
    /// Records the platform haptic calls the wheel makes.
    ///
    /// Asserted through the real channel rather than a callback seam: the
    /// click is the feature the user asked for, and a seam would let it be
    /// removed from the widget without any test noticing.
    List<String> recordHaptics(WidgetTester tester) {
      final List<String> calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String? ?? 'default');
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      return calls;
    }

    testWidgets('crossing a detent produces one click', (tester) async {
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      final List<String> haptics = recordHaptics(tester);

      tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
          .onChanged(const Duration(minutes: 35));
      await tester.pumpAndSettle();

      expect(haptics, hasLength(1));
    });

    testWidgets('moving within one detent stays silent', (tester) async {
      // The wheel reports continuously while a finger is down; clicking per
      // callback would rattle rather than detent.
      await pumpDuration(tester, initial: const Duration(minutes: 30));
      final List<String> haptics = recordHaptics(tester);

      final DurationWheel wheel = tester
          .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')));
      wheel.onChanged(const Duration(minutes: 31));
      await tester.pump();
      wheel.onChanged(const Duration(minutes: 32));
      await tester.pump();

      expect(haptics, isEmpty,
          reason: '31 and 32 both snap to 30, so no detent was crossed');
    });
  });

  group('Duration picker — navigation (D12)', () {
    testWidgets('backing out returns nothing', (tester) async {
      Duration? popped;
      bool returned = false;
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        locale: const Locale('en'),
        localeResolutionCallback: _resolve,
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<Duration>(
                  MaterialPageRoute<Duration>(
                    builder: (_) => const AddTileDurationScreen(
                      initialDuration: Duration(hours: 1),
                    ),
                  ),
                );
                returned = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget,
          reason: 'D12: secondary screens go Back, not Close');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(popped, isNull);
    });
  });
}
