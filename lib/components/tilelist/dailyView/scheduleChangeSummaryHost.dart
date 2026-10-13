import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/scheduleChipInsets.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryChip.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/services/scheduleMotion.dart';

/// Shows the "Plan updated" chip over the Daily content (list or grid) after
/// a schedule change on the day being viewed, through the calendar's
/// [ScheduleNoticeSurface].
///
/// Listens to [ScheduleBloc]; each new server revision is diffed against the
/// previous one for [currentDate], and a chip shows when the change is worth
/// reporting (see [ScheduleChangeSummary.from]). The chip hides on its own
/// after [visibleFor], when the day changes, or once its details are opened
/// and closed. It shows in every "Schedule updates" mode; only its own
/// entrance is skipped when motion is off.
class ScheduleChangeSummaryHost extends StatefulWidget {
  final DateTime currentDate;
  final Widget child;
  final Duration visibleFor;

  const ScheduleChangeSummaryHost({
    super.key,
    required this.currentDate,
    required this.child,
    this.visibleFor = const Duration(seconds: 6),
  });

  @override
  State<ScheduleChangeSummaryHost> createState() =>
      _ScheduleChangeSummaryHostState();
}

class _ScheduleChangeSummaryHostState extends State<ScheduleChangeSummaryHost> {
  /// Schedule changes as they happen, from the bloc's change feed.
  StreamSubscription<ScheduleChange>? _changes;
  ScheduleChangeSummary? _summary;
  Timer? _hideTimer;

  /// The change currently playing step by step ("3 Tiles moving"), shown
  /// until the chip takes over.
  ScheduleChangeSummary? _moving;
  Timer? _showTimer;

  /// Where the banner and chip are published.
  ScheduleNoticeBus? _bus;

  @override
  void initState() {
    super.initState();
    _bus = ScheduleNoticeBus.maybeOf(context);
    _changes =
        context.read<ScheduleBloc>().changeFeed.changes.listen(_onChange);
  }

  @override
  void didUpdateWidget(ScheduleChangeSummaryHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.currentDate, widget.currentDate)) {
      _hide();
    }
  }

  @override
  void dispose() {
    _bus?.hide(_movingNotice);
    _bus?.hide(_summaryNotice);
    _changes?.cancel();
    _hideTimer?.cancel();
    _showTimer?.cancel();
    super.dispose();
  }

  Timeline get _day {
    final date = widget.currentDate;
    final start = DateTime(date.year, date.month, date.day);
    return Timeline.fromDateTime(
        start, DateTime(date.year, date.month, date.day + 1));
  }

  void _onChange(ScheduleChange change) {
    if (!mounted) return;
    final summary = summaryForChange(change, _day);
    if (summary == null) return;
    AnalysticsSignal.send('schedule_change_summary_shown', additionalInfo: {
      'origin': summary.attribution.origin.name,
      'moved': summary.movedCount,
      'movedToOtherDays': summary.movedToOtherDaysCount,
      'added': summary.addedCount,
      'removed': summary.removedCount,
    });
    _hideTimer?.cancel();
    _showTimer?.cancel();
    // The chip follows the change: after the steps in Detailed (a banner
    // names what is moving meanwhile), after the slide in Minimal, at once
    // with motion off.
    final mode = ScheduleMotion.modeFor(context,
        origin: summary.attribution.origin, listen: false);
    final steps = mode.choreographs
        ? GridChoreography.plan(summary.delta,
            subjectId: summary.attribution.subjectId)
        : null;
    final delay = steps != null
        ? steps.end
        : (mode.animates ? const Duration(milliseconds: 300) : Duration.zero);
    void reveal() {
      if (!mounted) return;
      _moving = null;
      _summary = summary;
      _publish();
      _hideTimer = Timer(widget.visibleFor, _hide);
    }

    if (delay == Duration.zero) {
      reveal();
      return;
    }
    _summary = null;
    _moving = steps != null ? summary : null;
    _publish();
    _showTimer = Timer(delay, reveal);
  }

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    if (_summary != null || _moving != null) {
      _summary = null;
      _moving = null;
      _publish();
    }
  }

  static const Object _movingNotice = #scheduleChangeMoving;
  static const Object _summaryNotice = #scheduleChangeSummary;

  /// Puts what is showing on the calendar's notice surface: the banner in
  /// the top slot (beneath the evaluation card if it is still up), the chip
  /// in the bottom slot.
  void _publish() {
    final bus = _bus;
    if (bus == null) return;
    final moving = _moving;
    final summary = _summary;
    if (moving == null) {
      bus.hide(_movingNotice);
    } else {
      bus.show(ScheduleNotice(
          id: _movingNotice,
          slot: ScheduleNoticeSlot.top,
          priority: ScheduleNotice.progressPriority,
          builder: (_) =>
              Center(child: ScheduleChangeMovingBanner(summary: moving))));
    }
    if (summary == null) {
      bus.hide(_summaryNotice);
    } else {
      bus.show(ScheduleNotice(
          id: _summaryNotice,
          slot: ScheduleNoticeSlot.bottom,
          priority: ScheduleNotice.progressPriority,
          builder: (_) => ScheduleChangeSummaryChip(
                summary: summary,
                onSeeChanges: () => _openDetails(summary),
              )));
    }
  }

  Future<void> _openDetails(ScheduleChangeSummary summary) async {
    // Keep the chip while its details are open; it has done its job after.
    _hideTimer?.cancel();
    AnalysticsSignal.send('schedule_change_details_opened',
        additionalInfo: {'origin': summary.attribution.origin.name});
    await ScheduleChangeSheet.show(context, summary);
    _hide();
  }

  @override
  Widget build(BuildContext context) {
    // The content runs behind the bottom navigation bar; the scaffold
    // reports the bar's height as this body's bottom padding.
    return ScheduleChipInsets(
      bottomBar: MediaQuery.paddingOf(context).bottom,
      child: widget.child,
    );
  }
}
