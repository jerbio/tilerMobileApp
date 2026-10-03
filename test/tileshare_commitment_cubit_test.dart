// TileShare redesign Step 9.16 (§5.8, T20): answering a share I was invited
// to, from its detail. Answers go out one task at a time, in order; a partial
// failure leaves the rest pending with Retry and is never reported as done;
// an accept refreshes the schedule once (a refresh that fails is said
// separately and never undoes the answer).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_commitment_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final FakeTileShareAssignmentsSource assignments;
  late final TileShareCommitmentCubit cubit;
  int answered = 0;

  _Rig({List<DesignatedTile>? mine})
      : assignments = FakeTileShareAssignmentsSource(mine ??
            [
              tsDesignatedTile('d1', clusterId: 'k'),
              tsDesignatedTile('d2', clusterId: 'k'),
              tsDesignatedTile('d3', clusterId: 'k'),
            ]) {
    cubit = TileShareCommitmentCubit(
      assignments: assignments,
      mine: assignments.tiles,
      onAnswered: () => answered++,
    );
  }

  List<String> responds() =>
      assignments.calls.where((c) => c.startsWith('respond')).toList();
  int refreshes() =>
      assignments.calls.where((c) => c.startsWith('afterAccept')).length;
}

void main() {
  late void Function(String) originalSink;
  setUp(() {
    originalSink = TileShareLog.sink;
    TileShareLog.sink = (_) {};
  });
  tearDown(() => TileShareLog.sink = originalSink);

  test('my answer on each task, from my own designated tiles', () async {
    final rig = _Rig(mine: [
      tsDesignatedTile('d1', clusterId: 'k', status: InvitationStatus.accepted),
      tsDesignatedTile('d2', clusterId: 'k'),
    ]);
    expect(rig.cubit.state.statuses,
        {'d1': InvitationStatus.accepted, 'd2': InvitationStatus.none});
    expect(rig.cubit.state.pending, ['d2']);
    await rig.cubit.close();
  });

  test('accepting sends it and refreshes the schedule once', () async {
    final rig = _Rig(mine: [tsDesignatedTile('d1', clusterId: 'k')]);
    await rig.cubit.respond(['d1'], InvitationStatus.accepted);
    expect(rig.responds(), ['respond(d1, accepted)']);
    expect(rig.refreshes(), 1);
    expect(rig.cubit.state.statuses['d1'], InvitationStatus.accepted);
    expect(rig.answered, 1);
    await rig.cubit.close();
  });

  test('declining sends it and does not touch the schedule', () async {
    final rig = _Rig(mine: [tsDesignatedTile('d1', clusterId: 'k')]);
    await rig.cubit.respond(['d1'], InvitationStatus.declined);
    expect(rig.responds(), ['respond(d1, declined)']);
    expect(rig.refreshes(), 0);
    expect(rig.cubit.state.statuses['d1'], InvitationStatus.declined);
    await rig.cubit.close();
  });

  test('accepting all goes task by task, in order, one at a time, then one '
      'refresh', () async {
    final rig = _Rig();
    rig.assignments.hold();
    final done = rig.cubit.respond(['d1', 'd2', 'd3'], InvitationStatus.accepted);
    await Future<void>.delayed(Duration.zero);
    expect(rig.responds(), ['respond(d1, accepted)']);
    expect(rig.cubit.state.sending, {'d1', 'd2', 'd3'});
    rig.assignments.release();
    await done;
    expect(rig.responds(), [
      'respond(d1, accepted)',
      'respond(d2, accepted)',
      'respond(d3, accepted)',
    ]);
    expect(rig.refreshes(), 1);
    expect(rig.cubit.state.sending, isEmpty);
    await rig.cubit.close();
  });

  test('a task that refuses leaves it and the rest pending, says how many '
      'went through, and Retry sends only those', () async {
    final rig = _Rig();
    rig.assignments.failNextOn('respond(d2', StateError('offline'));
    await rig.cubit.respond(['d1', 'd2', 'd3'], InvitationStatus.accepted);
    final s = rig.cubit.state;
    expect(s.statuses['d1'], InvitationStatus.accepted);
    expect(s.statuses['d2'], InvitationStatus.none);
    expect(s.statuses['d3'], InvitationStatus.none);
    expect(rig.responds(), ['respond(d1, accepted)', 'respond(d2, accepted)']);
    expect(s.failure!.answered, 1);
    expect(s.failure!.total, 3);
    expect(s.failure!.status, InvitationStatus.accepted);
    expect(rig.refreshes(), 1, reason: 'one accept did go through');

    rig.assignments.calls.clear();
    await rig.cubit.retry();
    expect(rig.responds(), ['respond(d2, accepted)', 'respond(d3, accepted)']);
    expect(rig.cubit.state.failure, isNull);
    expect(rig.cubit.state.pending, isEmpty);
    await rig.cubit.close();
  });

  test('a schedule refresh that fails is said, and the answer stands',
      () async {
    final rig = _Rig(mine: [tsDesignatedTile('d1', clusterId: 'k')]);
    rig.assignments.failNextOn('afterAccept', StateError('refresh down'));
    await rig.cubit.respond(['d1'], InvitationStatus.accepted);
    expect(rig.cubit.state.statuses['d1'], InvitationStatus.accepted);
    expect(rig.cubit.state.scheduleRefreshFailed, isTrue);
    expect(rig.cubit.state.failure, isNull);
    await rig.cubit.close();
  });

  test('an answer already going out is not sent twice', () async {
    final rig = _Rig(mine: [tsDesignatedTile('d1', clusterId: 'k')]);
    rig.assignments.hold();
    final first = rig.cubit.respond(['d1'], InvitationStatus.accepted);
    await rig.cubit.respond(['d1'], InvitationStatus.accepted);
    rig.assignments.release();
    await first;
    expect(rig.responds(), ['respond(d1, accepted)']);
    await rig.cubit.close();
  });

  test('a reload brings the server\'s answers, keeping what is going out',
      () async {
    final rig = _Rig(mine: [tsDesignatedTile('d1', clusterId: 'k')]);
    rig.cubit.sync([
      tsDesignatedTile('d1', clusterId: 'k', status: InvitationStatus.declined),
      tsDesignatedTile('d4', clusterId: 'k'),
    ]);
    expect(rig.cubit.state.statuses,
        {'d1': InvitationStatus.declined, 'd4': InvitationStatus.none});
    await rig.cubit.close();
  });
}
