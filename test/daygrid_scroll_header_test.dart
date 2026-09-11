// DayGridScrollHeader (P6 Step 16.4, C21/C23) — built in isolation.
//
// The grid-mode header that scrolls away with the day (mounted into
// DayGridWidget.header in Step 16.5). Top to bottom: big date, alert
// subtitle, the compact swipeable day strip, then one banner row per alert
// kind (conflicts, pending RSVP). Covers:
//   * date title formatting; subtitle pluralization + "All clear";
//   * conflict row iff conflicts, RSVP row iff pending RSVP, both when both;
//   * row taps open the same modals the chips did (conflict cards / pending
//     RSVP sheet);
//   * the day strip is DayRibbonCarousel in compact mode: no 130px body, no
//     today top-border, and a day tap dispatches DateChangeEvent exactly as
//     the ribbon always has;
//   * DayRibbonCarousel/DayButton default (compact: false) is untouched.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridScrollHeader.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayButton.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

/// Records UiDateManagerBloc events without running them.
class _RecordingDateBloc extends UiDateManagerBloc {
  final List<UiDateManagerEvent> events = <UiDateManagerEvent>[];

  @override
  void add(UiDateManagerEvent event) {
    events.add(event);
    super.add(event);
  }
}

SubCalendarEvent _tile({
  required String id,
  required DateTime start,
  required DateTime end,
  RsvpStatus? rsvp,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    rsvp: rsvp,
  );
  tile.isViable = true;
  return tile;
}

final DateTime _day = DateTime(2027, 1, 15); // a Friday

List<TilerEvent> _conflictTiles() => [
      _tile(id: 'c1', start: _day.add(const Duration(hours: 9)),
          end: _day.add(const Duration(hours: 11))),
      _tile(id: 'c2', start: _day.add(const Duration(hours: 10)),
          end: _day.add(const Duration(hours: 12))),
    ];

List<TilerEvent> _rsvpTiles() => [
      _tile(
          id: 'r1',
          start: _day.add(const Duration(hours: 14)),
          end: _day.add(const Duration(hours: 15)),
          rsvp: RsvpStatus.needsAction),
    ];

Widget _buildApp({
  required UiDateManagerBloc dateBloc,
  required Widget child,
}) {
  final scheduleBloc = ScheduleBloc(getContextCallBack: () => null);
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: dateBloc),
        BlocProvider.value(value: scheduleBloc),
      ],
      child: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

Widget _header(List<TilerEvent> tiles) =>
    DayGridScrollHeader(currentDate: _day, tiles: tiles);

