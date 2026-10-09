import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';

/// How a single Tile changed on the diffed day.
enum TileChangeKind {
  /// Same id, same day, new start, same duration.
  moved,

  /// Same id, same start, new duration.
  resized,

  /// Same id, same day, new start and new duration.
  movedAndResized,

  /// Was on the diffed day, is now on another loaded day.
  movedToOtherDay,

  /// Was on another loaded day, is now on the diffed day.
  movedFromOtherDay,

  /// Only in the new snapshot (and the old snapshot covered its time).
  added,

  /// Only in the old snapshot (and the new snapshot covers its old time).
  /// Deleted, completed, or moved beyond the loaded window: the diff cannot
  /// tell these apart, so the UI words it by change origin.
  removed,
}

/// The travel time into a Tile changed (`travelTimeBefore`).
class TravelChange {
  final String id;
  final Duration before;
  final Duration after;

  /// The Tile the travel leads to, as it is now.
  final SubCalendarEvent? tile;

  const TravelChange(
      {required this.id, required this.before, required this.after, this.tile});

  Duration get delta => after - before;
}

class TileChange {
  final TileChangeKind kind;
  final String id;
  final SubCalendarEvent? before;
  final SubCalendarEvent? after;

  /// Set when the travel into this Tile also changed.
  final TravelChange? travel;

  const TileChange(
      {required this.kind,
      required this.id,
      this.before,
      this.after,
      this.travel});

  /// Movers get choreographed (lift/move/settle); added/removed only
  /// enter/exit.
  bool get isMover =>
      kind != TileChangeKind.added && kind != TileChangeKind.removed;

  Duration get startShift => before == null || after == null
      ? Duration.zero
      : Duration(milliseconds: after!.start! - before!.start!);

  Duration get durationShift => before == null || after == null
      ? Duration.zero
      : Duration(
          milliseconds:
              (after!.end! - after!.start!) - (before!.end! - before!.start!));
}

/// A run of changed Tiles with no unchanged Tile between them, in day order.
/// Clusters only decide the play order.
class ChangeCluster {
  final List<TileChange> tiles;

  const ChangeCluster(this.tiles);

  /// The cluster's cause, when its first Tile's travel changed.
  TravelChange? get cause => tiles.first.travel;
}

/// Up to [ScheduleDelta.batchSize] movers that lift, move and settle together.
class ChangeBatch {
  final int index;
  final List<TileChange> tiles;

  /// Travel changes that play at the start of this batch (the causes of the
  /// clusters whose first Tile is in this batch).
  final List<TravelChange> causes;

  const ChangeBatch(
      {required this.index, required this.tiles, required this.causes});
}

/// Which choreography tier the change gets, by how many Tiles moved.
enum ScheduleDeltaTier {
  /// No movers (nothing changed, or only adds/removes).
  none,
  single,

  /// 2 to [ScheduleDelta.maxBatchedTiles] movers.
  batched,

  /// More movers than the batches can carry: everything moves at once.
  compressed,

  /// The day had Tiles and now has none.
  dayEmptied,

  /// The day had no Tiles and now has some.
  dayFilled,
}

/// What changed on one day between two schedule snapshots.
///
/// Pure: no Flutter, no bloc. Tiles are matched by [TilerEvent.uniqueId],
/// which is the sub-event id for Tiler Tiles and `thirdpartyId` for
/// third-party ones, so a third-party Tile whose `id` changes still matches.
/// All-day / >= 16h Tiles are left out (the grid pins them outside the
/// timeline), as are Tiles without a usable id or times.
class ScheduleDelta {
  static const int batchSize = 3;
  static const int maxBatches = 3;
  static const int maxBatchedTiles = batchSize * maxBatches;

  /// Shifts smaller than this are noise, not moves.
  static const Duration noiseThreshold = Duration(minutes: 1);

  final Timeline day;
  final List<TileChange> changes;

  /// Every travel change on the day, including ones on Tiles that did not
  /// move.
  final List<TravelChange> travelChanges;
  final List<ChangeCluster> clusters;
  final List<ChangeBatch> batches;
  final int tileCountBefore;
  final int tileCountAfter;

  /// Total free minutes between the day's Tiles (gaps minus travel).
  final int freeMinutesBefore;
  final int freeMinutesAfter;
  final int longestFreeMinutesBefore;
  final int longestFreeMinutesAfter;

