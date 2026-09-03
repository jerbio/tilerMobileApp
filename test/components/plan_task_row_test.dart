// plan_task_row_test.dart
//
// Phase 3 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Covers the §7.2 PlanTaskRow layout contract, the §17 missing-data edge cases,
// and the §10 accessibility requirements for the shared row primitives.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/todayStatus/metadataLabel.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/components/todayStatus/reasonChip.dart';
import 'package:tiler_app/components/todayStatus/statusIconWell.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

PlanItemViewModel _item({
  String id = 'id',
  String? title = 'Morning prep',
  PlanItemStatus status = PlanItemStatus.placed,
  DateTime? displayDate,
  int? durationMinutes,
  AttentionReasonCode? reasonCode,
}) {
  return PlanItemViewModel(
    id: id,
    title: title,
    status: status,
    source: SubCalendarEvent(id: id, name: title),
    displayDate: displayDate,
    durationMinutes: durationMinutes,
    reasonCode: reasonCode,
  );
}

Widget _harness({required Widget child, double width = 390, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusIconWell', () {
    testWidgets('tints itself from the semantic status, not a hardcoded color',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const Column(children: [
          StatusIconWell(status: PlanItemStatus.placed, icon: Icons.check),
          StatusIconWell(
              status: PlanItemStatus.needsAttention, icon: Icons.error),
        ]),
      ));

      final wells = tester
          .widgetList<Container>(find.descendant(
              of: find.byType(StatusIconWell),
              matching: find.byType(Container)))
          .toList();
      final placedColor = (wells.first.decoration as BoxDecoration).color;
      final attentionColor = (wells.last.decoration as BoxDecoration).color;

      final tokens = TodayStatusTokens.from(TileThemeData.lightTheme);
      expect(placedColor, tokens.successTint);
      expect(attentionColor, tokens.attentionTint);
    });

    testWidgets('is at least the §4.1 icon well size', (tester) async {
      await tester.pumpWidget(_harness(
        // Aligned so the well sizes itself rather than inheriting the tight
        // width of the surrounding harness.
        child: const Align(
          alignment: Alignment.centerLeft,
          child:
              StatusIconWell(status: PlanItemStatus.placed, icon: Icons.check),
        ),
      ));

      final size = tester.getSize(find.byType(StatusIconWell));
      expect(size.width, TodayStatusTokens.iconWell);
      expect(size.height, TodayStatusTokens.iconWell);
    });
  });

  group('MetadataLabel', () {
    testWidgets('renders its icon alongside the label', (tester) async {
      await tester.pumpWidget(_harness(
        child:
            const MetadataLabel(icon: Icons.calendar_month, label: 'Tomorrow'),
      ));

      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });
  });

  group('ReasonChip', () {
    testWidgets('renders the localized label for a reason code',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const ReasonChip(reasonCode: AttentionReasonCode.noFeasibleSlot),
      ));

      expect(find.text('No open slot'), findsOneWidget);
    });

    testWidgets('interpolates the duration for DURATION_EXCEEDS_GAP',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const ReasonChip(
          reasonCode: AttentionReasonCode.durationExceedsGap,
          durationMinutes: 45,
        ),
      ));

      expect(find.text('Needs 45 min'), findsOneWidget);
    });

    testWidgets('falls back to the generic label when no duration is known',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const ReasonChip(
            reasonCode: AttentionReasonCode.durationExceedsGap),
      ));

      expect(find.text("Couldn't fit"), findsOneWidget);
    });
  });

  group('PlanTaskRow §7.2 layout contract', () {
    testWidgets('renders the tile title', (tester) async {
      await tester.pumpWidget(_harness(child: PlanTaskRow(item: _item())));

      expect(find.text('Morning prep'), findsOneWidget);
    });

    testWidgets('uses the localized fallback for a missing title',
        (tester) async {
      await tester
          .pumpWidget(_harness(child: PlanTaskRow(item: _item(title: null))));

      expect(find.text('Untitled tile'), findsOneWidget);
    });

    testWidgets('caps the title at two lines with an ellipsis', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(item: _item(title: 'A very long tile title ' * 12)),
      ));

      final Text title = tester.widget<Text>(find.byKey(PlanTaskRow.titleKey));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('omits date metadata entirely when there is no date',
        (tester) async {
      await tester.pumpWidget(_harness(child: PlanTaskRow(item: _item())));

      expect(find.byIcon(Icons.calendar_month), findsNothing);
    });

    testWidgets('shows the date when one is available', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(
            item: _item(
                displayDate: DateTime.now().add(const Duration(days: 1)))),
      ));

      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('makes the whole row tappable', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(item: _item(), onTap: () => taps++),
      ));

      await tester.tap(find.byType(PlanTaskRow));
      expect(taps, 1);
    });

    testWidgets('meets the minimum row height', (tester) async {
      await tester.pumpWidget(_harness(child: PlanTaskRow(item: _item())));

      expect(tester.getSize(find.byType(PlanTaskRow)).height,
          greaterThanOrEqualTo(TodayStatusTokens.rowMinHeight));
    });

    testWidgets('moves metadata below the title on narrow widths (§11)',
        (tester) async {
      await tester.pumpWidget(_harness(
        width: 320,
        child: PlanTaskRow(
          item: _item(
            displayDate: DateTime.now(),
            reasonCode: AttentionReasonCode.noFeasibleSlot,
            status: PlanItemStatus.needsAttention,
          ),
        ),
      ));

      expect(find.byKey(PlanTaskRow.stackedMetadataKey), findsOneWidget);
      expect(find.byKey(PlanTaskRow.inlineMetadataKey), findsNothing);
      expect(find.text('Morning prep'), findsOneWidget,
          reason: 'the title must never be sacrificed for metadata');
    });

    testWidgets('keeps metadata inline at the baseline width', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(item: _item(displayDate: DateTime.now())),
      ));

      expect(find.byKey(PlanTaskRow.inlineMetadataKey), findsOneWidget);
      expect(find.byKey(PlanTaskRow.stackedMetadataKey), findsNothing);
    });

    testWidgets('renders a checkbox in place of the icon well when supplied',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(
          item: _item(status: PlanItemStatus.needsAttention),
          leading: const Icon(Icons.check_box_outline_blank),
        ),
      ));

      expect(find.byType(StatusIconWell), findsNothing);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });
  });

  group('PlanTaskRow §10 accessibility', () {
    testWidgets('announces title, status, date and duration as one label',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(
          item: _item(
            title: 'Morning prep',
            displayDate: DateTime.now().add(const Duration(days: 1)),
            durationMinutes: 30,
          ),
          onTap: () {},
        ),
      ));

      expect(
        find.bySemanticsLabel(
            RegExp(r'Morning prep.*Placed successfully.*Tomorrow.*30 min')),
        findsOneWidget,
      );
    });

    testWidgets('exposes the full title even when it is visually truncated',
        (tester) async {
      const String longTitle =
          'Create the end of quarter write-up for the campaign retrospective';
      await tester.pumpWidget(_harness(
        child: PlanTaskRow(item: _item(title: longTitle), onTap: () {}),
      ));

      expect(find.bySemanticsLabel(RegExp(RegExp.escape(longTitle))),
          findsOneWidget);
    });
  });

  group('PlanTaskRow theming', () {
    testWidgets('resolves dark tokens under the dark theme', (tester) async {
      await tester.pumpWidget(_harness(
        theme: TileThemeData.darkTheme,
        child: PlanTaskRow(item: _item()),
      ));

      final Text title = tester.widget<Text>(find.byKey(PlanTaskRow.titleKey));
      expect(title.style?.color,
          TodayStatusTokens.from(TileThemeData.darkTheme).textPrimary);
    });
  });
}
