// TileShare redesign Step 9.11b (T21-T25, §5.9): the accept-preview page. A
// one-day strip (the Daily grid in preview mode) as context, a draggable sheet
// as the product: the time the task lands, Accept and Accept & lock beside it,
// Decline, and an honest message for every other state. Driven by the real
// cubit over the in-memory preview source.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_cubit.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/previewTiles.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/tileSharePreviewPage.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';
import 'helpers/tileshare_preview_fixtures.dart';

final DateTime _now = DateTime.fromMillisecondsSinceEpoch(1789500000000 + 60000);

TileSharePreview _viable() =>
    TileSharePreview.fromJson(previewFixture('preview_viable'));

DateTime _dayOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day);
}

class _Rig {
  final FakeTileSharePreviewSource source;
  final FakeTileShareAssignmentsSource assignments;
  late final TileSharePreviewCubit cubit;
  Object? popResult = 'not popped';

  _Rig({TileSharePreview? preview, FakeTileSharePreviewSource? source})
      : source = source ??
            FakeTileSharePreviewSource(preview ?? _viable(), optionPages: [
              PreviewOptionsPage.fromJson(previewFixture('options_page')),
            ]),
        assignments = FakeTileShareAssignmentsSource(
            [tsDesignatedTile(kPreviewAssignmentId)]) {
    cubit = TileSharePreviewCubit(
      source: this.source,
      assignments: assignments,
      assignmentId: kPreviewAssignmentId,
      pendingStore: FakePendingAcceptStore(),
      clock: () => _now,
    );
  }
}

Widget _app(_Rig rig, {ThemeData? theme, double textScale = 1}) => MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                rig.popResult = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                            value: rig.cubit,
                            child: TileSharePreviewPage(now: _now))));
              },
              child: const Text('open preview'),
            ),
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {Size size = const Size(390, 844),
    ThemeData? theme,
    double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh tree, so a second open in one test starts on a fresh navigator.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_app(rig, theme: theme, textScale: textScale));
  await tester.tap(find.text('open preview'));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));
bool _visible(Finder f) => f.hitTestable().evaluate().isNotEmpty;