  /// Free gaps between the day's tiles that this change opened up or made
  /// longer, in time order.
  final List<FreeGap> grownGaps;

  final Set<String> _afterIdsOnDay;
  final Map<String, TileChange> _changeById;

  ScheduleDelta._({
    required this.day,
    required this.changes,
    required this.travelChanges,
    required this.clusters,
    required this.batches,
    required this.tileCountBefore,
    required this.tileCountAfter,
    required this.freeMinutesBefore,
    required this.freeMinutesAfter,
    required this.longestFreeMinutesBefore,
    required this.longestFreeMinutesAfter,
    required this.grownGaps,
    required Set<String> afterIdsOnDay,
  })  : _afterIdsOnDay = afterIdsOnDay,
        _changeById = {for (final c in changes) c.id: c};

  bool get isEmpty => changes.isEmpty && travelChanges.isEmpty;

  List<TileChange> get movers => changes.where((c) => c.isMover).toList();

  int get tilesMoved => movers.length;

  int get freeMinutesDelta => freeMinutesAfter - freeMinutesBefore;

  TileChange? changeFor(String id) => _changeById[id];

  ScheduleDeltaTier get tier {
    if (changes.isNotEmpty && tileCountBefore > 0 && tileCountAfter == 0) {
      return ScheduleDeltaTier.dayEmptied;
    }
    if (changes.isNotEmpty && tileCountBefore == 0 && tileCountAfter > 0) {
      return ScheduleDeltaTier.dayFilled;
    }
    final count = tilesMoved;
    if (count == 0) return ScheduleDeltaTier.none;
    if (count == 1) return ScheduleDeltaTier.single;
    if (count <= maxBatchedTiles) return ScheduleDeltaTier.batched;
    return ScheduleDeltaTier.compressed;
  }

  /// Diffs [before] against [after] for [day].
  ///
  /// [beforeWindow] / [afterWindow] are the lookup timelines each snapshot
  /// was loaded for. A Tile missing from one side only counts as
  /// added/removed when that side's window covered its time; otherwise it
  /// was just loaded or unloaded, which is not a change.
  static ScheduleDelta compute({
    required List<SubCalendarEvent> before,
    required List<SubCalendarEvent> after,
    required Timeline day,
    Timeline? beforeWindow,
    Timeline? afterWindow,
  }) {
    final beforeById = _byId(before);
    final afterById = _byId(after);
    bool onDay(SubCalendarEvent e) =>
        e.start! >= day.start! && e.start! < day.end!;

    final beforeOnDay = beforeById.values.where(onDay).toList();
    final afterOnDay = afterById.values.where(onDay).toList();

    final changes = <TileChange>[];
    final travelChanges = <TravelChange>[];

    for (final b in beforeOnDay) {
      final id = b.uniqueId;
      final a = afterById[id];
      if (a == null) {
        if (_inWindow(b, afterWindow)) {
          changes.add(TileChange(
              kind: TileChangeKind.removed, id: id, before: b, after: null));
        }
        continue;
      }
      if (!onDay(a)) {
        changes.add(TileChange(
            kind: TileChangeKind.movedToOtherDay, id: id, before: b, after: a));
        continue;
      }
      final travel = _travelChange(id, b, a);
      if (travel != null) travelChanges.add(travel);
      final moved = _isShift(a.start! - b.start!);
      final resized = _isShift((a.end! - a.start!) - (b.end! - b.start!));
      if (!moved && !resized) continue;
      changes.add(TileChange(
          kind: moved && resized
              ? TileChangeKind.movedAndResized
              : (moved ? TileChangeKind.moved : TileChangeKind.resized),
          id: id,
          before: b,
          after: a,
          travel: travel));
    }

    final beforeIdsOnDay = beforeOnDay.map((e) => e.uniqueId).toSet();
    for (final a in afterOnDay) {
      final id = a.uniqueId;
      if (beforeIdsOnDay.contains(id)) continue;
      final b = beforeById[id];
      if (b != null) {
        changes.add(TileChange(
            kind: TileChangeKind.movedFromOtherDay,
            id: id,
            before: b,
            after: a));
      } else if (_inWindow(a, beforeWindow)) {
        changes.add(TileChange(
            kind: TileChangeKind.added, id: id, before: null, after: a));
      }
    }

    final clusters = _clusters(changes, afterOnDay);
    final beforeFree = _freeMinutes(beforeOnDay);
    final afterFree = _freeMinutes(afterOnDay);

    return ScheduleDelta._(
      day: day,
      changes: changes,
      travelChanges: travelChanges,
      clusters: clusters,
      batches: _batches(clusters),
      tileCountBefore: beforeOnDay.length,
      tileCountAfter: afterOnDay.length,
      freeMinutesBefore: beforeFree.$1,
      freeMinutesAfter: afterFree.$1,
      longestFreeMinutesBefore: beforeFree.$2,
      longestFreeMinutesAfter: afterFree.$2,
      grownGaps: _grownGaps(beforeOnDay, afterOnDay),
      afterIdsOnDay: afterOnDay.map((e) => e.uniqueId).toSet(),
    );
  }

