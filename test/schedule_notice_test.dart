import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeSurface.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

ScheduleNotice notice(String id, ScheduleNoticeSlot slot, int priority) =>
    ScheduleNotice(
        id: id,
        slot: slot,
        priority: priority,
        builder: (_) => Text(id, key: ValueKey('notice:$id')));

Widget app(ScheduleNoticeBus bus, Widget home, {ScheduleBloc? bloc}) {
  Widget child = RepositoryProvider<ScheduleNoticeBus>.value(
      value: bus,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ));
  if (bloc != null) {
    child = BlocProvider<ScheduleBloc>.value(value: bloc, child: child);
  }
  return child;
}

Widget calendar() => const Scaffold(
    body: ScheduleNoticeSurface.calendar(child: SizedBox.expand()));

void main() {
  group('Calendar slots', () {
    testWidgets('the top slot puts the change in progress above its moves',
        (tester) async {
      final bus = ScheduleNoticeBus();
      await tester.pumpWidget(app(bus, calendar()));

      bus.show(notice(
          'moving', ScheduleNoticeSlot.top, ScheduleNotice.progressPriority));
      bus.show(notice(
          'status', ScheduleNoticeSlot.top, ScheduleNotice.statusPriority));
      await tester.pump();

      final status = find.byKey(const ValueKey('notice:status'));
      final moving = find.byKey(const ValueKey('notice:moving'));
      expect(status, findsOneWidget);
      expect(moving, findsOneWidget);
      expect(
          tester.getTopLeft(status).dy, lessThan(tester.getTopLeft(moving).dy));

      // At most two: a third, lower one waits.
      bus.show(notice('extra', ScheduleNoticeSlot.top, 0));
      await tester.pump();
      expect(find.byKey(const ValueKey('notice:extra')), findsNothing);

      // Once the change ends, its moves take the top.
      bus.hide('status');
      await tester.pump();
      expect(status, findsNothing);
      expect(find.byKey(const ValueKey('notice:extra')), findsOneWidget);
    });

    testWidgets('the bottom slot shows one; an interruption takes it a while',
        (tester) async {
      final bus =
          ScheduleNoticeBus(interruptionFor: const Duration(seconds: 2));
      await tester.pumpWidget(app(bus, calendar()));
      bus.show(notice('low', ScheduleNoticeSlot.bottom, 1));
      bus.show(notice('summary', ScheduleNoticeSlot.bottom,
          ScheduleNotice.progressPriority));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notice:summary')), findsOneWidget);
      expect(find.byKey(const ValueKey('notice:low')), findsNothing);

      bus.interrupt(tester.element(find.byType(Scaffold)), 'Wait a moment');
      await tester.pumpAndSettle();
      expect(find.text('Wait a moment'), findsOneWidget);
      expect(find.byKey(const ValueKey('notice:summary')), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Wait a moment'), findsNothing);
      expect(find.byKey(const ValueKey('notice:summary')), findsOneWidget);
    });

    testWidgets('notices published while the frame builds still show',
        (tester) async {
      final bus = ScheduleNoticeBus();
      await tester.pumpWidget(app(bus, Scaffold(body:
          ScheduleNoticeSurface.calendar(child: Builder(builder: (context) {
        bus.show(notice('built', ScheduleNoticeSlot.top, 1));
        return const SizedBox.expand();
      })))));
      await tester.pump();
      expect(find.byKey(const ValueKey('notice:built')), findsOneWidget);
    });

    testWidgets('the calendar hosts the evaluation card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bus = ScheduleNoticeBus();
      final bloc = ScheduleBloc(getContextCallBack: () => null);
      await tester.pumpWidget(app(
          bus,
          const Scaffold(
              body: ScheduleNoticeSurface.calendar(
                  child: ScheduleEvaluationNotices(child: SizedBox.expand()))),
          bloc: bloc));
      final window =
          Timeline.fromDateTime(DateTime(2026), DateTime(2026, 1, 8));
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: const [],
          timelines: const [],
          lookupTimeline: window,
          scheduleStatus: ScheduleStatus.fromJson(
              {'analysisId': 'a', 'evaluationId': 'e'})));
      await tester.pump();
      final write = Completer<void>();
      final pending = bloc.runScheduleChange(() => write.future,
          kind: ScheduleChangeKind.shuffle);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('scheduleEvaluationFeedback')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('scheduleNoticeTopSlot')),
              matching:
                  find.byKey(const ValueKey('scheduleEvaluationFeedback'))),
          findsOneWidget);

      write.complete();
      await pending;
      await tester.pump();
      await tester.pump();
      // Settled: the slot now says the schedule is updating, until the
      // refresh read after the answer ends.
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('scheduleNoticeTopSlot')),
              matching: find.text(lookupAppLocalizations(const Locale('en'))
                  .scheduleChangeRefreshing)),
          findsOneWidget);
      // Its spinner keeps going while the read is out, so no settling here.
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('A blocked change', () {
    late ScheduleBloc bloc;
    late Completer<void> write;
    late Future<void> pending;

    /// Holds a write in progress, so every other change is blocked.
    Future<void> block(WidgetTester tester) async {
      write = Completer<void>();
      pending = bloc.runScheduleChange(() => write.future,
          kind: ScheduleChangeKind.complete);
      await tester.pump();
      expect(bloc.scheduleChangesBlocked, isTrue);
    }

    Future<void> release(WidgetTester tester) async {
      write.complete();
      await pending;
      await tester.pumpAndSettle();
    }

    /// The calendar with a button that opens a sheet; the sheet's button
    /// attempts a change.
    Widget home({required bool sheetSurface}) => Scaffold(
          body: ScheduleNoticeSurface.calendar(
            child: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) {
                      final Widget sheet = SizedBox(
                        height: 300,
                        child: Center(
                          child: Builder(
                            builder: (context) => TextButton(
                              onPressed: () => scheduleChangesAllowed(context),
                              child: const Text('Complete'),
                            ),
                          ),
                        ),
                      );
                      return sheetSurface
                          ? ScheduleNoticeSurface(child: sheet)
                          : sheet;
                    },
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

    Future<ScheduleNoticeBus> open(WidgetTester tester,
        {required bool sheetSurface}) async {
      SharedPreferences.setMockInitialValues({});
      bloc = ScheduleBloc(getContextCallBack: () => null);
      final bus = ScheduleNoticeBus();
      await tester
          .pumpWidget(app(bus, home(sheetSurface: sheetSurface), bloc: bloc));
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: const [],
          timelines: const [],
          lookupTimeline:
              Timeline.fromDateTime(DateTime(2026), DateTime(2026, 1, 8)),
          scheduleStatus: ScheduleStatus.fromJson(
              {'analysisId': 'a', 'evaluationId': 'e'})));
      await tester.pump();
      await block(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return bus;
    }

    final toast = find.byKey(ScheduleInterruptionToast.toastKey);

    testWidgets('says so on the open sheet, not behind it', (tester) async {
      await open(tester, sheetSurface: true);
      await tester.tap(find.text('Complete'));
      await tester.pump();

      expect(toast, findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: toast),
          findsOneWidget);
      // Nothing covers it: a tap at its centre reaches it.
      expect(toast.hitTestable(), findsOneWidget);
      await release(tester);
    });

    testWidgets('a sheet without a surface still shows it above itself',
        (tester) async {
      await open(tester, sheetSurface: false);
      await tester.tap(find.text('Complete'));
      await tester.pump();

      expect(toast, findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: toast),
          findsNothing);
      expect(toast.hitTestable(), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(toast, findsNothing);
      await release(tester);
    });

    testWidgets('with no sheet, the calendar shows it', (tester) async {
      await open(tester, sheetSurface: true);
      Navigator.of(tester.element(find.text('Complete'))).pop();
      await tester.pumpAndSettle();
      expect(
          scheduleChangesAllowed(tester.element(find.text('Open'))), isFalse);
      await tester.pump();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('scheduleNoticeBottomSlot')),
              matching: toast),
          findsOneWidget);
      await release(tester);
    });
  });
}
