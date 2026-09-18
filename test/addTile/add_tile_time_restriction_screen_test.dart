// Step 6.3 — the Time restrictions screen: Anytime / Work hours / Personal
// hours / Custom hours (D67–D73).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileTimeRestrictionScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';
import 'restriction_hours_draft_test.dart' as fx;

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    requested ?? const Locale('en');

/// A source the test drives by hand.
class FakeProfileSource implements AddTileRestrictionProfileSource {
  Completer<NamedRestrictionProfiles> gate =
      Completer<NamedRestrictionProfiles>();
  int loads = 0;
  final List<(RestrictionProfile, NamedRestrictionProfileType)> saves = [];

  @override
  Future<NamedRestrictionProfiles> load() {
    loads++;
    return gate.future;
  }

  @override
  Future<RestrictionProfile> save(
      RestrictionProfile profile, NamedRestrictionProfileType type) async {
    saves.add((profile, type));
    return profile;
  }
}

Finder key(String k) => find.byKey(ValueKey(k));

TimeRestrictionResult? result;
bool doneCalled = false;
final List<HoursEditorRequest> editorRequests = <HoursEditorRequest>[];

/// What the fake editor hands back on the next open; null = backed out.
HoursEditorResult? editorAnswer;

Future<void> pumpScreen(
  WidgetTester tester, {
  RestrictionProfile? initial,
  required FakeProfileSource source,
  Size viewSize = AddTileTestMatrix.standard,
  double textScale = 1.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  result = null;
  doneCalled = false;
  editorRequests.clear();
  editorAnswer = null;
  await tester.pumpWidget(MaterialApp(
    theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AddTileTimeRestrictionScreen(
      initial: initial,
      source: source,
      onDone: (TimeRestrictionResult r) {
        result = r;
        doneCalled = true;
      },
      openHoursEditor: (BuildContext _, HoursEditorRequest request) async {
        editorRequests.add(request);
        return editorAnswer;
      },
    ),
  ));
  await tester.pump();
}

/// Resolves the load and lets the rows build.
Future<void> loaded(WidgetTester tester, FakeProfileSource source,
    {RestrictionProfile? work, RestrictionProfile? personal}) async {
  source.gate
      .complete(NamedRestrictionProfiles(work: work, personal: personal));
  await tester.pump();
  await tester.pump();
}

Future<void> tapDone(WidgetTester tester) async {
  await tester.ensureVisible(key('restrictionDone'));
  await tester.tap(key('restrictionDone'));
  await tester.pump();
}

bool selectedOf(WidgetTester tester, String k) =>
    tester.widget<TimeRestrictionChoiceRow>(key(k)).selected;

void main() {
  final RestrictionProfile work = fx.weekdays(id: 'work-1');
  final RestrictionProfile personal =
      fx.weekdays(start: fx.sixPm, end: fx.tenPm, id: 'personal-1');

  group('Rows and summaries', () {
    testWidgets('four rows; Anytime selected for a tile with no profile',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: personal);
      for (final TimeRestrictionChoice c in TimeRestrictionChoice.values) {
        expect(key('restrictionChoice_${c.name}'), findsOneWidget,
            reason: c.name);
      }
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isTrue);
      expect(selectedOf(tester, 'restrictionChoice_work'), isFalse);
      expect(find.text(testL10n.addTileRestrictionWork), findsOneWidget);
      expect(find.text(testL10n.addTileRestrictionPersonal), findsOneWidget);
      expect(find.text(testL10n.addTileRestrictionCustom), findsOneWidget);
      await tester.scrollUntilVisible(
          find.text(testL10n.addTileRestrictionTip), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(testL10n.addTileRestrictionTip), findsOneWidget);
    });

    testWidgets('Work and Personal print their grouped hours', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: personal);
      expect(find.text('Mon – Fri · 9:00 AM – 6:00 PM'), findsOneWidget);
      expect(find.text('Mon – Fri · 6:00 PM – 10:00 PM'), findsOneWidget);
    });

    testWidgets('an all-day profile reads "All day" (D74)', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source,
          work: fx.weekdays(start: fx.nine, end: fx.nine));
      expect(
          find.text(testL10n.addTileRestrictionWindow(
              'Mon – Fri', testL10n.addTileRestrictionAllDay, '')),
          findsNothing,
          reason: 'not the window template with an empty end');
      expect(find.text('Mon – Fri · All day'), findsOneWidget);
    });

    testWidgets('a tile already on Work hours (by id) preselects Work',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      final RestrictionProfile tilesCopy = fx.weekdays(id: 'work-1');
      await pumpScreen(tester, initial: tilesCopy, source: source);
      await loaded(tester, source, work: work, personal: personal);
      expect(selectedOf(tester, 'restrictionChoice_work'), isTrue);
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isFalse);
    });

    testWidgets('an ad-hoc profile preselects Custom and prints its hours',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      final RestrictionProfile adHoc =
          fx.weekdays(start: fx.ten, end: fx.four, id: null);
      await pumpScreen(tester, initial: adHoc, source: source);
      await loaded(tester, source, work: work, personal: personal);
      expect(selectedOf(tester, 'restrictionChoice_custom'), isTrue);
      expect(find.text('Mon – Fri · 10:00 AM – 4:00 PM'), findsOneWidget);
    });
  });

  group('Loading and failure (D73)', () {
    testWidgets('a skeleton stands in for Work and Personal while loading',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      expect(key('restrictionProfilesLoading'), findsOneWidget);
      expect(key('restrictionChoice_work'), findsNothing);
      expect(key('restrictionChoice_anytime'), findsOneWidget,
          reason: 'Anytime and Custom never wait on the network');
      expect(key('restrictionChoice_custom'), findsOneWidget);
      await loaded(tester, source, work: work);
      expect(key('restrictionProfilesLoading'), findsNothing);
      expect(key('restrictionChoice_work'), findsOneWidget);
    });

    testWidgets('a failed load shows a callout; Retry asks again',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      source.gate.completeError(TilerError(Message: 'down'));
      await tester.pump();
      await tester.pump();
      expect(key('restrictionLoadFailed'), findsOneWidget);
      expect(find.text(testL10n.addTileRestrictionLoadFailed), findsOneWidget);
      expect(key('restrictionChoice_work'), findsNothing);
      // Anytime and Custom still work.
      await tester.tap(key('restrictionChoice_anytime'));
      await tester.pump();
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isTrue);

      source.gate = Completer<NamedRestrictionProfiles>();
      await tester.tap(key('restrictionRetry'));
      await tester.pump();
      expect(source.loads, 2);
      expect(key('restrictionProfilesLoading'), findsOneWidget);
      await loaded(tester, source, work: work, personal: personal);
      expect(key('restrictionLoadFailed'), findsNothing);
      expect(key('restrictionChoice_work'), findsOneWidget);
    });

    testWidgets(
        'a missing profile reads Not set up, cannot be selected, and its '
        'arrow opens the editor in profile mode', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: null);
      expect(
          find.descendant(
              of: key('restrictionChoice_personal'),
              matching: find.text(testL10n.addTileRestrictionNotSetUp)),
          findsOneWidget);
      await tester.tap(key('restrictionChoice_personal'));
      await tester.pump();
      expect(selectedOf(tester, 'restrictionChoice_personal'), isFalse);
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isTrue);

      await tester.tap(key('restrictionEdit_personal'));
      await tester.pump();
      expect(editorRequests.single.profileType,
          NamedRestrictionProfileType.personal);
      expect(editorRequests.single.seed, isNull);
    });

    testWidgets('a disabled server profile counts as Not set up',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source,
          work: fx.weekdays(id: 'work-1')..isEnabled = false);
      expect(
          find.descendant(
              of: key('restrictionChoice_work'),
              matching: find.text(testL10n.addTileRestrictionNotSetUp)),
          findsOneWidget);
    });
  });

  group('Choosing and Done', () {
    testWidgets('Work → Done returns the loaded Work profile itself',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: personal);
      await tester.tap(key('restrictionChoice_work'));
      await tester.pump();
      expect(selectedOf(tester, 'restrictionChoice_work'), isTrue);
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isFalse);
      await tapDone(tester);
      expect(result!.choice, TimeRestrictionChoice.work);
      expect(result!.profile, same(work),
          reason: 'the object with the server id, so the mapper sends '
              'RestrictionProfileId');
    });

    testWidgets('Anytime → Done returns no profile; Back returns nothing',
        (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester,
          initial: fx.weekdays(id: 'work-1'), source: source);
      await loaded(tester, source, work: work);
      await tester.tap(key('restrictionChoice_anytime'));
      await tester.pump();
      await tapDone(tester);
      expect(result!.choice, TimeRestrictionChoice.anytime);
      expect(result!.profile, isNull);
    });

    testWidgets(
        'the Custom row opens the editor seeded with the current '
        'custom hours, else the Weekdays 9–6 preset (D68)', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work);
      await tester.tap(key('restrictionChoice_custom'));
      await tester.pump();
      final HoursEditorRequest first = editorRequests.single;
      expect(first.profileType, isNull, reason: 'ad-hoc mode');
      expect(describeRestrictionProfile(first.seed).single.days,
          <int>[1, 2, 3, 4, 5]);
      expect(describeRestrictionProfile(first.seed).single.end,
          const TimeOfDay(hour: 18, minute: 0));

      // The editor answers: Custom is now selected with those hours.
      final RestrictionProfile adHoc =
          fx.weekdays(start: fx.ten, end: fx.four, id: null);
      editorAnswer = HoursEditorResult(adHoc);
      await tester.tap(key('restrictionEdit_custom'));
      await tester.pump();
      expect(selectedOf(tester, 'restrictionChoice_custom'), isTrue);
      expect(find.text('Mon – Fri · 10:00 AM – 4:00 PM'), findsOneWidget);

      // Re-entering seeds from THOSE hours.
      editorAnswer = null;
      await tester.tap(key('restrictionChoice_custom'));
      await tester.pump();
      expect(editorRequests.last.seed, same(adHoc));
      expect(selectedOf(tester, 'restrictionChoice_custom'), isTrue,
          reason: 'backing out changes nothing');

      await tapDone(tester);
      expect(result!.choice, TimeRestrictionChoice.custom);
      expect(result!.profile, same(adHoc));
    });

    testWidgets('an editor answer with no days is Anytime', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester,
          initial: fx.weekdays(start: fx.ten, end: fx.four, id: null),
          source: source);
      await loaded(tester, source, work: work);
      expect(selectedOf(tester, 'restrictionChoice_custom'), isTrue);
      editorAnswer = const HoursEditorResult(null);
      await tester.tap(key('restrictionEdit_custom'));
      await tester.pump();
      expect(selectedOf(tester, 'restrictionChoice_anytime'), isTrue);
      expect(selectedOf(tester, 'restrictionChoice_custom'), isFalse);
    });

    testWidgets(
        'the Work arrow opens the editor in profile mode; the saved copy '
        'replaces the row and is selected (D67)', (tester) async {
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: personal);
      final RestrictionProfile saved =
          fx.weekdays(start: fx.ten, end: fx.four, id: 'work-1');
      editorAnswer = HoursEditorResult(saved);
      await tester.tap(key('restrictionEdit_work'));
      await tester.pump();
      expect(
          editorRequests.single.profileType, NamedRestrictionProfileType.work);
      expect(editorRequests.single.seed, same(work));
      expect(find.text('Mon – Fri · 10:00 AM – 4:00 PM'), findsOneWidget);
      expect(selectedOf(tester, 'restrictionChoice_work'), isTrue);
      await tapDone(tester);
      expect(result!.profile, same(saved));
    });
  });

  group('Semantics and matrix', () {
    testWidgets('rows are selectable buttons; the arrow is its own node',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final FakeProfileSource source = FakeProfileSource();
      await pumpScreen(tester, source: source);
      await loaded(tester, source, work: work, personal: personal);
      expect(
          tester.getSemantics(key('restrictionChoice_anytime')),
          matchesSemantics(
              isButton: true,
              isSelected: true,
              hasSelectedState: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
              label: '${testL10n.anytime}, '
                  '${testL10n.addTileRestrictionAnytimeHelper}'));
      expect(
          tester.getSemantics(key('restrictionEdit_work')),
          // An IconButton: focusable, enabled, and named through its
          // tooltip.
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true,
              hasEnabledState: true,
              isEnabled: true,
              tooltip: testL10n
                  .addTileRestrictionEdit(testL10n.addTileRestrictionWork)));
      handle.dispose();
    });

    testWidgets('320pt with large text, and dark, without overflow',
        (tester) async {
      for (final bool dark in <bool>[false, true]) {
        final FakeProfileSource source = FakeProfileSource();
        await pumpScreen(tester,
            source: source,
            viewSize: AddTileTestMatrix.narrow,
            textScale: AddTileTestMatrix.largeTextScale,
            dark: dark);
        await loaded(tester, source, work: work, personal: personal);
        await tapDone(tester);
        expect(tester.takeException(), isNull, reason: 'dark=$dark');
      }
    });
  });
}
