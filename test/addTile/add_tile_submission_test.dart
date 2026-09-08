// Step 1.3 completion — submitting the draft to the backend (D49).
//
// Until now the CTA built a payload and showed it in a debug SnackBar. The
// mapping was never the risk — `add_tile_request_mapper_parity_test.dart`
// pins it field-for-field against the legacy flow — so what needed covering is
// the ORCHESTRATION around the call: what reaches the caller, what the user is
// told when it fails, and that a failure leaves the draft intact.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileSubmission.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

final now = DateTime(2026, 9, 8, 9, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// A submission that records what it was asked to send and answers with
/// whatever the test wants.
class FakeSubmission implements AddTileSubmission {
  FakeSubmission({this.result, this.onCreate});

  final AddTileSubmissionResult? result;
  final AddTileSubmissionResult Function(NewTile)? onCreate;

  final List<NewTile> sent = <NewTile>[];

  @override
  Future<AddTileSubmissionResult> create(NewTile tile) async {
    sent.add(tile);
    if (onCreate != null) return onCreate!(tile);
    return result ?? const AddTileSubmissionResult.failure('api_rejected');
  }
}

Future<void> pumpShell(
  WidgetTester tester, {
  required AddTileDraft draft,
  AddTileSubmission? submission,
  Map<String, dynamic>? newTileParams,
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<SubCalendarTileBloc>(
        create: (_) => SubCalendarTileBloc(getContextCallBack: () => null),
      ),
      BlocProvider<ScheduleBloc>(
        create: (_) => ScheduleBloc(getContextCallBack: () => null),
      ),
    ],
    child: MaterialApp(
      theme: TileThemeData.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localeResolutionCallback: _resolve,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AddTileRedesignScreen(
        draft: draft,
        now: now,
        submission: submission,
        newTileParams: newTileParams,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

AddTileDraft submittableFixed() {
  final draft = AddTileDraft.fixed(now: now);
  draft.name = 'Weekend run';
  draft.setUserStartTime(DateTime(2026, 9, 12, 18, 0));
  draft.setUserDuration(const Duration(hours: 2));
  return draft;
}

void main() {
  group('The submission result flattens both kinds of failure', () {
    // `addNewTile` RETURNS a TilerError rather than throwing it, and reserves
    // exceptions for transport problems. Both are failures to a user, so the
    // shell must not have to know the difference.
    test('a created tile is a success', () {
      final SubCalendarEvent event = SubCalendarEvent(name: 'Weekend run');
      final result = AddTileSubmissionResult.success(event);
      expect(result.failed, isFalse);
      expect(result.tile, same(event));
      expect(result.reasonCode, isNull);
    });

    test('a failure carries an allow-listed reason and no tile', () {
      const result = AddTileSubmissionResult.failure('api_rejected');
      expect(result.failed, isTrue);
      expect(result.tile, isNull);
      expect(result.reasonCode, 'api_rejected');
    });
  });

  group('A successful submission', () {
    testWidgets('sends the mapped payload', (tester) async {
      final fake = FakeSubmission(
          result: AddTileSubmissionResult.success(
              SubCalendarEvent(name: 'Weekend run')));
      await pumpShell(tester, draft: submittableFixed(), submission: fake);

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(fake.sent, hasLength(1));
      expect(fake.sent.single.Name, 'Weekend run');
      expect(fake.sent.single.DurationMinute, '120');
      expect(fake.sent.single.Rigid, 'true');
    });

    testWidgets('writes the created tile into the caller\'s slot',
        (tester) async {
      // The legacy by-reference contract: whoever pushed the route reads
      // `newTileParams['newTile']` once it pops.
      final SubCalendarEvent created = SubCalendarEvent(name: 'Weekend run');
      final Map<String, dynamic> params = <String, dynamic>{};
      await pumpShell(
        tester,
        draft: submittableFixed(),
        submission:
            FakeSubmission(result: AddTileSubmissionResult.success(created)),
        newTileParams: params,
      );

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(params['newTile'], same(created));
    });

    testWidgets('closes the screen', (tester) async {
      await pumpShell(
        tester,
        draft: submittableFixed(),
        submission: FakeSubmission(
            result: AddTileSubmissionResult.success(
                SubCalendarEvent(name: 'Weekend run'))),
      );

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addTileCta')), findsNothing,
          reason: 'a submitted draft must not leave the user on the form');
    });
  });

  group('A failed submission', () {
    testWidgets('tells the user, rather than failing silently', (tester) async {
      // Previously the catch recorded an analytics outcome and showed nothing:
      // the button simply re-enabled itself and the user was left guessing.
      await pumpShell(
        tester,
        draft: submittableFixed(),
        submission: FakeSubmission(
            result: const AddTileSubmissionResult.failure('api_rejected')),
      );

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addTileSubmitError')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('keeps the user on the form with the draft intact',
        (tester) async {
      final AddTileDraft draft = submittableFixed();
      await pumpShell(
        tester,
        draft: draft,
        submission: FakeSubmission(
            result: const AddTileSubmissionResult.failure('api_rejected')),
      );

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addTileCta')), findsOneWidget);
      expect(draft.name, 'Weekend run');
      expect(draft.duration, const Duration(hours: 2));
    });

    testWidgets('nothing reaches the caller\'s slot', (tester) async {
      final Map<String, dynamic> params = <String, dynamic>{};
      await pumpShell(
        tester,
        draft: submittableFixed(),
        submission: FakeSubmission(
            result: const AddTileSubmissionResult.failure('api_rejected')),
        newTileParams: params,
      );

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(params, isEmpty);
    });

    testWidgets('Retry sends again', (tester) async {
      // The whole point of preserving the draft.
      int attempts = 0;
      final fake = FakeSubmission(onCreate: (_) {
        attempts++;
        return attempts == 1
            ? const AddTileSubmissionResult.failure('network_timeout')
            : AddTileSubmissionResult.success(
                SubCalendarEvent(name: 'Weekend run'));
      });
      await pumpShell(tester, draft: submittableFixed(), submission: fake);

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
    });
  });

  group('Without an orchestrator', () {
    testWidgets('the CTA writes nothing', (tester) async {
      // The harness path. It must stay a report, never a silent no-op that
      // looks like a successful save.
      await pumpShell(tester, draft: submittableFixed());

      await tester.tap(find.byKey(const ValueKey('addTileCta')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Draft mapped (debug)'), findsOneWidget);
      expect(find.byKey(const ValueKey('addTileCta')), findsOneWidget,
          reason: 'nothing was submitted, so the form stays open');
    });
  });
}
