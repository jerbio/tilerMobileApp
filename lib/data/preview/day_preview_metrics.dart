import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';

/// Default distance unit when the backend does not specify one on any
/// travel detail in the response.
const String kDefaultDistanceUnit = 'meters';

/// Pure value object that aggregates the metrics shown on the preview
/// sundial / summary card.
///
/// All derivations are deterministic — given the same inputs the output
/// is byte-for-byte identical, which makes the class trivially testable.
class DayPreviewMetrics {
  final int tilesCount;
  final int blocksCount;
  final int tileSharesCount;
  final int nonViableCount;
  final Duration workDuration;
  final Duration transitDuration;
  final DateTime? dayClearsBy;
  final double? distance;
  final String distanceUnit;
  final int locationsCount;
  final Duration? sleepDuration;
  final double? completionPct;

  /// Unbooked time left in the day, measured from "now" to midnight at the
  /// start of the next day. Excludes work, blocks and transit; sleep is
  /// not subtracted. Clamped to be non-negative.
  final Duration freeDuration;

  const DayPreviewMetrics({
    required this.tilesCount,
    required this.blocksCount,
    required this.tileSharesCount,
    required this.nonViableCount,
    required this.workDuration,
    required this.transitDuration,
    required this.dayClearsBy,
    required this.distance,
    required this.distanceUnit,
    required this.locationsCount,
    required this.sleepDuration,
    required this.completionPct,
    required this.freeDuration,
  });

