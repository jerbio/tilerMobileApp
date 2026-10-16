import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tiler_app/components/scheduleChipInsets.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/services/scheduleMotion.dart';

/// Shows the schedule notices from [ScheduleNoticeBus] over [child].
///
/// Every surface shows interruptions while it is the one the user sees (see
/// [ScheduleNoticeBus.interrupt]). The calendar surface also hosts ambient
/// notices in two slots:
/// - top: highest priority first, at most [topSlotLimit] — the change in
///   progress, with what it is moving beneath it while it lasts;
/// - bottom: the single highest-priority notice, clear of the navigation
///   bar and the add button. An interruption takes this slot while it
///   shows.
///
/// Without a bus it shows only [child].
class ScheduleNoticeSurface extends StatefulWidget {
  final Widget child;

  /// Whether ambient notices show here (the calendar).
  final bool hostsAmbient;

  /// An interruption-only surface, e.g. a sheet.
  const ScheduleNoticeSurface({super.key, required this.child})
      : hostsAmbient = false;

  /// The calendar: interruptions and both ambient slots.
  const ScheduleNoticeSurface.calendar({super.key, required this.child})
      : hostsAmbient = true;

  static const int topSlotLimit = 2;

  /// Whether a calendar surface above [context] shows ambient notices, so
  /// content under it should publish rather than draw its own.
  static bool hostsAmbientNotices(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SurfaceScope>()?.ambient ??
      false;

  @override
  State<ScheduleNoticeSurface> createState() => _ScheduleNoticeSurfaceState();
}

class _ScheduleNoticeSurfaceState extends State<ScheduleNoticeSurface>
    implements ScheduleNoticeHost {
  ScheduleNoticeBus? _bus;

  @override
  bool get isVisibleNow =>
      mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = ScheduleNoticeBus.maybeOf(context);
    if (identical(bus, _bus)) return;
    _bus?.removeListener(_onNotices);
    _bus?.unregister(this);
    _bus = bus;
    bus?.register(this);
    bus?.addListener(_onNotices);
  }

  @override
  void dispose() {
    _bus?.removeListener(_onNotices);
    _bus?.unregister(this);
    super.dispose();
  }

  bool _rebuildScheduled = false;

  void _onNotices() {
    if (!mounted) return;
    // Publishers below may publish while the frame builds; rebuild after.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bus = _bus;
    final scoped = _SurfaceScope(
        ambient: widget.hostsAmbient && bus != null, child: widget.child);
    if (bus == null) return widget.child;
    final interruption = bus.interruptionOn(this);
    if (!widget.hostsAmbient) {
      return Stack(clipBehavior: Clip.none, children: [
        scoped,
        if (interruption != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ScheduleInterruptionToast(
                key: ValueKey(interruption.id), interruption: interruption),
          ),
      ]);
    }

    final top = bus
        .notices(ScheduleNoticeSlot.top)
        .take(ScheduleNoticeSurface.topSlotLimit);
    final bottom = bus.notices(ScheduleNoticeSlot.bottom);
    final Widget? bottomChild = interruption != null
        ? ScheduleInterruptionToast(
            key: ValueKey(interruption), interruption: interruption)
        : bottom.isEmpty
            ? null
            : KeyedSubtree(
                key: ObjectKey(bottom.first),
                child: Builder(builder: bottom.first.builder));
    final animates = ScheduleMotion.modeFor(context).animates;
    final bottomBar = ScheduleChipInsets.bottomBarOf(context);
    return Stack(
      // The content keeps the tight size its region gives it.
      fit: StackFit.expand,
      children: [
        scoped,
        if (top.isNotEmpty)
          Positioned(
            key: const ValueKey('scheduleNoticeTopSlot'),
            top: 0,
            left: 0,
            right: 0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final notice in top)
                Padding(
                  key: ValueKey(notice.id),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Builder(builder: notice.builder),
                ),
            ]),
          ),
        Positioned(
          key: const ValueKey('scheduleNoticeBottomSlot'),
          left: 16,
          right: ScheduleChipInsets.fabClearance,
          bottom: bottomBar + ScheduleChipInsets.summaryGap,
          child: AnimatedSwitcher(
            duration:
                animates ? const Duration(milliseconds: 250) : Duration.zero,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                        .animate(animation),
                child: child,
              ),
            ),
            child: bottomChild ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _SurfaceScope extends InheritedWidget {
  final bool ambient;

  const _SurfaceScope({required this.ambient, required super.child});

  @override
  bool updateShouldNotify(_SurfaceScope oldWidget) =>
      ambient != oldWidget.ambient;
}
