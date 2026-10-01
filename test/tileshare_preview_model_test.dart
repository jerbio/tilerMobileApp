// TileShare redesign Step 9.10 (T21): the accept preview's data model, read
// from the shapes the backend builds. The model is tolerant (a server that adds
// a field, or a value we do not know, must not crash the screen) but never
// invents a capability: nothing is allowed unless the response says so.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileSharePreview.dart';

import 'helpers/tileshare_preview_fixtures.dart';

void main() {
  TileSharePreview viable() =>
      TileSharePreview.fromJson(previewFixture('preview_viable'));

  group('a viable, stored preview', () {
    test('reads what it is about', () {
      final p = viable();
      expect(p.assignmentId, kPreviewAssignmentId);
      expect(p.name, 'Content & Marketing Report');
      expect(p.inviterName, 'Jessica Jones');
      expect(p.description, contains('content performance'));
      expect(p.durationMs, 3600000);
      expect(p.timeZone, 'America/Chicago');
      expect(p.isViable, isTrue);
      expect(p.unsupportedReason, isNull);
      expect(p.previewToken, kPreviewToken);
      expect(p.scheduleRevision, 'rev-41');
    });

    test('reads the window, the deadline and when the token runs out', () {
      final p = viable();
      expect(p.generatedAtMs, 1789500000000);
      expect(p.expiresAtMs, 1789500000000 + 15 * 60 * 1000);
      expect(p.deadlineMs, isNotNull);
      expect(p.rangeEndMs! - p.generatedAtMs!, 28 * 24 * 3600000);
    });

    test('reads the schedule around it', () {
      final p = viable();
      expect(p.current, hasLength(4));
      expect(p.proposed, hasLength(5));
      expect(p.current[2].isFixed, isTrue);
      expect(p.proposed.where((b) => b.isProposed), hasLength(1));
    });

    test('reads the task\'s own placement', () {
      final session = viable().sessions.single;
      expect(session.sessionKey, '0');
      expect(session.placement, PreviewPlacement.scheduled);
      expect(session.isProposed, isTrue);
      expect(session.viable, isTrue);
      expect(session.durationMs, 3600000);
      expect(session.endMs - session.startMs, 3600000);
      expect(session.name, 'Content & Marketing Report');
    });

    test('allows everything the response allows', () {
      final p = viable();
      expect(p.capabilities.alternatives, isTrue);
      expect(p.capabilities.fixedSessions, isTrue);
      expect(p.capabilities.reviewedAcceptance, isTrue);
      expect(p.canAccept, isTrue);
      expect(p.canFindOtherTimes, isTrue);
    });

    test('the proposed blocks are the viable proposed sessions', () {
      expect(viable().proposedSessionBlocks.map((b) => b.id), ['sub-new']);
    });
  });

  group('colour (the server sends "#RRGGBB" or null)', () {
    PreviewBlock block(Object? color) => PreviewBlock.fromJson(
        {'id': 'x', 'start': 1, 'end': 2, 'color': color});

    test('a tile has the colour the server gave it', () {
      final p = viable();
      expect(p.current[0].color, '#00695C');
      expect(p.current[0].colorArgb, 0xFF00695C);
      expect(p.current[1].colorArgb, 0xFF33691E);
    });

    test('a tile with none has none, so the app can pick its own', () {
      final p = viable();
      expect(p.current[3].color, isNull);
      expect(p.current[3].colorArgb, isNull);
      expect(p.sessions.single.colorArgb, isNull,
          reason: 'the task being previewed has no colour yet');
    });

    test('hex in either case, with or without a leading #', () {
      expect(block('#2e7d32').colorArgb, 0xFF2E7D32);
      expect(block('#2E7D32').colorArgb, 0xFF2E7D32);
      expect(block('2E7D32').colorArgb, 0xFF2E7D32);
    });

    test('anything that is not six hex digits is no colour, never a crash',
        () {
      for (final bad in ['red', '#12', '#GGGGGG', '#12345678', '', 7, null]) {
        expect(block(bad).colorArgb, isNull, reason: '$bad');
      }
    });
  });

  group('the window a task may be placed in', () {
    test('a session carries the range it is allowed in', () {
      final s = viable().sessions.single;
      expect(s.allowedStartMs, 1789500000000);
      expect(s.allowedEndMs, 1789500000000 + 7 * 24 * 3600000);
    });

    test('a tile without one has none', () {
      final b = PreviewBlock.fromJson({'id': 'x', 'start': 1, 'end': 2});
      expect(b.allowedStartMs, isNull);
      expect(b.allowedEndMs, isNull);
    });
  });

  group('the shuffle seed', () {
    test('is read when the server sends it, and absent otherwise', () {
      expect(viable().shuffleSeed, 0);
      expect(TileSharePreview.fromJson(previewFixture('revise_moved')).shuffleSeed,
          12345);
      expect(TileSharePreview.fromJson({'assignmentId': 'a'}).shuffleSeed,
          isNull);
    });
  });

  group('what may be done is what the response says', () {
    Map<String, dynamic> with_(Map<String, dynamic> changes) =>
        {...previewFixture('preview_viable'), ...changes};

    test('no token means no accept and no other times, whatever the flags',
        () {
      final p = TileSharePreview.fromJson(with_({'previewToken': null}));
      expect(p.canAccept, isFalse);
      expect(p.canFindOtherTimes, isFalse);
    });

    test('not viable means no accept', () {
      final p = TileSharePreview.fromJson(with_({'isViable': false}));
      expect(p.canAccept, isFalse);
    });

    test('a capability that is off stays off even with a token', () {
      final accept = TileSharePreview.fromJson(with_({
        'capabilities': {
          'alternatives': true,
          'fixedSessions': true,
          'reviewedAcceptance': false
        }
      }));
      expect(accept.canAccept, isFalse);
      expect(accept.canFindOtherTimes, isTrue);

      final other = TileSharePreview.fromJson(with_({
        'capabilities': {
          'alternatives': false,
          'fixedSessions': true,
          'reviewedAcceptance': true
        }
      }));
      expect(other.canFindOtherTimes, isFalse);
      expect(other.canAccept, isTrue);
    });

    test('no capabilities object means none', () {
      final json = with_({})..remove('capabilities');
      final p = TileSharePreview.fromJson(json);
      expect(p.capabilities.alternatives, isFalse);
      expect(p.capabilities.fixedSessions, isFalse);
      expect(p.capabilities.reviewedAcceptance, isFalse);
      expect(p.canAccept, isFalse);
    });

    test('the token expires when the server says, and never if it does not',
        () {
      final p = viable();
      expect(p.isExpiredAt(DateTime.fromMillisecondsSinceEpoch(p.expiresAtMs! - 1)),
          isFalse);
      expect(p.isExpiredAt(DateTime.fromMillisecondsSinceEpoch(p.expiresAtMs!)),
          isTrue);
      final none = TileSharePreview.fromJson(with_({'expiresAt': null}));
      expect(none.isExpiredAt(DateTime(2100)), isFalse);
    });
  });

  group('a preview that does not work out', () {
    test('not viable: no token, no capabilities, and what is in the way', () {
      final p = TileSharePreview.fromJson(previewFixture('preview_not_viable'));
      expect(p.isViable, isFalse);
      expect(p.previewToken, isNull);
      expect(p.canAccept, isFalse);
      expect(p.canFindOtherTimes, isFalse);
      expect(p.conflicts, hasLength(1));
      expect(p.conflicts.single.placement, PreviewPlacement.unscheduled);
      expect(p.conflicts.single.viable, isFalse);
      expect(p.proposedSessionBlocks, isEmpty,
          reason: 'an unplaced session is never drawn as a tile');
    });

    test('unsupported: the reason is named', () {
      final accepted = TileSharePreview.fromJson(
          previewFixture('preview_unsupported_already_accepted'));
      expect(accepted.isUnsupported, isTrue);
      expect(accepted.unsupportedReason,
          PreviewUnsupportedReason.alreadyAccepted);
      final constraints = TileSharePreview.fromJson(
          previewFixture('preview_unsupported_constraints'));
      expect(constraints.unsupportedReason,
          PreviewUnsupportedReason.unsupportedConstraints);
      expect(constraints.canAccept, isFalse);
    });

    test('a deadline in the past and an unheard-of reason', () {
      final past = TileSharePreview.fromJson({
        ...previewFixture('preview_unsupported_constraints'),
        'unsupportedReason': 'missingFutureDeadline'
      });
      expect(past.unsupportedReason,
          PreviewUnsupportedReason.missingFutureDeadline);
      final odd = TileSharePreview.fromJson({
        ...previewFixture('preview_unsupported_constraints'),
        'unsupportedReason': 'somethingNew'
      });
      expect(odd.unsupportedReason, PreviewUnsupportedReason.other);
      expect(odd.unsupportedReasonText, 'somethingNew');
      expect(odd.isUnsupported, isTrue);
    });
  });

  group('tolerance', () {
    test('an unknown placement is unknown, a missing one is null, case does '
        'not matter', () {
      PreviewBlock block(Object? placement) => PreviewBlock.fromJson({
            'id': 'x',
            'start': 1,
            'end': 2,
            if (placement != null) 'placement': placement
          });
      expect(block('Scheduled').placement, PreviewPlacement.scheduled);
      expect(block('scheduled').placement, PreviewPlacement.scheduled);
      expect(block('OutsideWindow').placement, PreviewPlacement.outsideWindow);
      expect(block('Conflict').placement, PreviewPlacement.conflict);
      expect(block('Teleported').placement, PreviewPlacement.unknown);
      expect(block(null).placement, isNull);
    });

    test('times may arrive as whole numbers or as doubles', () {
      final b = PreviewBlock.fromJson(
          {'id': 'x', 'start': 1789500000000.0, 'end': 1789503600000, 'duration': 3600000});
      expect(b.startMs, 1789500000000);
      expect(b.endMs, 1789503600000);
      expect(b.durationMs, 3600000);
    });

    test('missing lists are empty, extra fields are ignored', () {
      final p = TileSharePreview.fromJson({
        'assignmentId': 'a',
        'somethingNew': {'nested': true},
      });
      expect(p.current, isEmpty);
      expect(p.proposed, isEmpty);
      expect(p.sessions, isEmpty);
      expect(p.conflicts, isEmpty);
      expect(p.isViable, isFalse, reason: 'nothing says it is viable');
    });
  });

  group('other times', () {
    test('a page of options and where the next one starts', () {
      final page = PreviewOptionsPage.fromJson(previewFixture('options_page'));
      expect(page.options, hasLength(4));
      expect(page.nextOffset, 4);
      expect(page.hasMore, isTrue);
      expect(page.options.first.optionId, isNotEmpty);
      expect(page.options.first.endMs - page.options.first.startMs, 3600000);
      expect(page.options.map((o) => o.optionId).toSet(), hasLength(4));
    });

    test('the last page has no next offset', () {
      final page =
          PreviewOptionsPage.fromJson(previewFixture('options_last_page'));
      expect(page.options, hasLength(1));
      expect(page.nextOffset, isNull);
      expect(page.hasMore, isFalse);
    });

    test('each option brings its whole preview, named by the option id', () {
      final page = PreviewOptionsPage.fromJson(previewFixture('options_page'));
      for (final option in page.options) {
        expect(option.preview, isNotNull);
        expect(option.preview!.previewToken, option.optionId,
            reason: 'the option id is the token of its own preview');
        expect(option.preview!.canAccept, isTrue);
        expect(option.preview!.sessions.single.startMs, option.startMs);
        expect(option.preview!.sessions.single.endMs, option.endMs);
      }
      expect(page.options.map((o) => o.preview!.shuffleSeed).toSet(), hasLength(4),
          reason: 'each is a different arrangement');
    });

    test('an option without a preview is still an option', () {
      final page = PreviewOptionsPage.fromJson(previewFixture('options_bare'));
      expect(page.options.single.preview, isNull);
      expect(page.options.single.optionId, isNotEmpty);
    });

    test('no options at all is an empty page', () {
      final page = PreviewOptionsPage.fromJson({'options': [], 'nextOffset': null});
      expect(page.options, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('the accept operation', () {
    TileShareOperation op(String fixture) =>
        TileShareOperation.fromJson(previewFixture(fixture));

    test('queued is not done', () {
      final o = op('operation_queued');
      expect(o.operationId, kPreviewOperationId);
      expect(o.assignmentId, kPreviewAssignmentId);
      expect(o.state, OperationState.queued);
      expect(o.isFinal, isFalse);
      expect(o.calendarId, isNull);
    });

    test('completed is done, and names the calendar event', () {
      final o = op('operation_completed');
      expect(o.state, OperationState.completed);
      expect(o.isFinal, isTrue);
      expect(o.succeeded, isTrue);
      expect(o.calendarId, startsWith('CalendarEvent+'));
    });

    test('needs review is done but not a success, with its reason', () {
      final o = op('operation_needs_review');
      expect(o.state, OperationState.needsReview);
      expect(o.isFinal, isTrue);
      expect(o.succeeded, isFalse);
      expect(o.reason, 'scheduleChanged');
    });

    test('every state, however spelled, and an unheard-of one', () {
      OperationState of(String s) => TileShareOperation.fromJson(
          {'operationId': 'o', 'assignmentId': 'a', 'state': s}).state;
      expect(of('preview'), OperationState.preview);
      expect(of('queued'), OperationState.queued);
      expect(of('applied'), OperationState.applied);
      expect(of('Completed'), OperationState.completed);
      expect(of('rejected'), OperationState.rejected);
      expect(of('needsreview'), OperationState.needsReview);
      expect(of('needsReview'), OperationState.needsReview);
      expect(of('NeedsReview'), OperationState.needsReview);
      expect(of('melted'), OperationState.unknown);
      expect(TileShareOperation.fromJson(
              {'operationId': 'o', 'assignmentId': 'a', 'state': 'melted'})
          .isFinal,
          isFalse,
          reason: 'an unknown state is never treated as finished');
    });

    test('applied is still in progress; rejected is final and a failure', () {
      TileShareOperation of(String s) => TileShareOperation.fromJson(
          {'operationId': 'o', 'assignmentId': 'a', 'state': s});
      expect(of('applied').isFinal, isFalse);
      expect(of('rejected').isFinal, isTrue);
      expect(of('rejected').succeeded, isFalse);
    });
  });

  group('the recovered response', () {
    test('an accepted assignment with its calendar event', () {
      final r = TileShareAssignmentResponse.fromJson(
          previewFixture('response_accepted'));
      expect(r.id, kPreviewAssignmentId);
      expect(r.isAccepted, isTrue);
      expect(r.calendarId, startsWith('CalendarEvent+'));
    });

    test('a pending one is not accepted', () {
      final r = TileShareAssignmentResponse.fromJson({
        ...previewFixture('response_accepted'),
        'invitationStatus': 'none',
        'calendarId': null
      });
      expect(r.isAccepted, isFalse);
      expect(r.calendarId, isNull);
    });
  });
}
