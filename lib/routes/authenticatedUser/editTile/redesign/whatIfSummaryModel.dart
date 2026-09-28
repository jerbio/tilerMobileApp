import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/util.dart';

/// Why a tile appears in the what-if summary.
enum WhatIfImpact {
  /// The change makes this tile run late (server `tardies`).
  late,

  /// The change leaves this tile without a fitting slot (server
  /// `nonViable`) — "overflow" in the UI (D22, never "unscheduled").
  overflow,
}

/// One affected tile plus why it is affected.
class WhatIfEntry {
  final SubCalendarEvent tile;
  final WhatIfImpact impact;

  const WhatIfEntry(this.tile, this.impact);

  bool get isHighPriority => tile.priority == TilePriority.high;

  /// Whether the tile carries a real placement. `TimeRange.start` defaults
  /// to `0` (epoch), so an overflow tile the server could not place at all
  /// arrives as 0 rather than null — both mean "no slot".
  bool get isPlaced => (tile.start ?? 0) > 0;

  /// The tile's start, or `null` when it has no slot (see [isPlaced]).
  DateTime? get start =>
      isPlaced ? Utility.localDateTimeFromMs(tile.start!) : null;

  DateTime? get end {
    if (!isPlaced) return null;
    final int? ms = tile.end;
    return (ms == null || ms <= 0) ? null : Utility.localDateTimeFromMs(ms);
  }
}

/// The affected tiles of ONE day, in start order.
class WhatIfDayGroup {
  /// Midnight of the day, or `null` for the undated (unplaceable) group.
  final DateTime? day;
  final List<WhatIfEntry> entries;

  const WhatIfDayGroup({required this.day, required this.entries});

  bool get isUndated => day == null;

  /// High-priority entries sort first inside a day so the most pressing
  /// consequences of the edit read first.
  int get highPriorityCount =>
      entries.where((e) => e.isHighPriority).length;
}

/// The grouped, capped shape the what-if sheet renders.
class WhatIfSummary {
  /// Every dated group, ascending. [days] is the capped view of this; the
  /// sheet renders the whole list once the user expands the
  /// "+N more days" line.
  final List<WhatIfDayGroup> allDays;

  /// Affected tiles the server could not place on any day (no start).
  /// Rendered after [days] and never counted against the cap.
  final WhatIfDayGroup? undated;

  const WhatIfSummary({
    required this.allDays,
    required this.undated,
  });

  /// The dated groups shown before expanding: at most [maxDays].
  List<WhatIfDayGroup> get days => allDays.take(maxDays).toList();

  /// Dated days beyond the cap — surfaced as a tappable "+N more days"
  /// line rather than an unbounded list.
  int get hiddenDayCount =>
      allDays.length > maxDays ? allDays.length - maxDays : 0;

  /// At most this many dated groups are listed; the rest collapse into
  /// [hiddenDayCount].
  static const int maxDays = 3;

  bool get isEmpty => allDays.isEmpty && undated == null;

  /// Builds the grouped summary from the server's two lists.
  ///
  /// Entries are grouped by the local calendar day of their start, days
  /// ascending, entries inside a day ordered high-priority first then by
  /// start. Tiles with no start (unplaceable overflow) land in [undated].
  /// [days] lists only the first [maxDays] dated groups; the remainder are
  /// counted in [hiddenDayCount] and reachable through [allDays] when the
  /// sheet expands.
  static WhatIfSummary from({
    required List<SubCalendarEvent> tardy,
    required List<SubCalendarEvent> overflow,
  }) {
    final entries = <WhatIfEntry>[
      for (final t in tardy) WhatIfEntry(t, WhatIfImpact.late),
      for (final t in overflow) WhatIfEntry(t, WhatIfImpact.overflow),
    ];

    final Map<int, List<WhatIfEntry>> byDay = <int, List<WhatIfEntry>>{};
    final List<WhatIfEntry> undatedEntries = <WhatIfEntry>[];
    for (final entry in entries) {
      final DateTime? start = entry.start;
      if (start == null) {
        undatedEntries.add(entry);
        continue;
      }
      byDay.putIfAbsent(start.universalDayIndex, () => <WhatIfEntry>[])
          .add(entry);
    }

    final List<int> dayIndexes = byDay.keys.toList()..sort();
    final List<WhatIfDayGroup> allDays = <WhatIfDayGroup>[
      for (final dayIndex in dayIndexes)
        WhatIfDayGroup(
          day: Utility.getTimeFromIndex(dayIndex),
          entries: _sorted(byDay[dayIndex]!),
        ),
    ];

    return WhatIfSummary(
      allDays: allDays,
      undated: undatedEntries.isEmpty
          ? null
          : WhatIfDayGroup(day: null, entries: _sorted(undatedEntries)),
    );
  }

  /// High priority first, then earliest start, then name — so the ordering
  /// is stable for equal keys.
  static List<WhatIfEntry> _sorted(List<WhatIfEntry> entries) {
    final sorted = List<WhatIfEntry>.of(entries);
    sorted.sort((a, b) {
      if (a.isHighPriority != b.isHighPriority) {
        return a.isHighPriority ? -1 : 1;
      }
      final int byStart =
          (a.tile.start ?? 0).compareTo(b.tile.start ?? 0);
      if (byStart != 0) return byStart;
      return (a.tile.name ?? '').compareTo(b.tile.name ?? '');
    });
    return sorted;
  }
}
