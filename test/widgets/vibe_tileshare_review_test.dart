import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/vibeChat/tileShareReviewCard.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child));
  testWidgets('plan review includes schedule effects for each target',
      (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'Operation': 'UpdatePlan',
          'ReviewToken': 'review',
          'Review': {
            'Operation': 'UpdatePlan',
            'Items': [
              {
                'PreviousName': 'Report',
                'Name': 'Report',
                'ScheduleSummary':
                    'Duration: 60 minutes -> 90 minutes\nAccepted calendars to update: 2'
              }
            ]
          }
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.textContaining('Duration: 60 minutes -> 90 minutes'),
        findsOneWidget);
    expect(find.text('Confirm update'), findsOneWidget);
  });
  for (final state in ['Pending', 'Failed']) {
    testWidgets('$state plan displays each target without mutation retry',
        (tester) async {
      await tester.pumpWidget(host(TileShareReviewCard(
          result: {
            'State': state,
            'ActionId': 'a',
            'Operation': 'UpdatePlan',
            'PlanTargets': [
              {
                'ProjectId': 'p',
                'Name': 'Report',
                'State': state == 'Pending' ? 'Pending' : 'NotAttempted'
              }
            ]
          },
          onConfirm: (_) async => {},
          onCheck: () async => {},
          onChanged: (_) {})));
      expect(find.textContaining('Report'), findsOneWidget);
      expect(
          find.text(state == 'Pending'
              ? 'Waiting for combined calculation'
              : 'Not applied'),
          findsOneWidget);
      expect(find.text('Confirm update'), findsNothing);
      expect(find.text('Check status'),
          state == 'Pending' ? findsOneWidget : findsNothing);
    });
  }
  final review = <String, dynamic>{
    'State': 'NotAttempted',
    'ActionId': 'a',
    'ReviewToken': 'exact',
    'Review': {
      'Name': 'Launch',
      'CreatesProject': true,
      'Tilettes': [
        {
          'Name': 'Copy',
          'DurationMinutes': 60,
          'Recipients': [
            {'name': 'Ada', 'email': 'ada@example.test'}
          ]
        }
      ]
    }
  };
  testWidgets('plan reviews all targets and confirms one exact token',
      (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          ...review,
          'Operation': 'UpdatePlan',
          'Review': {
            'Operation': 'UpdatePlan',
            'Name': 'Update shared work',
            'Items': [
              {
                'PreviousName': 'Launch',
                'Name': 'Release',
                'UpdatesName': true
              },
              {
                'PreviousName': 'Report',
                'Name': 'Report',
                'UpdatesNotes': true,
                'PreviousNotes': 'Old instructions',
                'Notes': ''
              }
            ]
          }
        },
        onConfirm: (token) async {
          expect(token, 'exact');
          confirmations++;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'UpdatePlan'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Review shared-work plan'), findsOneWidget);
    expect(find.textContaining('Launch'), findsWidgets);
    expect(find.text('Old instructions'), findsOneWidget);
    expect(find.text('Clear notes'), findsOneWidget);
    expect(confirmations, 0);
    await tester.tap(find.text('Confirm update'));
    await tester.pumpAndSettle();
    expect(confirmations, 1);
  });
  testWidgets('saved plan lists each updated target', (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'UpdatePlan',
          'PlanTargets': [
            {
              'ProjectId': 'p',
              'Name': 'Release',
              'Url': '/tileshare/p',
              'State': 'Applied'
            },
            {
              'ProjectId': 'p',
              'TiletteId': 't',
              'Name': 'Report',
              'Url': '/tileshare/p/tilette/t',
              'State': 'Applied'
            }
          ]
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Reviewed changes saved together.'), findsOneWidget);
    expect(find.text('Release'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('TileShare created.'), findsNothing);
  });
  for (final operation in ['UpdateRecipients', 'UpdateAccess']) {
    testWidgets('$operation presents effects and update confirmation',
        (tester) async {
      await tester.pumpWidget(host(TileShareReviewCard(
          result: {
            ...review,
            'Operation': operation,
            'Review': {
              'Operation': operation,
              'Name': 'Launch',
              'Tilettes': [],
              'EffectsSummary':
                  'Participant: 1 calendar to suspend; independent grants survive.'
            }
          },
          onConfirm: (_) async => {},
          onCheck: () async => {},
          onChanged: (_) {})));
      expect(find.textContaining('1 calendar to suspend'), findsOneWidget);
      expect(find.text('Confirm update'), findsOneWidget);
      expect(find.text('Confirm creation'), findsNothing);
    });
  }
  testWidgets('queued schedule update offers read-only status check',
      (tester) async {
    var confirmations = 0;
    Map<String, dynamic>? changed;
    await tester.pumpWidget(host(TileShareReviewCard(
        disabled: true,
        result: {
          'State': 'Pending',
          'ActionId': 'a',
          'Operation': 'UpdateTilette'
        },
        onConfirm: (_) async {
          confirmations++;
          return {};
        },
        onCheck: () async => {'State': 'Applied', 'ActionId': 'a'},
        onChanged: (result) => changed = result)));
    expect(find.textContaining('No changes have been saved'), findsOneWidget);
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    expect(confirmations, 0);
    expect(changed?['State'], 'Applied');
  });
  testWidgets('failed calculation has no mutation retry', (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Failed',
          'ActionId': 'a',
          'ErrorCode': 'schedule_no_fit'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.textContaining('No changes were applied'), findsOneWidget);
    expect(find.text('Check status'), findsNothing);
  });
  testWidgets('schedule effects accompany one update confirmation',
      (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          ...review,
          'Review': {
            'Operation': 'UpdateTilette',
            'Name': 'Review',
            'Tilettes': [],
            'ScheduleSummary':
                'Deadline: 2035-01-12 09:00 UTC\nAccepted calendars to update: 1'
          }
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(
        find.textContaining('Accepted calendars to update: 1'), findsOneWidget);
    expect(find.text('Confirm update'), findsOneWidget);
  });
  testWidgets('confirmed rejection does not become an uncertain save',
      (tester) async {
    Map<String, dynamic>? changed;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: review,
        onConfirm: (_) async => {
              'State': 'Rejected',
              'ActionId': 'a',
              'ErrorCode': 'locked_work_conflict'
            },
        onCheck: () async => {},
        onChanged: (value) {
          changed = value;
        })));
    await tester.tap(find.text('Confirm creation'));
    await tester.pumpAndSettle();
    expect(changed?['State'], 'Rejected');
    expect(find.textContaining('No changes were applied'), findsOneWidget);
    expect(find.text('Check status'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirm creation'))
            .onPressed,
        isNull);
  });
  testWidgets('composite update reviews both fields with one confirmation',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'combined',
          'Review': {
            'Operation': 'UpdateTilette',
            'Name': 'Weekly review',
            'PreviousName': 'Review',
            'ProjectName': 'Launch',
            'UpdatesName': true,
            'UpdatesNotes': true,
            'PreviousNotes': 'Old instructions',
            'Notes': '',
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'UpdateTilette'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Review tilette update'), findsOneWidget);
    expect(find.text('Current name: Review'), findsOneWidget);
    expect(find.text('Old instructions'), findsOneWidget);
    expect(find.text('Clear notes'), findsOneWidget);
    expect(token, isNull);
    await tester.tap(find.text('Confirm update'));
    await tester.pumpAndSettle();
    expect(token, 'combined');
  });
  testWidgets('composite name-only update does not clear omitted notes',
      (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'combined',
          'Review': {
            'Operation': 'UpdateTilette',
            'Name': 'Weekly review',
            'PreviousName': 'Review',
            'UpdatesName': true,
            'UpdatesNotes': false,
            'Tilettes': []
          }
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Clear notes'), findsNothing);
    expect(find.text('Current notes'), findsNothing);
    expect(find.text('Confirm update'), findsOneWidget);
  });
  testWidgets('saved composite update reports an update', (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'UpdateTilette'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Tilette updated.'), findsOneWidget);
  });
  testWidgets('rename review shows both names and confirms the exact proposal',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'rename',
          'Review': {
            'Operation': 'RenameProject',
            'Name': 'Release',
            'PreviousName': 'Launch',
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'RenameProject'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Rename project: Release'), findsOneWidget);
    expect(find.text('Current name: Launch'), findsOneWidget);
    expect(token, isNull);
    await tester.tap(find.text('Confirm rename'));
    await tester.pumpAndSettle();
    expect(token, 'rename');
  });
  testWidgets('saved rename reports a rename instead of creation',
      (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'RenameProject'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Project renamed.'), findsOneWidget);
    expect(find.text('TileShare created.'), findsNothing);
    expect(find.text('Confirm rename'), findsNothing);
  });
  testWidgets('tilette rename keeps project context and saved result',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'tilette',
          'Review': {
            'Operation': 'RenameTilette',
            'Name': 'API review',
            'PreviousName': 'Review',
            'ProjectName': 'Launch',
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'RenameTilette'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Rename tilette: API review'), findsOneWidget);
    expect(find.text('Project: Launch'), findsOneWidget);
    await tester.tap(find.text('Confirm rename'));
    await tester.pumpAndSettle();
    expect(token, 'tilette');
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'RenameTilette'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Tilette renamed.'), findsOneWidget);
  });
  testWidgets('renders effects and approves only after a tap', (tester) async {
    String? token;
    Map<String, dynamic>? changed;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: review,
        onConfirm: (value) async {
          token = value;
          return {'State': 'Applied', 'ActionId': 'a'};
        },
        onCheck: () async => {},
        onChanged: (value) => changed = value)));
    expect(token, isNull);
    expect(find.textContaining('ada@example.test'), findsOneWidget);
    await tester.tap(find.text('Confirm creation'));
    await tester.pumpAndSettle();
    expect(token, 'exact');
    expect(changed?['State'], 'Applied');
  });
  testWidgets(
      'uncertain response requires a read-only check before another attempt',
      (tester) async {
    int writes = 0, reads = 0;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: review,
        onConfirm: (value) async {
          writes++;
          throw Exception('private');
        },
        onCheck: () async {
          reads++;
          return {'State': 'Applied', 'ActionId': 'a'};
        },
        onChanged: (_) {})));
    await tester.tap(find.text('Confirm creation'));
    await tester.pumpAndSettle();
    final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm creation'));
    expect(confirm.onPressed, isNull);
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(reads, 1);
  });

  testWidgets('notes review shows previous text and explicit clearing',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'notes',
          'Review': {
            'Operation': 'SetTiletteNotes',
            'Name': 'Review',
            'ProjectName': 'Launch',
            'PreviousNotes': '<b>Original</b>',
            'Notes': '',
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'SetTiletteNotes'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Review tilette notes'), findsOneWidget);
    expect(find.text('<b>Original</b>'), findsOneWidget);
    expect(find.text('Clear notes'), findsOneWidget);
    expect(token, isNull);
    await tester.tap(find.text('Confirm notes'));
    await tester.pumpAndSettle();
    expect(token, 'notes');
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'SetTiletteNotes'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Tilette notes updated.'), findsOneWidget);
  });

  testWidgets('deletion displays effects and requires an explicit tap',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'delete',
          'Review': {
            'Operation': 'DeleteTilette',
            'Name': 'Review',
            'ProjectName': 'Launch',
            'AssignmentCount': 2,
            'LinkedCalendarCount': 3,
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'DeleteTilette'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Review tilette deletion'), findsOneWidget);
    expect(find.text('Assignments: 2'), findsOneWidget);
    expect(find.text('Linked calendar items: 3'), findsOneWidget);
    expect(token, isNull);
    await tester.tap(find.text('Confirm deletion'));
    await tester.pumpAndSettle();
    expect(token, 'delete');
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'DeleteTilette',
          'Url': '/tileshare/p'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Tilette deleted.'), findsOneWidget);
    expect(find.text('Open project'), findsOneWidget);
  });
  testWidgets('project update reviews both fields with one confirmation',
      (tester) async {
    String? token;
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'NotAttempted',
          'ActionId': 'a',
          'ReviewToken': 'combined',
          'Review': {
            'Operation': 'UpdateProject',
            'Name': 'Weekly review',
            'PreviousName': 'Review',
            'ProjectName': 'Launch',
            'UpdatesName': true,
            'UpdatesNotes': true,
            'PreviousNotes': 'Old instructions',
            'Notes': '',
            'Tilettes': []
          }
        },
        onConfirm: (value) async {
          token = value;
          return {
            'State': 'Applied',
            'ActionId': 'a',
            'Operation': 'UpdateProject'
          };
        },
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Review project update'), findsOneWidget);
    expect(find.text('Current name: Review'), findsOneWidget);
    expect(find.text('Old instructions'), findsOneWidget);
    expect(find.text('Clear notes'), findsOneWidget);
    expect(token, isNull);
    await tester.tap(find.text('Confirm update'));
    await tester.pumpAndSettle();
    expect(token, 'combined');
  });
  testWidgets('saved project update reports an update', (tester) async {
    await tester.pumpWidget(host(TileShareReviewCard(
        result: {
          'State': 'Applied',
          'ActionId': 'a',
          'Operation': 'UpdateProject'
        },
        onConfirm: (_) async => {},
        onCheck: () async => {},
        onChanged: (_) {})));
    expect(find.text('Project updated.'), findsOneWidget);
  });
}
