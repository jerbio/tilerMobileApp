import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/previewChart.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/previewWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/preview_sundial_card.dart';
import 'package:tiler_app/theme/theme_data.dart';

Timeline _todayTimeline() {
  final now = DateTime.now();
  final begin = DateTime(now.year, now.month, now.day);
  final end = begin.add(const Duration(days: 1));
  return Timeline(begin.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

PreviewSummary _summary({
  bool withClassification = false,
  bool withLocation = false,
  bool withTag = false,
}) {
  final json = <String, dynamic>{};
  Map<String, dynamic> _group(String name) => {
        'message': null,
        'groupings': [
          {
            'name': name,
            'isNullGrouping': false,
            'tiles': <Map<String, dynamic>>[],
          },
        ],
      };
  if (withClassification) json['classification'] = _group('cls-sec');
  if (withLocation) json['location'] = _group('loc-sec');
  if (withTag) json['tag'] = _group('tag-sec');
  return PreviewSummary.fromJson(json);
}

class _CapturingScheduleSummaryBloc extends ScheduleSummaryBloc {
  _CapturingScheduleSummaryBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleSummaryEvent event) {
    // Swallow events so the real handler doesn't attempt network calls.
  }
}

Widget _wrap(Widget child, ScheduleSummaryBloc bloc) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ScheduleSummaryBloc>.value(
      value: bloc,
      child: Scaffold(
        body: SizedBox(width: 360, height: 600, child: child),
      ),
    ),
  );
}

/// Inspect the items list of the rendered [CarouselSlider]. We assert on
/// the raw widget tree rather than scrolling the carousel because off-
/// screen slides may not be mounted at first paint.
List<Widget> _carouselItems(WidgetTester tester) {
  final slider = tester.widget<CarouselSlider>(find.byType(CarouselSlider));
  return slider.items ?? const <Widget>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreviewWidget carousel composition', () {
    testWidgets(
        'first carousel slide is the PreviewSundialCard even without a previewSummary',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewWidget(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
        ),
        bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CarouselSlider), findsOneWidget);
      final items = _carouselItems(tester);
      expect(items, hasLength(1));
      expect(items.first, isA<PreviewSundialCard>());
    });

    testWidgets(
        'classification chart is included as the second slide when sections are present',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewWidget(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          previewSummary: _summary(withClassification: true),
        ),
        bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final items = _carouselItems(tester);
      expect(items, hasLength(2));
      expect(items[0], isA<PreviewSundialCard>());
      expect(items[1], isA<PreviewChart>());
    });

    testWidgets(
        'location chart is still included as a slide when location sections are present',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewWidget(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          previewSummary: _summary(withLocation: true),
        ),
        bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final items = _carouselItems(tester);
      expect(items, hasLength(2));
      expect(items[0], isA<PreviewSundialCard>());
      expect(items[1], isA<PreviewChart>());
    });

    testWidgets('tag chart is NOT rendered even when tag sections are present',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewWidget(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          previewSummary: _summary(withTag: true),
        ),
        bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final items = _carouselItems(tester);
      expect(items, hasLength(1));
      expect(items.first, isA<PreviewSundialCard>());
      expect(items.whereType<PreviewChart>(), isEmpty);
    });

    testWidgets(
        'with classification + location + tag, only sundial + classification + location slides render',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewWidget(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          previewSummary: _summary(
            withClassification: true,
            withLocation: true,
            withTag: true, // tag should still be ignored
          ),
        ),
        bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final items = _carouselItems(tester);
      expect(items, hasLength(3));
      expect(items[0], isA<PreviewSundialCard>());
      expect(items[1], isA<PreviewChart>());
      expect(items[2], isA<PreviewChart>());
    });
  });
}
