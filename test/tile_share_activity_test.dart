import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareActivityWidget.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';

void main() {
  test('invitation channel is allowlisted and unknown outcomes are supported',
      () {
    final json = <String, dynamic>{
      'eventId': 'unknown',
      'schemaVersion': 1,
      'eventType': 'invitation_send_unknown',
      'clusterId': 'cluster',
      'occurredAt': 1760000000000,
      'metadata': {'channel': 'email'},
    };
    expect(TileShareActivity.fromJson(json).isKnown, isTrue);
    expect(TileShareActivity.fromJson(json).invitationChannel, 'email');
    json['metadata'] = {'channel': 'private@example.test'};
    expect(TileShareActivity.fromJson(json).invitationChannel, isNull);
    json['metadata'] = {'channel': 'email'};
    json['schemaVersion'] = 99;
    expect(TileShareActivity.fromJson(json).invitationChannel, isNull);
  });

  test('parses the server canonical event and tolerates future versions', () {
    final fixture = File(
            '../../WagTapWeb/TilerFront/TilerFront.Tests/Fixtures/TileShareActivity/AssignmentAccepted.json')
        .readAsStringSync();
    final json = jsonDecode(fixture) as Map<String, dynamic>;
    final event = TileShareActivity.fromJson(json);
    expect(event.eventType, 'assignment_accepted');
    expect(event.isKnown, isTrue);
    json['schemaVersion'] = 99;
    json['metadata'] = {'title': 'untrusted future data'};
    expect(TileShareActivity.fromJson(json).title, isNull);
  });

  testWidgets('scopes reads and clears history when access is revoked',
      (tester) async {
    var denied = false;
    Future<TileShareActivityPage> load(
        {String? clusterId, String? tiletteId, String? cursor}) async {
      expect(clusterId, 'cluster');
      expect(tiletteId, 'tilette');
      if (denied) throw TileShareActivityAccessException();
      return TileShareActivityPage.fromJson({
        'items': [
          {
            'eventId': 'one',
            'eventType': 'assignment_accepted',
            'schemaVersion': 1,
            'clusterId': 'cluster',
            'tiletteId': 'tilette',
            'occurredAt': 1760000000000,
            'targetAvailable': false
          }
        ],
        'nextCursor': null,
        'historyAvailableFrom': 1,
      });
    }

    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: TileShareActivityWidget(
                clusterId: 'cluster', tiletteId: 'tilette', loader: load))));
    await tester.pumpAndSettle();
    expect(find.text('Assignment accepted'), findsOneWidget);
    denied = true;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Assignment accepted'), findsNothing);
    expect(find.text('This activity is no longer available to you.'),
        findsOneWidget);
  });
}
