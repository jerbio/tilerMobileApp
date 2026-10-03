import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tileSharePreview.dart';

/// What the preview's one-day strip draws (redesign T24). The strip is the
/// Daily grid in preview mode, which takes one day's tiles; these helpers pick
/// the days the server returned, the tiles on one of them, and how many existing
/// tiles the arrangement moves. Pure, so they are tested without widgets.
abstract final class PreviewTiles {
  /// The colour of the task being previewed: it has none of its own yet, so it
  /// takes the preview accent (the desktop preview's teal).
  static const Color proposedColor = Color(0xFF009688);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _dayOfMs(int ms) =>
      _day(DateTime.fromMillisecondsSinceEpoch(ms));

  /// Every local day of the window the server returned, in order. Without a
  /// window, the days the task's sessions fall on; with nothing at all, today.
  static List<DateTime> days(TileSharePreview preview, {DateTime? today}) {
    final int? start = preview.rangeStartMs;
    final int? end = preview.rangeEndMs;
    if (start != null && end != null && end > start) {
      final DateTime first = _dayOfMs(start);
      final DateTime last = _dayOfMs(end - 1);
      final List<DateTime> result = <DateTime>[];
      for (DateTime d = first;
          !d.isAfter(last);
          d = DateTime(d.year, d.month, d.day + 1)) {
        result.add(d);
      }
      return result;
    }
    final Set<DateTime> sessionDays = <DateTime>{
      for (final PreviewBlock s in preview.sessions) _dayOfMs(s.startMs),
    };
    if (sessionDays.isEmpty) return <DateTime>[_day(today ?? DateTime.now())];
    return sessionDays.toList()..sort();
  }

  /// Whether [block] starts inside the returned window.
  static bool isInWindow(PreviewBlock block, TileSharePreview preview) {
    final int? start = preview.rangeStartMs;
    final int? end = preview.rangeEndMs;
    if (start == null || end == null) return true;
    return block.startMs >= start && block.startMs < end;
  }

  /// The strip day [block] starts on, or `null` when it is not one of [days].
  static DateTime? dayFor(PreviewBlock block, List<DateTime> days) {
    final DateTime day = _dayOfMs(block.startMs);
    return days.contains(day) ? day : null;
  }

  /// The proposed schedule's tiles that touch [day], as Daily-grid tiles: each
  /// with its own colour (none when the server sent none), the task being
  /// previewed in [proposedColor], fixed tiles rigid. Read-only.
  ///
  /// Scheduling issues are listed, never drawn: an unplaced session of the
  /// task, and work the forecast could not schedule, have no real time.
  static List<SubCalendarEvent> forDay(TileSharePreview preview, DateTime day) {
    final int from = _day(day).millisecondsSinceEpoch;
    final int to = DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch;
    final Set<String> unscheduled = <String>{
      for (final PreviewBlock issue in preview.conflicts)
        if (issue.placement == PreviewPlacement.unscheduled) issue.id,
    };
    return <SubCalendarEvent>[
      for (final PreviewBlock block in preview.proposed)
        if (block.endMs > from &&
            block.startMs < to &&
            !(block.isProposed && !block.viable) &&
            !unscheduled.contains(block.id))
          toTile(block),
    ];
  }

  /// One block as a Daily-grid tile.
  static SubCalendarEvent toTile(PreviewBlock block) {
    final int? argb = block.isProposed
        ? proposedColor.toARGB32()
        : block.colorArgb;
    return SubCalendarEvent.fromJson(<String, dynamic>{
      'id': block.id,
      'name': block.name ?? '',
      'start': block.startMs,
      'end': block.endMs,
      'isViable': block.viable || !block.isProposed,
      'isRigid': block.isFixed,
      'isReadOnly': true,
      'thirdpartyType': 'tiler',
      if (argb != null) ...<String, dynamic>{
        'colorRed': (argb >> 16) & 0xFF,
        'colorGreen': (argb >> 8) & 0xFF,
        'colorBlue': argb & 0xFF,
        'colorOpacity': 1.0,
      },
    });
  }

  /// How many of the user's existing tiles sit somewhere else in the proposal.
  static int movedCount(TileSharePreview preview) {
    final Map<String, PreviewBlock> before = <String, PreviewBlock>{
      for (final PreviewBlock b in preview.current) b.id: b,
    };
    int moved = 0;
    for (final PreviewBlock after in preview.proposed) {
      if (after.isProposed) continue;
      final PreviewBlock? was = before[after.id];
      if (was != null &&
          (was.startMs != after.startMs || was.endMs != after.endMs)) {
        moved++;
      }
    }
    return moved;
  }

  /// "Oct 9, 9:00 AM – 10:30 AM" in [locale].
  static String when(PreviewBlock block, String locale) =>
      whenRange(block.startMs, block.endMs, locale);

  /// [when] for a bare range (an arrangement that came without its preview).
  static String whenRange(int startMs, int endMs, String locale) {
    final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final DateFormat date = DateFormat.MMMEd(locale);
    final DateFormat time = DateFormat.jm(locale);
    return '${date.format(start)}, ${time.format(start)} – ${time.format(end)}';
  }

  /// When [block] may be placed, as ("Mon, Oct 5 9:00 AM", "Fri, Oct 9
  /// 5:00 PM"); `null` when the server sent no range.
  static (String, String)? window(PreviewBlock block, String locale) {
    final int? from = block.allowedStartMs;
    final int? to = block.allowedEndMs;
    if (from == null || to == null) return null;
    final DateFormat format = DateFormat.MMMEd(locale).add_jm();
    return (
      format.format(DateTime.fromMillisecondsSinceEpoch(from)),
      format.format(DateTime.fromMillisecondsSinceEpoch(to)),
    );
  }
}
