// Feature-flagged Add Tile redesign shell.
//
// Widget tests for the shared frame: type selector BEFORE fields,
// dynamic title/explanation/CTA by type, an independently scrolling form with a
// pinned persistent CTA, a keyboard/safe-area-safe CTA, a single root Close,
// CTA gating by draft validity, mapper routing, and double-submit prevention.
//
// Uses the shared widget-test harness matrix (viewports / text scale / themes)
// and the isCoveredByKeyboardBottom helper so the shell is validated against
// the same responsive / a11y matrix the later phases depend on.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

/// Pump [child] inside the app's localization + theme with a controllable
/// viewport, text scale, and simulated keyboard bottom inset. The shell is a
/// full-screen Scaffold, so it is the root here (unlike the harness's nested
/// Scaffold); the same matrix constants and keyboard helper are reused.
Future<void> pumpShell(
  WidgetTester tester,
  Widget child, {
  Size viewSize = AddTileTestMatrix.standard,
  double textScale = AddTileTestMatrix.baseTextScale,
  EdgeInsets viewInsets = EdgeInsets.zero,
  AddTileTestTheme theme = AddTileTestTheme.light,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme == AddTileTestTheme.light
          ? TileThemeData.lightTheme
          : TileThemeData.darkTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localeResolutionCallback:
          (Locale? requested, Iterable<Locale> supported) => supported.first,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _InsetsOverride(insets: viewInsets, scale: textScale, child: child),
    ),
  );
}

/// Applies a simulated keyboard bottom inset + text scale via MediaQuery.
class _InsetsOverride extends StatelessWidget {
  const _InsetsOverride({
    required this.insets,
    required this.scale,
    required this.child,
  });

  final EdgeInsets insets;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        viewInsets: insets,
        textScaler: TextScaler.linear(scale),
      ),
      child: child,
    );
  }
}

AddTileDraft _validFlexibleDraft(DateTime now) {
  final d = AddTileDraft.flexible(now: now);
  d.setUserDuration(const Duration(minutes: 30));
  return d;
}

Finder cta() => find.byKey(const ValueKey('addTileCta'));

/// The CTA widget exposes its raw validity via [AddTileBottomAction.enabled];
/// the loading/disabled interaction is [AddTileBottomAction.submitting].
AddTileBottomAction _ctaWidget(WidgetTester tester) =>
    tester.widget<AddTileBottomAction>(cta());

/// A template that ignores its argument, standing in for a translation that
/// dropped the `{emphasis}` placeholder.
String _noPlaceholder(String _) => 'A sentence with no placeholder at all.';