  /// The Tile that should hold its screen position while this change plays.
  ///
  /// [visibleIds] are the Tiles fully on screen just before the change, in
  /// screen order. [subjectId] is the Tile the user acted on, if any (none
  /// for background refreshes). Returns null when there is nothing to
  /// anchor to.
  String? anchorFor({required List<String> visibleIds, String? subjectId}) {
    if (tileCountBefore == 0 || tileCountAfter == 0) return null;
    // 1. The subject Tile, if it is still on this day and was on screen.
    if (subjectId != null &&
        visibleIds.contains(subjectId) &&
        _afterIdsOnDay.contains(subjectId)) {
      return subjectId;
    }
    bool isStable(String id) =>
        _afterIdsOnDay.contains(id) && !_changeById.containsKey(id);
    final firstChanged = visibleIds.indexWhere(_changeById.containsKey);
    if (firstChanged < 0) {
      // 3. Nothing visible changed: the first stable Tile in view.
      for (final id in visibleIds) {
        if (isStable(id)) return id;
      }
      return null;
    }
    // 2. The nearest stable Tile before the first visible change, else
    // after it.
    for (var i = firstChanged - 1; i >= 0; i--) {
      if (isStable(visibleIds[i])) return visibleIds[i];
    }
    for (var i = firstChanged + 1; i < visibleIds.length; i++) {
      if (isStable(visibleIds[i])) return visibleIds[i];
    }
    // 4. Every visible Tile changed: the first one still on this day.
    for (var i = firstChanged; i < visibleIds.length; i++) {
      if (_afterIdsOnDay.contains(visibleIds[i])) return visibleIds[i];
    }
    // 5. None.
    return null;
  }

  static Map<String, SubCalendarEvent> _byId(List<SubCalendarEvent> tiles) {
    final byId = <String, SubCalendarEvent>{};
    for (final tile in tiles) {
      if (tile.uniqueId.isEmpty || tile.start == null || tile.end == null) {
        continue;
      }
      if (tile.isAllDay) continue;
      byId[tile.uniqueId] = tile;
    }
    return byId;
  }

  static bool _inWindow(SubCalendarEvent e, Timeline? window) =>
      window == null || (e.start! >= window.start! && e.start! < window.end!);

  static bool _isShift(int ms) => ms.abs() >= noiseThreshold.inMilliseconds;

  static int _travelMs(SubCalendarEvent e) => (e.travelTimeBefore ?? 0).round();

  static TravelChange? _travelChange(
      String id, SubCalendarEvent before, SubCalendarEvent after) {
    final b = _travelMs(before), a = _travelMs(after);
    if (!_isShift(a - b)) return null;
    return TravelChange(
        id: id,
        before: Duration(milliseconds: b),
        after: Duration(milliseconds: a),
        tile: after);
  }

  /// Orders the day's Tiles and cuts the movers into runs. Movers sort by
  /// their new start when they stay on the day, else by their old start.
  /// Unchanged Tiles break a run; added/removed Tiles neither join nor
  /// break one.
  static List<ChangeCluster> _clusters(
      List<TileChange> changes, List<SubCalendarEvent> afterOnDay) {
    final changedIds = changes.map((c) => c.id).toSet();
    final slots = <(int, String, TileChange?)>[
      for (final tile in afterOnDay)
        if (!changedIds.contains(tile.uniqueId))
          (tile.start!, tile.uniqueId, null),
      for (final change in changes.where((c) => c.isMover))
        (
          change.kind == TileChangeKind.movedToOtherDay
              ? change.before!.start!
              : change.after!.start!,
          change.id,
          change
        ),
    ]..sort((x, y) {
        final byStart = x.$1.compareTo(y.$1);
        return byStart != 0 ? byStart : x.$2.compareTo(y.$2);
      });

    final clusters = <ChangeCluster>[];
    var run = <TileChange>[];
    for (final slot in slots) {
      final change = slot.$3;
      if (change != null) {
        run.add(change);
      } else if (run.isNotEmpty) {
        clusters.add(ChangeCluster(run));
        run = <TileChange>[];
      }
    }
    if (run.isNotEmpty) clusters.add(ChangeCluster(run));
    return clusters;
  }

