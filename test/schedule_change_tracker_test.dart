import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';

ScheduleRevision rev(String id) => ScheduleRevision(id, id);

void main() {
  group('ScheduleChangeTracker', () {
    late DateTime now;
    late ScheduleChangeTracker tracker;

    setUp(() {
      now = DateTime(2026, 10, 8, 18);
      tracker = ScheduleChangeTracker(clock: () => now);
    });

    test('an unclaimed revision is a refresh', () {
      expect(tracker.resolve(rev('r1')).isRefresh, isTrue);
    });

    test('the first new revision after begin claims the change', () {
      tracker.resolve(rev('r0'));
      tracker.begin(ScheduleChangeOrigin.userDrag,
          baseline: rev('r0'), subjectId: 'vitd');

      // The baseline itself does not claim it.
      expect(tracker.resolve(rev('r0')).isRefresh, isTrue);

      final claimed = tracker.resolve(rev('r1'));
      expect(claimed.origin, ScheduleChangeOrigin.userDrag);
      expect(claimed.subjectId, 'vitd');

      // Claimed once: the next revision is a refresh again.
      expect(tracker.resolve(rev('r2')).isRefresh, isTrue);
    });

    test('attribution is remembered per revision', () {
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      tracker.resolve(rev('r1'));
      expect(
          tracker.resolve(rev('r1')).origin, ScheduleChangeOrigin.tilerRevise);
    });

    test('unknown revisions are refreshes and do not claim the change', () {
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      expect(tracker.resolve(null).isRefresh, isTrue);
      expect(
          tracker.resolve(const ScheduleRevision(null, 'x')).isRefresh, isTrue);
      expect(
          tracker.resolve(rev('r1')).origin, ScheduleChangeOrigin.tilerRevise);
    });

    test('abandon drops the pending change, but only for its token', () {
      final first =
          tracker.begin(ScheduleChangeOrigin.userEdit, baseline: rev('r0'));
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      tracker.abandon(first); // stale token: the newer change survives
      expect(
          tracker.resolve(rev('r1')).origin, ScheduleChangeOrigin.tilerRevise);

      final token =
          tracker.begin(ScheduleChangeOrigin.userEdit, baseline: rev('r1'));
      tracker.abandon(token);
      expect(tracker.resolve(rev('r2')).isRefresh, isTrue);
    });

    test('the latest begin wins when changes fold into one revision', () {
      tracker.begin(ScheduleChangeOrigin.userEdit, baseline: rev('r0'));
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      expect(
          tracker.resolve(rev('r1')).origin, ScheduleChangeOrigin.tilerRevise);
    });

    test('a subject can be named once known (a new tile' 's id)', () {
      final token =
          tracker.begin(ScheduleChangeOrigin.userAdd, baseline: rev('r0'));
      tracker.attachSubject(token, 'new-1');
      final claimed = tracker.resolve(rev('r1'));
      expect(claimed.origin, ScheduleChangeOrigin.userAdd);
      expect(claimed.subjectId, 'new-1');
    });

    test('naming a subject for a change no longer pending does nothing', () {
      final token =
          tracker.begin(ScheduleChangeOrigin.userAdd, baseline: rev('r0'));
      tracker.abandon(token);
      tracker.attachSubject(token, 'new-1');
      expect(tracker.resolve(rev('r1')).isRefresh, isTrue);
    });

    test('a pending change expires', () {
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      now = now.add(const Duration(minutes: 3));
      expect(tracker.resolve(rev('r1')).isRefresh, isTrue);
    });

    test('a null baseline is claimed by any known revision', () {
      tracker.begin(ScheduleChangeOrigin.userComplete, baseline: null);
      expect(
          tracker.resolve(rev('r1')).origin, ScheduleChangeOrigin.userComplete);
    });

    test('reset clears pending and history', () {
      tracker.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      tracker.resolve(rev('r1'));
      tracker.begin(ScheduleChangeOrigin.userEdit, baseline: rev('r1'));
      tracker.reset();
      expect(tracker.resolve(rev('r1')).isRefresh, isTrue);
      expect(tracker.resolve(rev('r2')).isRefresh, isTrue);
    });

    test('history is bounded', () {
      final small = ScheduleChangeTracker(clock: () => now, historyLimit: 2);
      small.begin(ScheduleChangeOrigin.tilerRevise, baseline: rev('r0'));
      small.resolve(rev('r1'));
      small.resolve(rev('r2'));
      small.resolve(rev('r3'));
      // r1 fell out of history, so asking again re-resolves as a refresh.
      expect(small.resolve(rev('r1')).isRefresh, isTrue);
    });
  });

  group('ScheduleRevisionGate', () {
    test('the first known revision renders without motion', () {
      final gate = ScheduleRevisionGate();
      expect(gate.admit(rev('r0')), isFalse);
      expect(gate.lastRendered, rev('r0'));
    });

    test('a new revision is admitted once', () {
      final gate = ScheduleRevisionGate()..admit(rev('r0'));
      expect(gate.admit(rev('r1')), isTrue);
      // Same revision again: more days loaded, a cache replay, a rebuild.
      expect(gate.admit(rev('r1')), isFalse);
    });

    test('unknown revisions never pass and are not recorded', () {
      final gate = ScheduleRevisionGate()..admit(rev('r0'));
      expect(gate.admit(null), isFalse);
      expect(gate.admit(const ScheduleRevision(null, null)), isFalse);
      expect(gate.lastRendered, rev('r0'));
      // A failed load in between does not make the old revision look new.
      expect(gate.admit(rev('r0')), isFalse);
    });

    test('reset forgets the last rendered revision', () {
      final gate = ScheduleRevisionGate()..admit(rev('r0'));
      gate.reset();
      expect(gate.admit(rev('r1')), isFalse);
    });
  });
}
