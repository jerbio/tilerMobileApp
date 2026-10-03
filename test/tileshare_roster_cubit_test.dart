// TileShare redesign Step 9.13: a tilette's roster as its owner manages it.
// Every recipient with their answer, progress and how their invitation was
// delivered; adding shows at once and is never silently lost (contact-input
// doc 3.3 / 3.4), adds go out one at a time (3.5), and a removal that the
// server refuses comes back where it was.

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

Contact _email(String e) => Contact()..email = e;

class _Rig {
  final FakeTileShareRecipientsSource source;
  late final TileShareRosterCubit cubit;

  _Rig({FakeTileShareRecipientsSource? source})
      : source = source ??
            FakeTileShareRecipientsSource(
              tilettes: {
                'tpl-1': tsTilette('tpl-1', clusterId: 'c1', assignees: [
                  tsAssignee('ann@x.com',
                      status: InvitationStatus.accepted, completion: 40),
                  tsAssignee('bob@x.com'),
                ]),
              },
              activity: [
                tsActivity('e3', 'invitation_send_failed',
                    assignmentId: 'asg-bob@x.com',
                    atMsFromNow: -1000,
                    metadata: {'channel': 'sms'}),
                tsActivity('e2', 'invitation_sent',
                    assignmentId: 'asg-bob@x.com',
                    atMsFromNow: -2000,
                    metadata: {'channel': 'email'}),
                tsActivity('e1', 'invitation_sent',
                    assignmentId: 'asg-ann@x.com',
                    atMsFromNow: -3000,
                    metadata: {'channel': 'email'}),
                tsActivity('e0', 'assignment_accepted',
                    assignmentId: 'asg-ann@x.com', atMsFromNow: -500),
              ],
            ) {
    cubit = TileShareRosterCubit(
      source: this.source,
      clusterId: 'c1',
      tiletteId: 'tpl-1',
      recipients: this.source.tilettes['tpl-1']!.designatedUsers!,
    );
  }

  List<String> get labels => cubit.state.rows.map((r) => r.label).toList();
  RosterRow row(String label) =>
      cubit.state.rows.firstWhere((r) => r.label == label);
  int adds() =>
      source.calls.where((c) => c.startsWith('addRecipient')).length;
}