/// The legacy ribbon body: the unique `height: 130` Container.
Finder _legacyRibbonBody() => find.byWidgetPredicate(
    (w) => w is Container && w.constraints?.maxHeight == 130);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayGridScrollHeader — title + subtitle', () {
    testWidgets('renders the full date and "All clear" on a clean day',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(const [])));
      await tester.pump();

      expect(find.text('Fri, Jan 15, 2027'), findsOneWidget);
      expect(find.text('All clear'), findsOneWidget);
      expect(find.byKey(DayGridScrollHeader.conflictRowKey), findsNothing);
      expect(find.byKey(DayGridScrollHeader.rsvpRowKey), findsNothing);
    });

    testWidgets('pluralizes the subtitle from the alert counts',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(
          dateBloc: dateBloc,
          child: _header([..._conflictTiles(), ..._rsvpTiles()])));
      await tester.pump();

      expect(find.text('2 conflicts · 1 RSVP need attention'), findsOneWidget);
    });

    testWidgets('a single pending RSVP reads as singular', (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(_rsvpTiles())));
      await tester.pump();

      expect(find.text('1 RSVP needs attention'), findsOneWidget);
    });
  });

  group('DayGridScrollHeader — banner rows (C21)', () {
    testWidgets('conflict row only when there are conflicts', (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(_conflictTiles())));
      await tester.pump();

      expect(find.byKey(DayGridScrollHeader.conflictRowKey), findsOneWidget);
      expect(find.byKey(DayGridScrollHeader.rsvpRowKey), findsNothing);
      expect(find.text('2 conflicts'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('RSVP row only when there are pending RSVPs', (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(_rsvpTiles())));
      await tester.pump();

      expect(find.byKey(DayGridScrollHeader.rsvpRowKey), findsOneWidget);
      expect(find.byKey(DayGridScrollHeader.conflictRowKey), findsNothing);
      expect(find.text('1 RSVP'), findsOneWidget);
      expect(find.text('Respond'), findsOneWidget);
    });

    testWidgets('both rows when both alert kinds are present', (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(
          dateBloc: dateBloc,
          child: _header([..._conflictTiles(), ..._rsvpTiles()])));
      await tester.pump();

      expect(find.byKey(DayGridScrollHeader.conflictRowKey), findsOneWidget);
      expect(find.byKey(DayGridScrollHeader.rsvpRowKey), findsOneWidget);
    });

    testWidgets('tapping the conflict row opens the conflict cards sheet',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(_conflictTiles())));
      await tester.pump();

      await tester.tap(find.byKey(DayGridScrollHeader.conflictRowKey));
      await tester.pumpAndSettle();

      // The sheet's header: "{count} Conflicting Tiles".
      expect(find.text('2 Conflicting Tiles'), findsOneWidget);
    });

    testWidgets('tapping the RSVP row opens the pending-RSVP sheet',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(_rsvpTiles())));
      await tester.pump();

      await tester.tap(find.byKey(DayGridScrollHeader.rsvpRowKey));
      await tester.pumpAndSettle();

      expect(find.text('Pending Responses'), findsOneWidget);
    });
  });

  group('DayGridScrollHeader — compact day strip (C23)', () {
    testWidgets('uses DayRibbonCarousel in compact mode (no 130px body)',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(const [])));
      await tester.pump();

      final ribbon =
          tester.widget<DayRibbonCarousel>(find.byType(DayRibbonCarousel));
      expect(ribbon.compact, isTrue);
      expect(ribbon.topMargin, 0);
      expect(_legacyRibbonBody(), findsNothing);
      // Compact buttons: the strip renders 5 days around the shown day.
      expect(find.byType(DayButton), findsNWidgets(5));
      expect(find.text('15'), findsOneWidget);
      // The strip is short: well under the legacy 130px + 50px margin.
      final stripHeight =
          tester.getSize(find.byType(DayRibbonCarousel)).height;
      expect(stripHeight, lessThanOrEqualTo(80));
    });

    testWidgets('tapping a day dispatches DateChangeEvent', (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(
          _buildApp(dateBloc: dateBloc, child: _header(const [])));
      await tester.pump();

      await tester.tap(find.text('16'));
      await tester.pump();

      final changes = dateBloc.events.whereType<DateChangeEvent>().toList();
      expect(changes, hasLength(1));
      expect(changes.single.selectedDate.universalDayIndex,
          _day.add(const Duration(days: 1)).universalDayIndex);
      expect(changes.single.dateChangeTrigger, DateChangeTrigger.buttonPress);
    });
  });

  group('DayRibbonCarousel default stays legacy', () {
    testWidgets('compact defaults to false and keeps the 130px body',
        (tester) async {
      final dateBloc = _RecordingDateBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(
        dateBloc: dateBloc,
        child: SizedBox(
          height: 200,
          child: Stack(children: [
            DayRibbonCarousel(Utility.currentTime().dayDate),
          ]),
        ),
      ));
      await tester.pump();

      final ribbon =
          tester.widget<DayRibbonCarousel>(find.byType(DayRibbonCarousel));
      expect(ribbon.compact, isFalse);
      expect(_legacyRibbonBody(), findsOneWidget);
    });
  });
}
