// Phase 2.1 — Flexible primary form.
//
// Widget + unit tests for the three primary Flexible decisions:
//   what (name)  ->  how long (duration)  ->  by when (Complete by)
// plus the persistent **Find time** CTA, required-field validation focus,
// keyboard submission, and API-failure draft preservation.
//
// The form is tested two ways:
//   * through the feature-flagged shell (AddTileRedesignScreen) for structure,
//     ordering, and CTA integration;
//   * directly (FlexibleTileForm) for summary formatting and the row-tap seams,
//     using stub callbacks so no real route/dialog is needed.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

// Non-const in this SDK's widget-test context; the value is deterministic.
final now = DateTime(2026, 9, 4, 14, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// Pump the full redesigned screen (a full-screen Scaffold) against the app
/// theme + localization + a controllable viewport.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size viewSize = AddTileTestMatrix.standard,
  double textScale = AddTileTestMatrix.baseTextScale,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TileThemeData.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localeResolutionCallback: _resolve,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _ScaleOverride(scale: textScale, child: child),
    ),
  );
}

/// Pump a bare [FlexibleTileForm] (framework + theme only) for summary and
/// seam assertions without the shell.
Future<void> pumpForm(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TileThemeData.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localeResolutionCallback: _resolve,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

class _ScaleOverride extends StatelessWidget {
  const _ScaleOverride({required this.scale, required this.child});
  final double scale;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}

void main() {
  group('Flexible primary form — structure & order (shell)', () {
    testWidgets('shows name, How long?, Complete by in the required order',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      final nameTop = tester.getRect(find.byType(TextField)).top;
      final howLongTop = tester.getRect(find.text('DURATION *')).top;
      final completeByTop = tester.getRect(find.text('COMPLETE BY')).top;
      expect(nameTop, lessThan(howLongTop));
      expect(howLongTop, lessThan(completeByTop));
      expect(find.text('Find time'), findsOneWidget);
    });

    testWidgets('Complete by defaults to Anytime', (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      // Scoped to the Complete by ROW: since Step 2.2 the Preferred time
      // control carries its own, separate "Anytime". The two meanings are
      // asserted apart in add_tile_secondary_controls_test.dart.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('completeByRow')),
          matching: find.text('Anytime'),
        ),
        findsOneWidget,
      );
      expect(find.text('Not set'), findsOneWidget);
    });
  });

  group('Flexible primary form — summaries (direct)', () {
    test('duration summary formatting is locale-neutral and compact', () {
      expect(formatDurationSummary(const Duration(minutes: 45)), '45 min');
      expect(formatDurationSummary(const Duration(hours: 2)), '2 hr');
      expect(formatDurationSummary(const Duration(hours: 1, minutes: 30)),
          '1 hr 30 min');
    });

    testWidgets('duration row: Not set when zero, summary when set',
        (tester) async {
      final c = TextEditingController();
      final f = FocusNode();

      await pumpForm(
        tester,
        FlexibleTileForm(
          draft: AddTileDraft.flexible(now: now),
          nameController: c,
          nameFocus: f,
        ),
      );
      expect(find.text('Not set'), findsOneWidget);

      final d = AddTileDraft.flexible(now: now);
      d.setUserDuration(const Duration(hours: 1, minutes: 30));
      await pumpForm(
        tester,
        FlexibleTileForm(draft: d, nameController: c, nameFocus: f),
      );
      expect(find.text('1 hr 30 min'), findsOneWidget);
    });

    testWidgets('Complete by shows the formatted date when a deadline is set',
        (tester) async {
      final c = TextEditingController();
      final f = FocusNode();
      final d = AddTileDraft.flexible(now: now);
      d.endTime = DateTime(2026, 9, 12, 23, 59);

      await pumpForm(
        tester,
        FlexibleTileForm(draft: d, nameController: c, nameFocus: f),
      );
      expect(
        find.text(DateFormat.yMMMd().format(DateTime(2026, 9, 12, 23, 59))),
        findsOneWidget,
      );
      // The Complete by row no longer reads Anytime. The Preferred time
      // control's own "Anytime" is a different concept and stays selected.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('completeByRow')),
          matching: find.text('Anytime'),
        ),
        findsNothing,
      );
    });
  });

  group('Flexible primary form — row taps fire seams (direct)', () {
    testWidgets('tapping duration and Complete-by rows invoke their callbacks',
        (tester) async {
      var durationTapped = false;
      var deadlineTapped = false;
      final c = TextEditingController();
      final f = FocusNode();

      await pumpForm(
        tester,
        FlexibleTileForm(
          draft: AddTileDraft.flexible(now: now),
          nameController: c,
          nameFocus: f,
          onDurationTap: () => durationTapped = true,
          onDeadlineTap: () => deadlineTapped = true,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('durationRow')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('completeByRow')));
      await tester.pump();

      expect(durationTapped, isTrue,
          reason: 'tapping the duration row must open the duration picker');
      expect(deadlineTapped, isTrue,
          reason: 'tapping the Complete by row must open the deadline picker');
    });
  });

  group('Flexible primary form — validation & submission (shell)', () {
    testWidgets(
        'invalid submit (empty name) surfaces an inline error and '
        'keeps the CTA disabled', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setUserDuration(const Duration(minutes: 30));
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: draft, now: now),
      );
      await tester.pump();

      final ctaKey = const ValueKey('addTileCta');
      final cta = tester.widget<AddTileBottomAction>(find.byKey(ctaKey));
      expect(cta.enabled, isFalse, reason: 'empty name => invalid');

      await tester.tap(find.byKey(ctaKey));
      await tester.pump();

      // The first invalid (focusable) field is the name: an inline error is
      // announced (not color-only) and the CTA stays disabled.
      expect(find.text('Name is required'), findsOneWidget);
      final ctaAfter = tester.widget<AddTileBottomAction>(find.byKey(ctaKey));
      expect(ctaAfter.enabled, isFalse);
    });

    testWidgets('keyboard submission (done action) submits when valid',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setUserDuration(const Duration(minutes: 30));
      var submitted = false;
      await pumpScreen(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          now: now,
          onSubmitted: (_) {
            submitted = true;
            return Future.value();
          },
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Focus work');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitted, isTrue,
          reason: 'pressing done on the name field should submit when valid');
    });

    testWidgets('API failure preserves the draft and re-enables the CTA',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.name = 'Focus work';
      draft.setUserDuration(const Duration(minutes: 30));
      final ctaKey = const ValueKey('addTileCta');
      await pumpScreen(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          now: now,
          onSubmitted: (_) async => throw Exception('api_error'),
        ),
      );
      await tester.pump();

      final nameBefore = draft.name;
      await tester.tap(find.byKey(ctaKey));
      await tester.pumpAndSettle();

      expect(draft.name, nameBefore, reason: 'draft must survive a failed API');
      final cta = tester.widget<AddTileBottomAction>(find.byKey(ctaKey));
      expect(cta.submitting, isFalse, reason: 'loading must end on failure');
      expect(cta.enabled, isTrue,
          reason: 'CTA must be tappable again after a failure');
    });
  });
}