void main() {
  // Non-const: this SDK's DateTime constructor is not const in widget-test
  // context; the value is still deterministic.
  final now = DateTime(2026, 9, 4, 14, 0);

  group('shell — shared frame', () {
    testWidgets('type selector appears before the fields', (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      final selectorTop =
          tester.getRect(find.bySemanticsLabel('Tile type')).top;
      final nameTop = tester.getRect(find.byType(TextField)).top;
      expect(selectorTop, lessThan(nameTop));
    });

    testWidgets('the two segments share ONE track, flush (D37)',
        (tester) async {
      // The header mockup draws a single pill holding both segments. The
      // earlier version was two rounded buttons with an 8px gap, which read
      // as two independent toggles rather than one either/or choice — the gap
      // said "unrelated" about the only strictly exclusive decision here.
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      final Finder segments = find.byType(AddTileTypeSegment);
      expect(segments, findsNWidgets(2));

      final Rect first = tester.getRect(segments.at(0));
      final Rect second = tester.getRect(segments.at(1));
      expect(second.left, closeTo(first.right, 0.5),
          reason: 'a gap between segments reads as two separate controls');
      expect(first.top, closeTo(second.top, 0.5));
    });

    testWidgets('each segment carries its mode icon (D37)', (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      for (final AddTileType type in AddTileType.values) {
        expect(
          find.descendant(
            of: find.byType(AddTileTypeSelector),
            matching: find.byIcon(AddTileTypeSelector.iconFor(type)),
          ),
          findsOneWidget,
          reason: '$type is missing its icon',
        );
      }
    });

    testWidgets('the explanation emphasises one phrase (D37)', (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      final Text sentence = tester.widget<Text>(find.descendant(
        of: find.byKey(const ValueKey('modeExplanation')),
        matching: find.byType(Text),
      ));
      expect(sentence.textSpan, isNotNull,
          reason: 'the sentence must be rich text so one phrase can be '
              'set heavier');

      // The whole sentence still reads as one string — the emphasis is a
      // style, not a structural split a screen reader would announce apart.
      expect(sentence.textSpan!.toPlainText(),
          'Tiler will find the best time for this.');

      final List<InlineSpan> spans = (sentence.textSpan! as TextSpan).children!;
      final InlineSpan emphasised = spans.firstWhere(
        (span) => span is TextSpan && span.text == 'best time',
        orElse: () => const TextSpan(text: ''),
      );
      expect((emphasised as TextSpan).style?.fontWeight, FontWeight.w600);
    });

    testWidgets('the explanation follows the selected mode (D37)',
        (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('modeExplanation')),
          matching:
              find.byIcon(AddTileTypeSelector.iconFor(AddTileType.flexible)),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Fixed Block'));
      await tester.pumpAndSettle();

      expect(find.text('Blocks happen at a fixed time.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('modeExplanation')),
          matching: find.byIcon(AddTileTypeSelector.iconFor(AddTileType.fixed)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a translation that drops {emphasis} still renders (D37)',
        (tester) async {
      // gen-l10n would catch a missing placeholder at build time, but the
      // widget must not throw if one ever reaches it — a header that crashes
      // is worse than one that loses a bold.
      await pumpShell(
        tester,
        const Scaffold(
          body: AddTileModeExplanation(
            key: ValueKey('degraded'),
            icon: Icons.auto_awesome,
            template: _noPlaceholder,
            emphasis: 'best time',
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
          find.text('A sentence with no placeholder at all.'), findsOneWidget);
    });

    testWidgets('flexible default: title/explanation/CTA reflect Flexible',
        (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      expect(find.text('Add Tile'), findsOneWidget);
      expect(
          find.text('Tiler will find the best time for this.'), findsOneWidget);
      expect(find.text('Find time'), findsOneWidget);
      // Both mode labels are present (one segmented control, not two controls
      // for the same decision); the legacy carousel + toggle are removed and
      // replaced by this single selector.
      expect(find.text('Flexible Tile'), findsOneWidget);
      expect(find.text('Fixed Block'), findsOneWidget);
    });

    testWidgets('switching to Fixed updates title/explanation/CTA',
        (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      await tester.tap(find.text('Fixed Block'));
      await tester.pumpAndSettle();

      // Title + CTA now both read "Add Block"; the Flexible CTA is gone.
      expect(find.text('Add Block'), findsWidgets);
      expect(find.text('Blocks happen at a fixed time.'), findsOneWidget);
      expect(find.text('Find time'), findsNothing);
    });

    testWidgets('only one root Close; no legacy bottom Cancel', (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Proceed'), findsNothing);
    });

    testWidgets('form scrolls independently of the pinned CTA', (tester) async {
      // Short viewport so the form content can exceed the scroll area.
      await pumpShell(tester, AddTileRedesignScreen(now: now),
          viewSize: const Size(320, 500));
      await tester.pump();

      // The form's scroller is the VERTICAL one. Preferred time carries its
      // own horizontal scroller so its five chips stay on one line, so a bare
      // byType finder would match both and could drag the wrong axis.
      final formScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
        description: 'the form area scroll view',
      );
      final ctaBefore = tester.getRect(cta());
      expect(formScroll, findsOneWidget);
      await tester.drag(formScroll, const Offset(0, -300));
      await tester.pumpAndSettle();
      final ctaAfter = tester.getRect(cta());
      // The CTA is a sibling of the scroll view (pinned), not a child of it.
      expect(ctaAfter, ctaBefore);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CTA stays above a simulated keyboard inset', (tester) async {
      const keyboard = 320.0;
      await pumpShell(tester, AddTileRedesignScreen(now: now),
          viewSize: AddTileTestMatrix.largePhone,
          viewInsets: const EdgeInsets.only(bottom: keyboard));
      await tester.pump();

      final ctaWidget = tester.widget(cta());
      expect(
          isCoveredByKeyboardBottom(tester, ctaWidget, bottomHeight: keyboard),
          isFalse,
          reason: 'The persistent CTA must be visible above the keyboard');
    });
  });

  group('shell — CTA gating + submission', () {
    testWidgets('default flexible draft (no duration) keeps the CTA disabled',
        (tester) async {
      var submitted = false;
      await pumpShell(
        tester,
        AddTileRedesignScreen(
          now: now,
          onSubmitted: (_) {
            submitted = true;
            return Future.value();
          },
        ),
      );
      await tester.pump();

      // Shell owns a fresh flexible draft: empty name + zero duration.
      expect(_ctaWidget(tester).enabled, isFalse,
          reason: 'CTA must be disabled until required inputs are valid');

      await tester.tap(cta());
      await tester.pumpAndSettle();
      expect(submitted, isFalse);
    });

    testWidgets('name + duration enables the CTA and submits via the mapper',
        (tester) async {
      final draft = _validFlexibleDraft(now);
      final captured = <NewTile>[];
      await pumpShell(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          onSubmitted: (t) {
            captured.add(t);
            return Future.value();
          },
        ),
      );
      await tester.pump();

      expect(_ctaWidget(tester).enabled, isFalse,
          reason: 'name is still empty');

      await tester.enterText(find.byType(TextField), 'Do laundry');
      await tester.pump();

      expect(_ctaWidget(tester).enabled, isTrue,
          reason: 'name + valid duration => enabled');

      await tester.tap(cta());
      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      // Flexible maps Rigid unset (mapper parity).
      expect(captured.first.Rigid, isNull);
      expect(captured.first.Name, 'Do laundry');
      expect(captured.first.DurationMinute, '30');
    });

    testWidgets('fixed draft submits a rigid payload (Rigid = true)',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      draft.name = 'Standup';
      final captured = <NewTile>[];
      await pumpShell(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          onSubmitted: (t) {
            captured.add(t);
            return Future.value();
          },
        ),
      );
      await tester.pump();

      expect(_ctaWidget(tester).enabled, isTrue,
          reason: 'fixed default 30 min + name => enabled');
      await tester.tap(cta());
      await tester.pumpAndSettle();

      expect(captured, hasLength(1));
      expect(captured.first.Rigid, 'true');
      expect(captured.first.Name, 'Standup');
    });

    testWidgets('a pending submission cannot fire twice', (tester) async {
      final draft = _validFlexibleDraft(now);
      final gate = Completer<void>();
      var count = 0;
      await pumpShell(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          onSubmitted: (_) {
            count++;
            return gate.future;
          },
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Focus work');
      await tester.pump();

      await tester.tap(cta());
      await tester.pump();
      // Loading state is shown; the CTA is non-interactive while pending
      // (submitting == true => canSubmit == false => no onTap).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_ctaWidget(tester).submitting, isTrue);

      // A second tap is a no-op while pending.
      await tester.tap(cta());
      await tester.pump();
      expect(count, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(count, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('shell — responsive / a11y matrix', () {
    testWidgets('narrow width at text scale 1.3 does not overflow',
        (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now),
          viewSize: AddTileTestMatrix.narrow,
          textScale: AddTileTestMatrix.largeTextScale);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Both selector labels and the CTA remain present and reachable.
      expect(find.text('Flexible Tile'), findsOneWidget);
      expect(find.text('Fixed Block'), findsOneWidget);
      expect(find.text('Find time'), findsOneWidget);
    });

    testWidgets('selector exposes selected state to assistive tech',
        (tester) async {
      await pumpShell(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      // Exactly one mode is marked selected (the Flexible segment); the other
      // is not — selected state is exposed, not color-only. The segment
      // widget carries the assistive-tech values (label/selected) that feed
      // its Semantics node.
      final segments = tester
          .widgetList<AddTileTypeSegment>(find.byType(AddTileTypeSegment));
      final selected =
          segments.where((s) => s.selected).map((s) => s.label).toList();
      expect(selected, ['Flexible Tile']);
    });
  });
}
