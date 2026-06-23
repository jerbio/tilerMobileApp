import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/travelDetail.dart';

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
  });

  factory DayPreviewMetrics.from({
    required List<TilerEvent> subEvents,
    required Timeline dayTimeline,
    TimelineSummary? timelineSummary,
  }) {
    int tilesCount = 0;
    int blocksCount = 0;
    int tileSharesCount = 0;
    int nonViableCount = 0;
    int workMs = 0;
    int transitMs = 0;
    int? maxClearMs;
    double? distance;
    String? distanceUnit;
    final locations = <String>{};

    for (final event in subEvents) {
      if (!event.isInterfering(dayTimeline)) continue;

      final isBlock = event.isRigid == true;
      if (isBlock) {
        blocksCount++;
      } else {
        tilesCount++;
      }

      if (event.tileShareDesignatedId != null &&
          event.tileShareDesignatedId!.trim().isNotEmpty) {
        tileSharesCount++;
      }

      final sub = event is SubCalendarEvent ? event : null;
      final isViable = sub?.isViable ?? true;
      if (!isViable) nonViableCount++;

      final isComplete = event.isComplete;

      // Work duration: non-rigid, viable, not-complete
      if (!isBlock && isViable && !isComplete) {
        workMs += event.duration.inMilliseconds;
      }

      // Day clears by: viable, not-complete (rigid or not), max end
      if (isViable && !isComplete && event.end != null) {
        if (maxClearMs == null || event.end! > maxClearMs) {
          maxClearMs = event.end!.toInt();
        }
      }

      // Transit + distance
      final travelDetail = sub?.travelDetail;
      if (travelDetail != null) {
        final beforeMs = travelDetail.before?.duration;
        final afterMs = travelDetail.after?.duration;
        if (beforeMs != null) transitMs += beforeMs.round();
        if (afterMs != null) transitMs += afterMs.round();

        final beforeDist = travelDetail.before?.distance;
        final afterDist = travelDetail.after?.distance;
        if (beforeDist != null) {
          distance = (distance ?? 0) + beforeDist;
        }
        if (afterDist != null) {
          distance = (distance ?? 0) + afterDist;
        }

        distanceUnit ??= travelDetail.before?.distanceUnit ??
            travelDetail.after?.distanceUnit;
      } else if (sub != null) {
        // Fallback to raw travel-time fields when no travelDetail is set.
        if (sub.travelTimeBefore != null) {
          transitMs += sub.travelTimeBefore!.round();
        }
        if (sub.travelTimeAfter != null) {
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
