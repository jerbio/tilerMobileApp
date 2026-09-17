// What the user typed into the preview add sheet must reach the redesign
// when they choose More options (D64).
//
// `previewAddWidget` already builds a `SimpleAdditionTile` from its
// `newTile` and pushes it as the `/AddTileRedesign` argument, and the shell
// seeds its draft from it. The break was one step earlier: the sheet only
// reported `onTileUpdate` when a PREDICTION landed (a location or duration
// came back), never on the name change itself. So the parent's `newTile`
// stayed null — and More options opened blank — whenever the user tapped it
// before the prediction returned, typed a name too short to predict on, or
// got an empty prediction.
//
// These drive the real widget through the real button and read the argument
// the route was pushed with.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// The argument `/AddTileRedesign` was pushed with, or null if never pushed.
Object? pushedArguments;

Widget _wrap(Widget child) {
  final scheduleBloc = ScheduleBloc(getContextCallBack: () => null);
  final scheduleSummaryBloc =
      ScheduleSummaryBloc(getContextCallBack: () => null);
  final vibeChatBloc = VibeChatBloc(
    scheduleBloc: scheduleBloc,
    scheduleSummaryBloc: scheduleSummaryBloc,
    getContextCallBack: () => null,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: scheduleBloc),
      BlocProvider.value(value: scheduleSummaryBloc),
      BlocProvider(create: (_) => ForecastBloc(getContextCallBack: () => null)),
      BlocProvider(
          create: (_) => SubCalendarTileBloc(getContextCallBack: () => null)),
      BlocProvider(create: (_) => UiDateManagerBloc()),
      BlocProvider.value(value: vibeChatBloc),
    ],
    child: MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: child),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/AddTileRedesign') {
          pushedArguments = settings.arguments;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('redesign')),
            settings: settings,
          );
        }
        return null;
      },
    ),
  );
}

Future<void> pumpSheet(WidgetTester tester) async {
  pushedArguments = null;
  // Tall and wide: the sheet's own column is fixed-height and overflows a
  // phone-sized test viewport during the route transition, which is a
  // pre-existing layout matter and not what this test is about.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester
      .pumpWidget(_wrap(SingleChildScrollView(child: PreviewAddWidget())));
  await tester.pump();
}

/// Types into the sheet's name field. The sheet has one text field.
Future<void> typeName(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pump();
}

Future<void> tapMoreOptions(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_time));
  await tester.pump();
  await tester.pump();
}

/// Tears the sheet down and lets its prediction debounce elapse, so no
/// timer outlives the test. Everything asserted has already happened by
/// then. Tearing down FIRST is the realistic order: More options pops the
/// sheet, so on device the debounce always fires after the sheet is gone.
Future<void> drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

PreTile pushedPreTile() {
  expect(pushedArguments, isA<PreTile>(),
      reason: 'More options must push the prefill as the route argument');
  return pushedArguments as PreTile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the typed name reaches More options before any prediction',
      (tester) async {
    // The common case: the user types and goes straight to More options,
    // inside the prediction debounce.
    await pumpSheet(tester);
    await typeName(tester, 'Dentist appointment');
    await tapMoreOptions(tester);

    expect(pushedPreTile().description, 'Dentist appointment');
    await drainTimers(tester);
  });

  testWidgets('a name too short to predict on still transfers', (tester) async {
    // Prediction needs more than a couple of characters; the name itself
    // has no such threshold.
    await pumpSheet(tester);
    await typeName(tester, 'Gy');
    await tapMoreOptions(tester);

    expect(pushedPreTile().description, 'Gy');
    await drainTimers(tester);
  });

  testWidgets('the LATEST name is what transfers', (tester) async {
    // A stale reference would carry the first value typed.
    await pumpSheet(tester);
    await typeName(tester, 'Gym');
    await typeName(tester, 'Gym session');
    await tapMoreOptions(tester);

    expect(pushedPreTile().description, 'Gym session');
    await drainTimers(tester);
  });

  testWidgets('leaving the sheet mid-debounce fires no stale prediction',
      (tester) async {
    // More options pops the sheet. A debounce that outlives it would call
    // setState on a disposed State — an assertion on device in debug, and
    // a wasted request in release.
    await pumpSheet(tester);
    await typeName(tester, 'Dentist appointment');
    await tapMoreOptions(tester);

    await drainTimers(tester);
    expect(tester.takeException(), isNull,
        reason: 'the debounce must be cancelled with the sheet');
  });

  testWidgets('a cleared name transfers as no name', (tester) async {
    await pumpSheet(tester);
    await typeName(tester, 'Gym');
    await typeName(tester, '');
    await tapMoreOptions(tester);

    expect(pushedPreTile().description, anyOf(isNull, isEmpty));
    await drainTimers(tester);
  });
}
