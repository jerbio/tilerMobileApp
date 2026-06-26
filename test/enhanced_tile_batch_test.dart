import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/hourMarker.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/todaySummaryRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedWithinNowBatch.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/components/tilelist/proactiveAlertBanner.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnhancedTileBatch travel connector ordering', () {
    testWidgets(
      'renders the connector after intervening conflict groups and before its destination tile',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final day = DateTime(2026, 5, 15);
        final tiles = <SubCalendarEvent>[
          _buildTile(
            id: 'source',
            name: 'TilerWeb Sync',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 10, 45),
          ),
          _buildTile(
            id: 'conflict-1',
            name: 'Engr fix dev',
            start: DateTime(2026, 5, 15, 11),
            end: DateTime(2026, 5, 15, 11, 30),
          ),
          _buildTile(
            id: 'conflict-2',
            name: 'will be deleted',
            start: DateTime(2026, 5, 15, 11),
            end: DateTime(2026, 5, 15, 12),
          ),
          _buildTile(
            id: 'destination',
            name: 'Hiking Trail',
            address: 'Trailhead Parking',
            addressDescription: 'hiking trail',
            start: DateTime(2026, 5, 15, 12, 15),
            end: DateTime(2026, 5, 15, 13, 45),
            travelTimeBeforeMs: const Duration(minutes: 25).inMilliseconds.toDouble(),
            travelDetail: TravelDetail(
              before: TravelData(
                travelMedium: 'driving',
                startLocation: _location('123 Office St', 37.33, -122.03),
                endLocation: _location('456 Trail Rd', 37.44, -122.15),
                travelLegs: const [
                  TravelLeg(description: 'Head west on Highway 9'),
                ],
              ),
            ),
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ScheduleBloc(getContextCallBack: () => null),
                ),
                BlocProvider(
                  create: (_) =>
                      ScheduleSummaryBloc(getContextCallBack: () => null),
                ),
              ],
              child: Scaffold(
                body: SingleChildScrollView(
                  child: EnhancedTileBatch(
                    dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays,
                    tiles: tiles,
                    showProactiveAlerts: false,
                    showTimelineMarkers: false,
                    showEnhancedCards: true,
                    showConflictAlerts: true,
                    showTravelConnectors: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final connectorFinder = find.byType(TravelConnector);
        final conflictFinder = find.text('2 conflicts');
        final destinationFinder = find.text('Hiking Trail');

        expect(connectorFinder, findsOneWidget);
        expect(conflictFinder, findsOneWidget);
        expect(destinationFinder, findsOneWidget);

        final conflictY = tester.getTopLeft(conflictFinder).dy;
        final connectorY = tester.getTopLeft(connectorFinder).dy;
        final destinationY = tester.getTopLeft(destinationFinder).dy;

        expect(
          connectorY,
          greaterThan(conflictY),
          reason: 'The travel connector must render after the conflicting block that occurs before the destination tile.',
        );
        expect(
          connectorY,
          lessThan(destinationY),
          reason: 'The travel connector must render immediately before the destination tile it describes.',
        );
      },
    );
  });

  group('EnhancedWithinNowBatch travel connector ordering', () {
    testWidgets(
      'today view renders the connector after intervening conflict groups and before its destination tile',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final today = DateTime.now();
        DateTime at(int hour, [int minute = 0]) =>
            DateTime(today.year, today.month, today.day, hour, minute);

        final tiles = <SubCalendarEvent>[
          _buildTile(
            id: 'source',
            name: 'TilerWeb Sync',
            start: at(10),
            end: at(10, 45),
          ),
          _buildTile(
            id: 'conflict-1',
            name: 'Engr fix dev',
            start: at(11),
            end: at(11, 30),
          ),
          _buildTile(
            id: 'conflict-2',
            name: 'will be deleted',
            start: at(11),
            end: at(12),
          ),
          _buildTile(
            id: 'destination',
            name: 'Hiking Trail',
            address: 'Trailhead Parking',
            addressDescription: 'hiking trail',
            start: at(12, 15),
            end: at(13, 45),
            travelTimeBeforeMs:
                const Duration(minutes: 25).inMilliseconds.toDouble(),
            travelDetail: TravelDetail(
              before: TravelData(
                travelMedium: 'driving',
                startLocation:
                    _location('123 Office St', 37.33, -122.03),
                endLocation:
                    _location('456 Trail Rd', 37.44, -122.15),
                travelLegs: const [
                  TravelLeg(description: 'Head west on Highway 9'),
                ],
              ),
            ),
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      ScheduleBloc(getContextCallBack: () => null),
                ),
                BlocProvider(
                  create: (_) =>
                      ScheduleSummaryBloc(getContextCallBack: () => null),
                ),
              ],
              child: Scaffold(
                body: EnhancedWithinNowBatch(
                  tiles: tiles,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final connectorFinder = find.byType(TravelConnector);
        final conflictFinder = find.text('2 conflicts');
        final destinationFinder = find.text('Hiking Trail');

        expect(connectorFinder, findsOneWidget);
        expect(conflictFinder, findsOneWidget);
        expect(destinationFinder, findsOneWidget);

        final conflictY = tester.getTopLeft(conflictFinder).dy;
        final connectorY = tester.getTopLeft(connectorFinder).dy;
        final destinationY = tester.getTopLeft(destinationFinder).dy;

        expect(
          connectorY,
          greaterThan(conflictY),
          reason:
              'Today view: connector must render after the conflict group preceding the destination.',
        );
        expect(
          connectorY,
          lessThan(destinationY),
          reason:
              'Today view: connector must render immediately before the destination tile.',
        );
      },
    );
  });

  group('EnhancedTileBatch widget behavior', () {
    testWidgets('shows EmptyDayTile when tile list is empty', (tester) async {
      await _pumpETB(tester, []);
      expect(find.byType(EmptyDayTile), findsOneWidget);
    });

    testWidgets('renders viable tile names in the main tile list', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(
          id: 'a',
          name: 'Morning Standup',
          start: DateTime(2024, 6, 10, 9),
          end: DateTime(2024, 6, 10, 9, 30),
        ),
        _buildTile(
          id: 'b',
          name: 'Code Review',
          start: DateTime(2024, 6, 10, 11),
          end: DateTime(2024, 6, 10, 11, 30),
        ),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.text('Morning Standup'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);
    });

    testWidgets('hides non-viable tile from the main tile list', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(id: 'a', name: 'Visible Task', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 9, 30)),
        _buildTile(id: 'b', name: 'Ghost Task', start: DateTime(2024, 6, 10, 10), end: DateTime(2024, 6, 10, 10, 30)),
      ];
      tiles[1].isViable = false;
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.text('Visible Task'), findsOneWidget);
      expect(find.text('Ghost Task'), findsNothing);
    });

    testWidgets('routes needsAction RSVP tile to PendingRsvpBanner instead of main list', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(id: 'a', name: 'Regular Meeting', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 9, 30)),
        _buildRsvpTile(
          id: 'b',
          name: 'Pending Invite',
          start: DateTime(2024, 6, 10, 10),
          end: DateTime(2024, 6, 10, 10, 30),
          rsvp: RsvpStatus.needsAction,
        ),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.byType(PendingRsvpBanner), findsOneWidget);
    });

    testWidgets('routes declined RSVP tile to RSVP banner and excludes it from conflict detection', (tester) async {
      final day = DateTime(2024, 6, 10);
      // Two tiles at identical times — if both reached conflict detection they would form a conflict group.
      final tiles = [
        _buildTile(id: 'a', name: 'Work Session', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10)),
        _buildRsvpTile(
          id: 'b',
          name: 'Declined Event',
          start: DateTime(2024, 6, 10, 9),
          end: DateTime(2024, 6, 10, 10),
          rsvp: RsvpStatus.declined,
        ),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.byType(PendingRsvpBanner), findsOneWidget);
      expect(find.byType(ConflictSummaryBanner), findsNothing);
      expect(find.byType(CombinedAlertsBanner), findsNothing);
    });

    testWidgets('shows ConflictSummaryBanner for a single overlapping tile pair', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(id: 'c1', name: 'Task Alpha', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10)),
        _buildTile(id: 'c2', name: 'Task Beta', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10, 30)),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.byType(ConflictSummaryBanner), findsOneWidget);
      expect(find.byType(CombinedAlertsBanner), findsNothing);
    });

    testWidgets('shows CombinedAlertsBanner when conflicts and pending RSVP both exist', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(id: 'c1', name: 'Task Alpha', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10)),
        _buildTile(id: 'c2', name: 'Task Beta', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10, 30)),
        _buildRsvpTile(
          id: 'r1',
          name: 'Pending Invite',
          start: DateTime(2024, 6, 10, 14),
          end: DateTime(2024, 6, 10, 15),
          rsvp: RsvpStatus.needsAction,
        ),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.byType(CombinedAlertsBanner), findsOneWidget);
      expect(find.byType(ConflictSummaryBanner), findsNothing);
    });

    testWidgets('hides all TravelConnector widgets when showTravelConnectors is false', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        _buildTile(id: 'src', name: 'Office Meeting', start: DateTime(2024, 6, 10, 9), end: DateTime(2024, 6, 10, 10)),
        _buildTile(
          id: 'dst',
          name: 'Client Visit',
          start: DateTime(2024, 6, 10, 11),
          end: DateTime(2024, 6, 10, 12),
          address: '123 Main St',
          travelTimeBeforeMs: const Duration(minutes: 20).inMilliseconds.toDouble(),
          travelDetail: TravelDetail(
            before: TravelData(
              travelMedium: 'driving',
              startLocation: _location('Office', 37.0, -122.0),
              endLocation: _location('Client', 37.1, -122.1),
              travelLegs: const [TravelLeg(description: 'Head north')],
            ),
          ),
        ),
      ];
      await _pumpETB(
        tester,
        tiles,
        dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays,
        showTravelConnectors: false,
      );
      expect(find.byType(TravelConnector), findsNothing);
    });

    testWidgets('shows ExtendedTilesBanner for a tile with duration of at least 16 hours', (tester) async {
      final day = DateTime(2024, 6, 10);
      final tiles = [
        // 6:00 → 23:00 = 17 hours
        _buildTile(
          id: 'long',
          name: 'Day-Long Event',
          start: DateTime(2024, 6, 10, 6),
          end: DateTime(2024, 6, 10, 23),
        ),
      ];
      await _pumpETB(tester, tiles, dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays);
      expect(find.byType(ExtendedTilesBanner), findsOneWidget);
    });

    testWidgets('does not show ProactiveAlertBanner for a non-today day even with travel time', (tester) async {
      final day = DateTime(2020, 1, 1);
      final tiles = [
        _buildTile(
          id: 'travel',
          name: 'Past Event',
          start: DateTime(2020, 1, 1, 9),
          end: DateTime(2020, 1, 1, 10),
          travelTimeBeforeMs: const Duration(minutes: 15).inMilliseconds.toDouble(),
        ),
      ];
      await _pumpETB(
        tester,
        tiles,
        dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays,
        showProactiveAlerts: true,
      );
      expect(find.byType(ProactiveAlertBanner), findsNothing);
    });
  });

  group('EnhancedWithinNowBatch widget behavior', () {
    testWidgets('shows EmptyDayTile when tile list is empty', (tester) async {
      await _pumpEWNB(tester, []);
      expect(find.byType(EmptyDayTile), findsOneWidget);
    });

    testWidgets('always renders TodaySummaryRow regardless of tile count', (tester) async {
      final today = DateTime.now();
      final tiles = [
        _buildTile(
          id: 'a',
          name: 'Morning Task',
          start: DateTime(today.year, today.month, today.day, 9),
          end: DateTime(today.year, today.month, today.day, 9, 30),
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.byType(TodaySummaryRow), findsOneWidget);
    });

    testWidgets('wraps each main-list tile in a TileRowWithHourMarker', (tester) async {
      final today = DateTime.now();
      final tiles = [
        _buildTile(
          id: 'a',
          name: 'Task One',
          start: DateTime(today.year, today.month, today.day, 9),
          end: DateTime(today.year, today.month, today.day, 10),
        ),
        _buildTile(
          id: 'b',
          name: 'Task Two',
          start: DateTime(today.year, today.month, today.day, 11),
          end: DateTime(today.year, today.month, today.day, 12),
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.byType(TileRowWithHourMarker), findsWidgets);
    });

    testWidgets('renders SleepTileWidget when sleepTimeline is provided', (tester) async {
      final today = DateTime.now();
      final sleepTimeline = _buildTimeline(
        DateTime(today.year, today.month, today.day, 22),
        DateTime(today.year, today.month, today.day + 1, 7),
      );
      await _pumpEWNB(tester, [], sleepTimeline: sleepTimeline);
      expect(find.byType(SleepTileWidget), findsOneWidget);
    });

    testWidgets('routes needsAction RSVP tile to PendingRsvpBanner', (tester) async {
      final today = DateTime.now();
      final tiles = [
        _buildTile(
          id: 'a',
          name: 'Regular Task',
          start: DateTime(today.year, today.month, today.day, 9),
          end: DateTime(today.year, today.month, today.day, 10),
        ),
        _buildRsvpTile(
          id: 'b',
          name: 'Invite Response Needed',
          start: DateTime(today.year, today.month, today.day, 11),
          end: DateTime(today.year, today.month, today.day, 12),
          rsvp: RsvpStatus.needsAction,
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.byType(PendingRsvpBanner), findsOneWidget);
    });

    testWidgets('excludes declined tile from conflict detection', (tester) async {
      final today = DateTime.now();
      // Two tiles at the exact same time. The declined one is filtered out before conflict
      // detection runs, so only one tile remains — no conflict group is formed.
      final tiles = [
        _buildTile(
          id: 'a',
          name: 'Active Task',
          start: DateTime(today.year, today.month, today.day, 9),
          end: DateTime(today.year, today.month, today.day, 10),
        ),
        _buildRsvpTile(
          id: 'b',
          name: 'Declined Meeting',
          start: DateTime(today.year, today.month, today.day, 9),
          end: DateTime(today.year, today.month, today.day, 10),
          rsvp: RsvpStatus.declined,
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.text('2 conflicts'), findsNothing);
    });

    testWidgets('shows ProactiveAlertBanner alone for a future tile with travel time', (tester) async {
      final futureStart = DateTime.now().add(const Duration(hours: 2));
      final futureEnd = futureStart.add(const Duration(hours: 1));
      final tiles = [
        _buildTile(
          id: 'future',
          name: 'Client Drive',
          start: futureStart,
          end: futureEnd,
          travelTimeBeforeMs: const Duration(minutes: 30).inMilliseconds.toDouble(),
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.byType(ProactiveAlertBanner), findsOneWidget);
      expect(find.byType(CombinedAlertsBanner), findsNothing);
    });

    testWidgets('shows CombinedAlertsBanner when travel alert and pending RSVP both exist', (tester) async {
      final today = DateTime.now();
      final futureStart = today.add(const Duration(hours: 2));
      final futureEnd = futureStart.add(const Duration(hours: 1));
      final tiles = [
        _buildTile(
          id: 'future',
          name: 'Client Drive',
          start: futureStart,
          end: futureEnd,
          travelTimeBeforeMs: const Duration(minutes: 30).inMilliseconds.toDouble(),
        ),
        _buildRsvpTile(
          id: 'rsvp',
          name: 'Invite Pending',
          start: DateTime(today.year, today.month, today.day, 14),
          end: DateTime(today.year, today.month, today.day, 15),
          rsvp: RsvpStatus.needsAction,
        ),
      ];
      await _pumpEWNB(tester, tiles);
      expect(find.byType(CombinedAlertsBanner), findsOneWidget);
      expect(find.byType(ProactiveAlertBanner), findsNothing);
    });
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

SubCalendarEvent _buildTile({
  required String id,
  required String name,
  required DateTime start,
  required DateTime end,
  String? address,
  String? addressDescription,
  double? travelTimeBeforeMs,
  TravelDetail? travelDetail,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    address: address,
    addressDescription: addressDescription,
  );
  tile.travelTimeBefore = travelTimeBeforeMs;
  tile.travelDetail = travelDetail;
  return tile;
}

Location _location(String address, double latitude, double longitude) {
  final location = Location.fromLatitudeAndLongitude(
    latitude: latitude,
    longitude: longitude,
  );
  location.address = address;
  return location;
}

/// Builds a [SubCalendarEvent] with the given RSVP status.
/// Because [thirdpartyType] defaults to null, [isFromTiler] returns false,
/// which is required for RSVP filtering logic to apply.
SubCalendarEvent _buildRsvpTile({
  required String id,
  required String name,
  required DateTime start,
  required DateTime end,
  required RsvpStatus rsvp,
}) {
  return SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    rsvp: rsvp,
  );
}

/// Creates a [Timeline] spanning [start] to [end], used for sleep tile tests.
Timeline _buildTimeline(DateTime start, DateTime end) {
  return Timeline(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

/// Pumps an [EnhancedTileBatch] wrapped in the standard BLoC + theme scaffold.
Future<void> _pumpETB(
  WidgetTester tester,
  List<SubCalendarEvent> tiles, {
  int? dayIndex,
  bool showProactiveAlerts = false,
  bool showTravelConnectors = true,
  bool showConflictAlerts = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final idx =
      dayIndex ?? DateTime(2020, 1, 1).difference(DateTime.utc(1970, 1, 1)).inDays;
  await tester.pumpWidget(
    _buildTestApp(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
          BlocProvider(create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
        ],
        child: Scaffold(
          body: SingleChildScrollView(
            child: EnhancedTileBatch(
              dayIndex: idx,
              tiles: tiles,
              showProactiveAlerts: showProactiveAlerts,
              showTimelineMarkers: false,
              showEnhancedCards: true,
              showConflictAlerts: showConflictAlerts,
              showTravelConnectors: showTravelConnectors,
            ),
          ),
        ),
      ),
    ),
  );
  // Advance fake time past the 200 ms fade-in timer used by the empty-day path.
  // Note: pumpAndSettle is intentionally avoided here — SleepTileWidget embeds
  // a TimeScrub with a Timer.periodic(20 s) that would cause pumpAndSettle to
  // loop indefinitely. Two plain pumps are sufficient to process the initial
  // addPostFrameCallback and any resulting rebuilds.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(); // addPostFrameCallback from TimeScrub
  await tester.pump(); // settle rebuild
}

/// Pumps an [EnhancedWithinNowBatch] wrapped in the standard BLoC + theme scaffold.
Future<void> _pumpEWNB(
  WidgetTester tester,
  List<SubCalendarEvent> tiles, {
  Timeline? sleepTimeline,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    _buildTestApp(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
          BlocProvider(create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
        ],
        child: Scaffold(
          body: EnhancedWithinNowBatch(
            tiles: tiles,
            sleepTimeline: sleepTimeline,
          ),
        ),
      ),
    ),
  );
  // Advance fake time past the 200 ms fade-in timer used by the empty-day path.
  // Note: pumpAndSettle is intentionally avoided here — SleepTileWidget embeds
  // a TimeScrub with a Timer.periodic(20 s) that would cause pumpAndSettle to
  // loop indefinitely. Two plain pumps are sufficient to process the initial
  // addPostFrameCallback and any resulting rebuilds.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(); // addPostFrameCallback from TimeScrub
  await tester.pump(); // settle rebuild
}