// Step 6.5 — the Time restrictions screen wired into the Add Tile shell
// (D72): the Custom chip is the ONE entry; a named choice lands in the draft
// WITH its id and is user-edited (no prediction overwrite); the chip's label
// reads the choice; Anytime clears; Back leaves everything alone.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileAnalytics.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileTimeRestrictionScreen.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';
import 'restriction_hours_draft_test.dart' as fx;

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    requested ?? const Locale('en');

final DateTime now = DateTime(2026, 9, 18, 9, 0);

class ImmediateSource implements AddTileRestrictionProfileSource {
  ImmediateSource({this.work, this.personal});
  final RestrictionProfile? work;
  final RestrictionProfile? personal;
  int loads = 0;

  @override
  Future<NamedRestrictionProfiles> load() async {
    loads++;
    return NamedRestrictionProfiles(work: work, personal: personal);
  }

  @override
  Future<RestrictionProfile> save(
          RestrictionProfile profile, NamedRestrictionProfileType type) async =>
      profile;
}

class RecordingSink {
  final List<(String, Map<String, Object?>)> events = [];
  void call(String tag, Map<String, Object?> properties) =>
      events.add((tag, properties));
}

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> pumpShell(WidgetTester tester, AddTileDraft draft,
    {required AddTileRestrictionProfileSource source,
    RecordingSink? sink}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileRedesignScreen(
      draft: draft,
      now: now,
      restrictionProfileSource: source,
      analytics: sink == null ? null : AddTileAnalytics(send: sink.call),
    ),
  ));
  await tester.pump();
}

Future<void> openTimeRestrictions(WidgetTester tester) async {
  await tester.ensureVisible(key('preferredTimeCustom'));
  await tester.tap(key('preferredTimeCustom'));
  await tester.pumpAndSettle();
  expect(find.byType(AddTileTimeRestrictionScreen), findsOneWidget);
}

Future<void> done(WidgetTester tester) async {
  await tester.tap(key('restrictionDone'));
  await tester.pumpAndSettle();
}

String customChipLabel(WidgetTester tester) => tester
    .widget<Text>(find.descendant(
        of: key('preferredTimeCustom'), matching: find.byType(Text)))
    .data!;

void main() {
  final RestrictionProfile work = fx.weekdays(id: 'work-1');
  final RestrictionProfile personal =
      fx.weekdays(start: fx.sixPm, end: fx.tenPm, id: 'personal-1');

  testWidgets('the Custom chip opens Time restrictions seeded with the draft',
      (tester) async {
    final draft = AddTileDraft.flexible(now: now);
    final RestrictionProfile adHoc =
        fx.weekdays(start: fx.ten, end: fx.four, id: null);
    draft.setRestrictionProfile(adHoc);
    await pumpShell(tester, draft, source: ImmediateSource(work: work));
    await openTimeRestrictions(tester);
    final AddTileTimeRestrictionScreen screen =
        tester.widget<AddTileTimeRestrictionScreen>(
            find.byType(AddTileTimeRestrictionScreen));
    expect(screen.initial, same(adHoc));
  });

  testWidgets(
      'choosing Work writes the named profile — with its id — into the '
      'draft, marks it user-edited, and labels the chip', (tester) async {
    final draft = AddTileDraft.flexible(now: now);
    final sink = RecordingSink();
    await pumpShell(tester, draft,
        source: ImmediateSource(work: work, personal: personal), sink: sink);
    await openTimeRestrictions(tester);
    await tester.tap(key('restrictionChoice_work'));
    await tester.pump();
    await done(tester);
    expect(find.byType(AddTileTimeRestrictionScreen), findsNothing);
    expect(draft.restrictionProfile, same(work));
    expect(draft.restrictionProfile!.id, 'work-1');
    expect(draft.canAcceptSuggestion(AddTileSuggestedField.restrictionProfile),
        isFalse,
        reason: 'a prediction must not overwrite the user\'s choice (D72)');
    expect(customChipLabel(tester), testL10n.addTileRestrictionWork);

    final (String, Map<String, Object?>) event = sink.events
        .singleWhere((e) => e.$1 == 'ADD_ITEM_PREFERRED_TIME_CHOSEN');
    expect(event.$2['choice'], 'work');
    expect(event.$2['item_type'], 'flexible');
    expect(event.$2.keys, isNot(contains('hours')),
        reason: 'category only, never the hours');
  });

  testWidgets('Personal labels the chip Personal hours; Custom stays Custom',
      (tester) async {
    final draft = AddTileDraft.flexible(now: now);
    await pumpShell(tester, draft,
        source: ImmediateSource(work: work, personal: personal));
    await openTimeRestrictions(tester);
    await tester.tap(key('restrictionChoice_personal'));
    await tester.pump();
    await done(tester);
    expect(draft.restrictionProfile, same(personal));
    expect(customChipLabel(tester), testL10n.addTileRestrictionPersonal);

    // An ad-hoc profile reads Custom.
    draft.setRestrictionProfile(
        fx.weekdays(start: fx.ten, end: fx.four, id: null));
    await tester.pump();
    expect(customChipLabel(tester), testL10n.addTilePreferredTimeCustom);
  });

  testWidgets('Anytime clears the profile; Back changes nothing',
      (tester) async {
    final draft = AddTileDraft.flexible(now: now);
    draft.setRestrictionProfile(work);
    await pumpShell(tester, draft, source: ImmediateSource(work: work));
    await openTimeRestrictions(tester);
    await tester.tap(key('restrictionChoice_anytime'));
    await tester.pump();
    await done(tester);
    expect(draft.restrictionProfile, isNull);

    draft.setRestrictionProfile(work);
    await tester.pump();
    await openTimeRestrictions(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(draft.restrictionProfile, same(work));
  });

  testWidgets('the named profiles load once per Add Tile session',
      (tester) async {
    final draft = AddTileDraft.flexible(now: now);
    final ImmediateSource source = ImmediateSource(work: work);
    await pumpShell(tester, draft, source: source);
    await openTimeRestrictions(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openTimeRestrictions(tester);
    await tester.pumpAndSettle();
    expect(source.loads, 1);
  });
}