  factory DayPreviewMetrics.from({
    required List<TilerEvent> subEvents,
    required Timeline dayTimeline,
    TimelineSummary? timelineSummary,
    DateTime? now,
  }) {
    int tilesCount = 0;
    int blocksCount = 0;
    int tileSharesCount = 0;
    int nonViableCount = 0;
    int workMs = 0;
    int blockMs = 0;
    int transitMs = 0;
    int? maxClearMs;
    double? distance;
    String? distanceUnit;
    final locations = <String>{};

    // Everything below is measured for the rest of the day: from now until
    // midnight at the start of the next day. Booked time before now does
    // not reduce remaining free time and isn't shown as upcoming transit.
    final DateTime nowTime = now ?? DateTime.now();
    final int nowMs = nowTime.millisecondsSinceEpoch;

    // Only viable, interfering events contribute to the summary. Collect
    // them in time order so we can de-duplicate shared travel: for two
    // adjacent tiles A and B, A.after == B.before, so summing both before
    // and after on every tile double counts each gap.
    final viable = <TilerEvent>[];
    for (final event in subEvents) {
      if (!event.isInterfering(dayTimeline)) continue;

      final sub = event is SubCalendarEvent ? event : null;
      final isViable = sub?.isViable ?? true;
      if (!isViable) {
        nonViableCount++;
        continue;
      }
      viable.add(event);
    }
    viable.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    for (int i = 0; i < viable.length; i++) {
      final event = viable[i];
      final isLast = i == viable.length - 1;
      final next = isLast ? null : viable[i + 1];
      final nextSub = next is SubCalendarEvent ? next : null;

      final isComplete = event.isComplete;
      final isBlock = event.isRigid == true;
      // Remaining duration after now (events fully in the past add 0).
      final int startMs = event.start ?? nowMs;
      final int endMs = event.end ?? nowMs;
      final bool isUpcoming = endMs > nowMs;
      final int remainingMs =
          (endMs - (startMs > nowMs ? startMs : nowMs)).clamp(0, endMs);
      if (isBlock) {
        blocksCount++;
        if (!isComplete) blockMs += remainingMs;
      } else {
        tilesCount++;
      }

      if (event.tileShareDesignatedId != null &&
          event.tileShareDesignatedId!.trim().isNotEmpty) {
        tileSharesCount++;
      }

      final sub = event is SubCalendarEvent ? event : null;

      // Work duration: non-rigid, not-complete
      if (!isBlock && !isComplete) {
        workMs += remainingMs;
      }

      // Day clears by: not-complete (rigid or not), max end
      if (!isComplete && event.end != null) {
        if (maxClearMs == null || event.end! > maxClearMs) {
          maxClearMs = event.end!.toInt();
        }
      }

      // Transit + distance: count each tile's "before" plus its "after",
      // but skip the "after" when it's the same shared segment as the next
      // tile's "before" (A.after == B.before) so it isn't double counted.
      // Past tiles' travel is already done, so only count upcoming tiles.
      final travelDetail = sub?.travelDetail;
      if (isUpcoming && travelDetail != null) {
        final nextBefore = nextSub?.travelDetail?.before;
        final after = travelDetail.after;
        final beforeMs = travelDetail.before?.duration;
        if (beforeMs != null) transitMs += beforeMs.round();
        final shared = after != null &&
            nextBefore != null &&
            after.duration == nextBefore.duration &&
            after.distance == nextBefore.distance;
        if (!shared && after?.duration != null) {
          transitMs += after!.duration!.round();
        }

        final beforeDist = travelDetail.before?.distance;
        if (beforeDist != null) {
          distance = (distance ?? 0) + beforeDist;
        }
        if (!shared && after?.distance != null) {
          distance = (distance ?? 0) + after!.distance!;
        }

        distanceUnit ??= travelDetail.before?.distanceUnit ??
            travelDetail.after?.distanceUnit;
      } else if (isUpcoming && sub != null) {
        // Fallback to raw travel-time fields when no travelDetail is set.
        if (sub.travelTimeBefore != null) {
          transitMs += sub.travelTimeBefore!.round();
        }
        final nextBeforeRaw = nextSub?.travelTimeBefore;
        final sharedRaw = sub.travelTimeAfter != null &&
            nextBeforeRaw != null &&
            sub.travelTimeAfter == nextBeforeRaw;
        if (!sharedRaw && sub.travelTimeAfter != null) {
          transitMs += sub.travelTimeAfter!.round();
        }
      }

      // Location dedupe: locationId, then normalized address.
      final key = _locationKey(event);
      if (key != null) locations.add(key);
    }

    final DateTime? dayClearsBy = maxClearMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(maxClearMs, isUtc: true);

    final double? completionPct = _completionPct(
      timelineSummary: timelineSummary,
      remainingNonCompleteWorkMs: _remainingWorkMs(subEvents, dayTimeline),
    );

    // Free time left in the day: from now until midnight at the start of
    // the next day, minus booked work, blocks and transit (sleep ignored).
    final DateTime nextMidnight =
        DateTime(nowTime.year, nowTime.month, nowTime.day + 1);
    int restOfDayMs = nextMidnight.difference(nowTime).inMilliseconds;
    if (restOfDayMs < 0) restOfDayMs = 0;
    int freeMs = restOfDayMs - workMs - blockMs - transitMs;
    if (freeMs < 0) freeMs = 0;

    return DayPreviewMetrics(
      tilesCount: tilesCount,
      blocksCount: blocksCount,
      tileSharesCount: tileSharesCount,
      nonViableCount: nonViableCount,
      workDuration: Duration(milliseconds: workMs),
      transitDuration: Duration(milliseconds: transitMs),
      dayClearsBy: dayClearsBy,
      distance: distance,
      distanceUnit: distanceUnit ?? kDefaultDistanceUnit,
      locationsCount: locations.length,
      sleepDuration: timelineSummary?.sleepDuration,
      completionPct: completionPct,
      freeDuration: Duration(milliseconds: freeMs),
    );
  }

  static String? _locationKey(TilerEvent event) {
    final id = event.locationId;
    if (id != null && id.trim().isNotEmpty) return 'id::${id.trim()}';
    final address = event.address;
    if (address != null && address.trim().isNotEmpty) {
      final normalized =
          address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      return 'addr::$normalized';
    }
    return null;
  }

  static int _remainingWorkMs(
      List<TilerEvent> subEvents, Timeline dayTimeline) {
    int sum = 0;
    for (final e in subEvents) {
      if (!e.isInterfering(dayTimeline)) continue;
      if (e.isComplete) continue;
      final sub = e is SubCalendarEvent ? e : null;
      final isViable = sub?.isViable ?? true;
      if (!isViable) continue;
      sum += e.duration.inMilliseconds;
    }
    return sum;
  }

  static double? _completionPct({
    required TimelineSummary? timelineSummary,
    required int remainingNonCompleteWorkMs,
  }) {
    if (timelineSummary == null) return null;
    int completeMs = 0;
    final completeList = timelineSummary.complete;
    if (completeList != null) {
      for (final c in completeList) {
        completeMs += c.duration.inMilliseconds;
      }
    }
    final totalMs = completeMs + remainingNonCompleteWorkMs;
    if (totalMs <= 0) return 0.0;
    return completeMs / totalMs;
  }
}