void main() {
  late List<String> logs;
  late void Function(String) originalSink;
  setUp(() {
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() => TileShareLog.sink = originalSink);

  group('the roster', () {
    test('every recipient with their answer and progress, in the server\'s '
        'order', () async {
      final rig = _Rig();
      expect(rig.labels, ['ann@x.com', 'bob@x.com']);
      final ann = rig.row('ann@x.com');
      expect(ann.assignmentId, 'asg-ann@x.com');
      expect(ann.rsvp, InvitationStatus.accepted);
      expect(ann.completion, 40);
      expect(ann.phase, RosterRowPhase.saved);
      await rig.cubit.close();
    });

    test('delivery is each recipient\'s newest invitation event', () async {
      final rig = _Rig();
      await rig.cubit.loadDelivery();
      expect(rig.row('bob@x.com').delivery, RecipientDelivery.failed);
      expect(rig.row('bob@x.com').deliveryChannel, 'sms');
      expect(rig.row('ann@x.com').delivery, RecipientDelivery.sent,
          reason: 'an acceptance is not a delivery event');
      expect(rig.cubit.state.deliveryLoaded, isTrue);
      expect(rig.source.calls.single, 'clusterActivity(c1)');
      await rig.cubit.close();
    });

    test('delivery that cannot be read leaves the roster as it is, logged',
        () async {
      final rig = _Rig();
      rig.source.failNextOn('clusterActivity', StateError('feed down'));
      await rig.cubit.loadDelivery();
      expect(rig.labels, ['ann@x.com', 'bob@x.com']);
      expect(rig.row('bob@x.com').delivery, isNull);
      expect(rig.cubit.state.deliveryLoaded, isFalse);
      expect(logs.any((l) => l.contains('feed down')), isTrue);
      await rig.cubit.close();
    });
  });

  group('adding', () {
    test('shows at once as being added, then as the server\'s recipient',
        () async {
      final rig = _Rig();
      rig.source.hold();
      final done = rig.cubit.add(_email('cy@x.com'));
      expect(rig.labels.last, 'cy@x.com');
      expect(rig.row('cy@x.com').phase, RosterRowPhase.adding);
      rig.source.release();
      await done;
      expect(rig.row('cy@x.com').phase, RosterRowPhase.saved);
      expect(rig.row('cy@x.com').assignmentId, 'asg-cy@x.com');
      expect(rig.labels, ['ann@x.com', 'bob@x.com', 'cy@x.com']);
      await rig.cubit.close();
    });

    test('a refused add stays visible with the reason; Retry sends it again; '
        'it can be dismissed', () async {
      final rig = _Rig();
      rig.source.failNextOn('addRecipient',
          const TileShareRecipientFailure(TileShareFailureKind.invalid,
              statusCode: 400, reason: 'An email or phone number is required.'));
      await rig.cubit.add(_email('cy@x.com'));
      final failed = rig.row('cy@x.com');
      expect(failed.phase, RosterRowPhase.addFailed);
      expect(failed.failureReason, contains('email'));
      await rig.cubit.retryAdd(failed.key);
      expect(rig.row('cy@x.com').phase, RosterRowPhase.saved);

      rig.source.failNextOn('addRecipient', StateError('offline'));
      await rig.cubit.add(_email('di@x.com'));
      rig.cubit.dismiss(rig.row('di@x.com').key);
      expect(rig.labels.contains('di@x.com'), isFalse);
      await rig.cubit.close();
    });

    test('adds go out one at a time, in order', () async {
      final rig = _Rig();
      rig.source.hold();
      final first = rig.cubit.add(_email('cy@x.com'));
      final second = rig.cubit.add(_email('di@x.com'));
      await Future<void>.delayed(Duration.zero);
      expect(rig.adds(), 1, reason: 'the second waits for the first');
      expect(rig.row('di@x.com').phase, RosterRowPhase.adding);
      rig.source.release();
      await Future.wait([first, second]);
      expect(rig.adds(), 2);
      expect(
          rig.source.calls.where((c) => c.startsWith('addRecipient')).toList(),
          ['addRecipient(tpl-1, cy@x.com)', 'addRecipient(tpl-1, di@x.com)']);
      expect(rig.labels, ['ann@x.com', 'bob@x.com', 'cy@x.com', 'di@x.com']);
      await rig.cubit.close();
    });

    test('someone already on the roster, or already being added, is not '
        'added twice', () async {
      final rig = _Rig();
      rig.source.hold();
      expect(await rig.cubit.add(_email('ANN@x.com ')), isFalse);
      final pending = rig.cubit.add(_email('cy@x.com'));
      expect(await rig.cubit.add(_email('cy@x.com')), isFalse);
      expect(rig.cubit.state.duplicate, 'cy@x.com');
      rig.source.release();
      await pending;
      expect(rig.adds(), 1);
      await rig.cubit.close();
    });
  });

  group('removing', () {
    test('disappears at once and stays gone once the server agrees', () async {
      final rig = _Rig();
      rig.source.hold();
      final done = rig.cubit.remove('asg-bob@x.com');
      expect(rig.labels, ['ann@x.com']);
      rig.source.release();
      await done;
      expect(rig.labels, ['ann@x.com']);
      expect(rig.source.calls.last, 'removeRecipient(tpl-1, asg-bob@x.com)');
      await rig.cubit.close();
    });

    test('a refused removal comes back where it was, saying so', () async {
      final rig = _Rig();
      rig.source.failNextOn('removeRecipient', StateError('offline'));
      await rig.cubit.remove('asg-ann@x.com');
      expect(rig.labels, ['ann@x.com', 'bob@x.com']);
      expect(rig.row('ann@x.com').phase, RosterRowPhase.removeFailed);
      await rig.cubit.close();
    });

    test('a recipient the server no longer has counts as removed', () async {
      final rig = _Rig();
      rig.source.failNextOn('removeRecipient',
          const TileShareRecipientFailure(TileShareFailureKind.notFound,
              statusCode: 404));
      await rig.cubit.remove('asg-bob@x.com');
      expect(rig.labels, ['ann@x.com']);
      await rig.cubit.close();
    });
  });

  test('a reload brings the server\'s roster and keeps adds not yet answered',
      () async {
    final rig = _Rig();
    rig.source.failNextOn('addRecipient', StateError('offline'));
    await rig.cubit.add(_email('cy@x.com'));
    rig.cubit.sync([
      tsAssignee('ann@x.com', status: InvitationStatus.accepted),
      tsAssignee('eve@x.com'),
    ]);
    expect(rig.labels, ['ann@x.com', 'eve@x.com', 'cy@x.com']);
    expect(rig.row('cy@x.com').phase, RosterRowPhase.addFailed);
    await rig.cubit.close();
  });
}
