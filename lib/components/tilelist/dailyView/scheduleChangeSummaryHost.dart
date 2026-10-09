import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryChip.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/services/scheduleMotion.dart';

/// Lays the "Plan updated" chip over the Daily content (list or grid) after
/// a schedule change on the day being viewed.
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

  /// Room kept clear on the right for the floating add button.
  static const double fabClearance = 88;

  @override
  State<ScheduleChangeSummaryHost> createState() =>
      _ScheduleChangeSummaryHostState();
}

class _ScheduleChangeSummaryHostState extends State<ScheduleChangeSummaryHost> {
  final ScheduleChangeWatcher _watcher = ScheduleChangeWatcher();
  ScheduleChangeSummary? _summary;
  Timer? _hideTimer;

  /// The change currently playing step by step ("3 Tiles moving"), shown
  /// until the chip takes over.
  ScheduleChangeSummary? _moving;
  Timer? _showTimer;

  @override
  void initState() {
    super.initState();
    // Seed the watcher with what is already loaded, so the first change
    // after mounting has something to diff against.
    _observe(context.read<ScheduleBloc>().state);
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

  void _observe(ScheduleState state) {
    final bloc = context.read<ScheduleBloc>();
    final summary = _watcher.observe(state,
        day: _day, attribute: (status) => bloc.attributionFor(status));
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
      setState(() {
        _moving = null;
        _summary = summary;
      });
      _hideTimer = Timer(widget.visibleFor, _hide);
    }

    if (delay == Duration.zero) {
      reveal();
      return;
    }
    if (mounted) {
      setState(() {
        _summary = null;
        _moving = steps != null ? summary : null;
      });
    }
    _showTimer = Timer(delay, reveal);
  }

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    if (mounted && (_summary != null || _moving != null)) {
      setState(() {
        _summary = null;
        _moving = null;
      });
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
    final summary = _summary;
    final animates = ScheduleMotion.modeFor(context).animates;
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) => _observe(state),
      child: Stack(
        // The content keeps the tight size its region gives it.
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_moving != null)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child:
                  Center(child: ScheduleChangeMovingBanner(summary: _moving!)),
            ),
          Positioned(
            left: 16,
            right: ScheduleChangeSummaryHost.fabClearance,
            bottom: 16,
            child: AnimatedSwitcher(
              duration:
                  animates ? const Duration(milliseconds: 250) : Duration.zero,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: summary == null
                  ? const SizedBox.shrink()
                  : ScheduleChangeSummaryChip(
                      key: ValueKey(summary),
                      summary: summary,
                      onSeeChanges: () => _openDetails(summary),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