  /// Flattens clusters in order and cuts them into batches of
  /// [batchSize]. A cluster's cause plays with the batch holding its first
  /// Tile.
  static List<ChangeBatch> _batches(List<ChangeCluster> clusters) {
    final ordered = <TileChange>[];
    final causeAt = <int, TravelChange>{};
    for (final cluster in clusters) {
      final cause = cluster.cause;
      if (cause != null) causeAt[ordered.length] = cause;
      ordered.addAll(cluster.tiles);
    }
    final batches = <ChangeBatch>[];
    for (var start = 0; start < ordered.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, ordered.length);
      batches.add(ChangeBatch(
        index: batches.length,
        tiles: ordered.sublist(start, end),
        causes: [
          for (var i = start; i < end; i++)
            if (causeAt[i] != null) causeAt[i]!
        ],
      ));
    }
    return batches;
  }

  /// (total, longest) free minutes between consecutive Tiles, net of the
  /// travel into the next Tile.
  /// A gap only counts as grown when it gained at least this much.
  static const Duration minGapGrowth = Duration(minutes: 10);

  /// Gaps in [after] (end of one tile to the start of the travel into the
  /// next) that were at least [minGapGrowth] busier in [before].
  static List<FreeGap> _grownGaps(
      List<SubCalendarEvent> before, List<SubCalendarEvent> after) {
    final sorted = [...after]..sort((a, b) => a.start!.compareTo(b.start!));
    // Busy ranges before the change, travel included.
    final busy = [
      for (final t in before) (t.start! - _travelMs(t), t.end!),
    ];
    final gaps = <FreeGap>[];
    int? busyUntil;
    for (final tile in sorted) {
      if (busyUntil != null) {
        final gapStart = busyUntil;
        final gapEnd = tile.start! - _travelMs(tile);
        if (gapEnd > gapStart) {
          var busyBefore = 0;
          for (final (s, e) in busy) {
            final overlap =
                (e < gapEnd ? e : gapEnd) - (s > gapStart ? s : gapStart);
            if (overlap > 0) busyBefore += overlap;
          }
          // Free time gained = how much of the gap was busy before.
          final gained = busyBefore.clamp(0, gapEnd - gapStart);
          if (gained >= minGapGrowth.inMilliseconds) {
            gaps.add(FreeGap(
                startMs: gapStart,
                endMs: gapEnd,
                gained: Duration(milliseconds: gained),
                beforeTileId: tile.uniqueId));
          }
        }
      }
      if (busyUntil == null || tile.end! > busyUntil) busyUntil = tile.end!;
    }
    return gaps;
  }

  static (int, int) _freeMinutes(List<SubCalendarEvent> tiles) {
    final sorted = [...tiles]..sort((a, b) => a.start!.compareTo(b.start!));
    var total = 0, longest = 0;
    int? busyUntil;
    for (final tile in sorted) {
      if (busyUntil != null) {
        final gapMs = tile.start! - _travelMs(tile) - busyUntil;
        if (gapMs > 0) {
          final minutes = gapMs ~/ Duration.millisecondsPerMinute;
          total += minutes;
          if (minutes > longest) longest = minutes;
        }
      }
      if (busyUntil == null || tile.end! > busyUntil) busyUntil = tile.end!;
    }
    return (total, longest);
  }
}

/// A free stretch between two tiles that a change opened up or lengthened.
class FreeGap {
  final int startMs;
  final int endMs;

  /// How much more free time the stretch has than before.
  final Duration gained;

  /// The tile right after the gap.
  final String beforeTileId;

  const FreeGap({
    required this.startMs,
    required this.endMs,
    required this.gained,
    required this.beforeTileId,
  });

  Duration get length => Duration(milliseconds: endMs - startMs);
}