DayGridWidget _grid(WidgetTester tester) =>
    tester.widget<DayGridWidget>(find.byType(DayGridWidget));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('loading', () {
    testWidgets('a skeleton while the forecast is built, then the preview '
        'named after the task', (tester) async {
      final rig = _Rig();
      rig.source.hold();
      await _open(tester, rig);
      expect(_key('preview_loading'), findsOneWidget);
      expect(find.text('Checking your schedule…'), findsOneWidget);
      rig.source.release();
      await _settle(tester);
      expect(_key('preview_loading'), findsNothing);
      expect(find.text('Content & Marketing Report'), findsWidgets);
      await rig.cubit.close();
    });

    testWidgets('a failure says so and Retry builds it again', (tester) async {
      final rig = _Rig();
      rig.source.failNextOn('preview', StateError('down'));
      await _open(tester, rig);
      expect(_key('preview_error'), findsOneWidget);
      expect(find.text('Couldn’t build the preview.'), findsOneWidget);
      await tester.tap(_key('preview_retry'));
      await _settle(tester);
      expect(_key('preview_error'), findsNothing);
      expect(_key('preview_accept'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('gone and switched off read differently', (tester) async {
      final gone = _Rig();
      gone.source.failNextOn('preview',
          const TileSharePreviewFailure(PreviewFailureKind.notFound, statusCode: 404));
      await _open(tester, gone);
      expect(find.text('This invitation is no longer available.'), findsOneWidget);
      await gone.cubit.close();

      final off = _Rig();
      off.source.failNextOn('preview', const TileSharePreviewFailure(
          PreviewFailureKind.unavailable, statusCode: 503));
      await _open(tester, off);
      expect(find.text('Previews aren’t available right now.'), findsOneWidget);
      await off.cubit.close();
    });
  });

  group('the strip', () {
    testWidgets('is the Daily grid in preview mode, on the day the task lands, '
        'with the task selected', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      final grid = _grid(tester);
      final session = _viable().sessions.single;
      expect(grid.preview, isTrue);
      expect(grid.day, _dayOf(session.startMs));
      expect(grid.selectedActionEntityId, 'sub-new');
      final proposed = grid.tiles.firstWhere((t) => t.id == 'sub-new');
      expect(proposed.color, PreviewTiles.proposedColor);
      await rig.cubit.close();
    });

    testWidgets('ends where the sheet begins and follows it, so the task is '
        'never under the sheet', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      Rect grid() => tester.getRect(find.byType(DayGridWidget));
      Rect sheet() => tester.getRect(_key('preview_sheet'));
      expect(grid().bottom, closeTo(sheet().top + 16, 1));
      expect(
          tester.getRect(find.text('Content & Marketing Report').last).top,
          lessThan(sheet().top),
          reason: 'the task opens in view, above the sheet');

      final before = grid().bottom;
      await tester.drag(_key('preview_sheet_handle'), const Offset(0, -150));
      await _settle(tester);
      expect(grid().bottom, lessThan(before));
      expect(grid().bottom, closeTo(sheet().top + 16, 1));
      expect(tester.takeException(), isNull);

      // pulled all the way up the strip keeps its stepper, with no overflow
      await tester.drag(_key('preview_sheet_handle'), const Offset(0, -900));
      await _settle(tester);
      expect(_key('preview_day_label'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await rig.cubit.close();
    });

    testWidgets('tapping the task on the strip is safe (seen on device: '
        'duplicate keys)', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      final tile = find.descendant(
          of: find.byType(DayGridWidget),
          matching: find.text('Content & Marketing Report'));
      await tester.tap(tile.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      // its details open read-only: a proposal has nothing to play back
      expect(find.byType(PreviewDetailsTileWidget), findsOneWidget);
      expect(find.byType(PlayBack), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('steps through the returned days and stops at their ends',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      final days = PreviewTiles.days(_viable());
      final start = _grid(tester).day!;
      await tester.tap(_key('preview_day_next'));
      await _settle(tester);
      expect(_grid(tester).day, DateTime(start.year, start.month, start.day + 1));
      await tester.tap(_key('preview_day_prev'));
      await _settle(tester);
      expect(_grid(tester).day, start);

      // walk back to the first day: prev is then disabled
      for (var i = 0; i < days.length; i++) {
        final prev = tester.widget<IconButton>(_key('preview_day_prev'));
        if (prev.onPressed == null) break;
        await tester.tap(_key('preview_day_prev'));
        await _settle(tester);
      }
      expect(_grid(tester).day, days.first);
      expect(tester.widget<IconButton>(_key('preview_day_prev')).onPressed, isNull);
      await rig.cubit.close();
    });

    testWidgets('a task placed outside the days shown says when, instead of '
        'an empty day', (tester) async {
      final base = previewFixture('preview_viable');
      final session = (base['sessions'] as List).single as Map<String, dynamic>;
      final far = (base['rangeEnd'] as int) + 3 * 24 * 3600000;
      final moved = {...session, 'start': far, 'end': far + 3600000};
      final rig = _Rig(
          preview: TileSharePreview.fromJson({
        ...base,
        'sessions': [moved],
        'proposed': [...(base['current'] as List), moved],
      }));
      await _open(tester, rig);
      expect(_key('preview_outside'), findsOneWidget);
      expect(find.textContaining('Scheduled outside the days shown'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('the sheet', () {
    testWidgets('leads with the suggested time and what it moves', (tester) async {
      final base = previewFixture('preview_viable');
      final current = (base['current'] as List).cast<Map<String, dynamic>>();
      final shifted = current
          .map((b) => b['id'] == 'sub-groceries'
              ? {...b, 'start': (b['start'] as int) + 3600000, 'end': (b['end'] as int) + 3600000}
              : b)
          .toList();
      final rig = _Rig(
          preview: TileSharePreview.fromJson({
        ...base,
        'proposed': [...shifted, ...(base['sessions'] as List)],
      }));
      await _open(tester, rig);
      expect(find.text('Suggested schedule'), findsOneWidget);
      final when = PreviewTiles.when(_viable().sessions.single, 'en');
      expect(find.descendant(of: _key('preview_time'), matching: find.text(when)),
          findsOneWidget);
      expect(find.text('Moves 1 flexible tile'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('Accept and Accept & lock are both reachable without '
        'dragging the sheet, on a small phone too', (tester) async {
      for (final size in [const Size(390, 844), const Size(320, 640)]) {
        final rig = _Rig();
        await _open(tester, rig, size: size);
        expect(_visible(_key('preview_accept')), isTrue, reason: '$size');
        expect(_visible(_key('preview_accept_lock')), isTrue, reason: '$size');
        await rig.cubit.close();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the lock action names the time it fixes', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      final when = PreviewTiles.when(_viable().sessions.single, 'en');
      expect(find.text('Locks $when. Other sessions stay flexible.'), findsOneWidget);
      expect(find.text('Tiler may move flexible work later.'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('Accept sends a flexible accept and shows the outcome; Done '
        'closes', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(rig.source.accepted.single.mode, TileShareAcceptanceMode.flexible);
      expect(find.text('Added to your calendar'), findsOneWidget);
      await tester.tap(_key('preview_done'));
      await _settle(tester);
      expect(find.text('open preview'), findsOneWidget);
      expect(rig.popResult, isTrue, reason: 'something changed');
      await rig.cubit.close();
    });

    testWidgets('Accept & lock sends the lock', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(_key('preview_accept_lock'));
      await _settle(tester);
      final sent = rig.source.accepted.single;
      expect(sent.mode, TileShareAcceptanceMode.lockSession);
      expect(sent.sessionKey, '0');
      await rig.cubit.close();
    });

    testWidgets('while it goes out, the buttons give way to progress',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.source.hold();
      await tester.tap(_key('preview_accept'));
      await tester.pump();
      expect(_key('preview_submitting'), findsOneWidget);
      expect(find.text('Adding to your calendar…'), findsOneWidget);
      expect(_key('preview_accept'), findsNothing);
      rig.source.release();
      await _settle(tester);
      await rig.cubit.close();
    });

    testWidgets('a preview that does not fit says so and offers nothing to '
        'accept', (tester) async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson(previewFixture('preview_not_viable')));
      await _open(tester, rig);
      expect(_key('preview_cannot_fit'), findsOneWidget);
      expect(tester.widget<FilledButton>(_key('preview_accept')).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(_key('preview_accept_lock')).onPressed,
          isNull);
      expect(_key('preview_decline'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('a stale preview says so; Refresh builds a new one', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.source.failNextOn(
          'accept',
          const TileSharePreviewFailure(PreviewFailureKind.conflict,
              statusCode: 409, reason: 'scheduleChanged'));
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(_key('preview_stale'), findsOneWidget);
      expect(tester.widget<FilledButton>(_key('preview_accept')).onPressed, isNull);
      final before = rig.source.calls.where((c) => c.startsWith('preview(')).length;
      await tester.tap(_key('preview_refresh'));
      await _settle(tester);
      expect(rig.source.calls.where((c) => c.startsWith('preview(')).length,
          before + 1);
      expect(_key('preview_stale'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a session that can no longer be locked leaves Accept on',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.source.failNextOn(
          'accept',
          const TileSharePreviewFailure(PreviewFailureKind.conflict,
              statusCode: 409, reason: 'invalidSession'));
      await tester.tap(_key('preview_accept_lock'));
      await _settle(tester);
      expect(_key('preview_session_invalid'), findsOneWidget);
      expect(tester.widget<FilledButton>(_key('preview_accept')).onPressed,
          isNotNull);
      expect(tester.widget<OutlinedButton>(_key('preview_accept_lock')).onPressed,
          isNull);
      await rig.cubit.close();
    });

    testWidgets('the app-bar refresh generates a new preview', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(_key('preview_regenerate'));
      await _settle(tester);
      expect(rig.source.calls.where((c) => c.startsWith('preview(')), hasLength(2));
      await rig.cubit.close();
    });

    testWidgets('choosing another arrangement moves the strip and says it is '
        'the selected schedule', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      // step away first, so following the task is what brings the strip back
      await tester.tap(_key('preview_day_next'));
      await _settle(tester);
      await tester.tap(_key('preview_day_next'));
      await _settle(tester);
      await rig.cubit.findOtherTimes();
      final option = rig.cubit.state.options.last;
      expect(_grid(tester).day, isNot(_dayOf(option.startMs)));
      await rig.cubit.selectOption(option.optionId);
      await _settle(tester);
      expect(find.text('Selected schedule'), findsOneWidget);
      expect(_grid(tester).day, _dayOf(option.startMs));
      expect(_grid(tester).selectedActionEntityId, 'sub-new');
      await rig.cubit.close();
    });
  });

  group('other states', () {
    testWidgets('unsupported says why, with no accept, and decline still '
        'works', (tester) async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson(
              previewFixture('preview_unsupported_constraints')));
      await _open(tester, rig);
      expect(_key('preview_unsupported'), findsOneWidget);
      expect(find.textContaining('a preview can’t show yet'), findsOneWidget);
      expect(_key('preview_accept'), findsNothing);
      await tester.tap(_key('preview_decline'));
      await _settle(tester);
      expect(find.text('Declined'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('needs review and rejected are their own outcomes; rejected '
        'can be reviewed again', (tester) async {
      final review = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.needsReview, acceptReason: 'fixedTimeChanged'));
      await _open(tester, review);
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(find.text('Added, but its time couldn’t be confirmed.'), findsOneWidget);
      await review.cubit.close();

      final rejected = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.rejected, acceptReason: 'scheduleChanged'));
      await _open(tester, rejected);
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(find.text('Not added'), findsOneWidget);
      expect(find.text('Your schedule changed since this preview.'), findsOneWidget);
      rejected.source.acceptState = OperationState.completed;
      await tester.tap(_key('preview_review_again'));
      await _settle(tester);
      expect(_key('preview_accept'), findsOneWidget);
      await rejected.cubit.close();
    });

    testWidgets('an unconfirmed accept offers Try again (the same command) and '
        'Check status', (tester) async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await _open(tester, rig);
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(find.text('We couldn’t confirm your answer.'), findsOneWidget);
      expect(_key('preview_check_status'), findsOneWidget);
      await tester.tap(_key('preview_try_again'));
      await _settle(tester);
      expect(find.text('Added to your calendar'), findsOneWidget);
      expect(rig.source.accepted, hasLength(1));
      await rig.cubit.close();
    });

    testWidgets('still adding offers one Check status', (tester) async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.queued,
              operationScript: [OperationState.completed]));
      await _open(tester, rig);
      await tester.tap(_key('preview_accept'));
      await _settle(tester);
      expect(find.text('Still adding…'), findsOneWidget);
      await tester.tap(_key('preview_check_status'));
      await _settle(tester);
      expect(find.text('Added to your calendar'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('declining from the sheet ends declined; a failure says so',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.assignments.failNextOn('respond', StateError('offline'));
      await tester.tap(_key('preview_decline'));
      await _settle(tester);
      expect(find.text('Couldn’t decline. Try again.'), findsOneWidget);
      await tester.tap(_key('preview_decline'));
      await _settle(tester);
      expect(find.text('Declined'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('back closes with nothing changed', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(_key('preview_back'));
      await _settle(tester);
      expect(find.text('open preview'), findsOneWidget);
      expect(rig.popResult, isFalse);
      await rig.cubit.close();
    });
  });

  group('looks right', () {
    testWidgets('both themes, a narrow phone and large text', (tester) async {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        for (final scale in [1.0, 1.6]) {
          final rig = _Rig();
          await _open(tester, rig,
              size: const Size(320, 640), theme: theme, textScale: scale);
          expect(tester.takeException(), isNull,
              reason: '${theme.brightness} x$scale');
          await rig.cubit.close();
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  });
}
