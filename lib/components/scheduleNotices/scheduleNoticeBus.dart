import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where an ambient notice sits on the calendar.
enum ScheduleNoticeSlot {
  /// Under the day strip: the change in progress and what it is moving.
  top,

  /// Above the navigation bar, clear of the add button: what just changed.
  bottom,
}

/// Something about the schedule worth showing on the calendar for a while
/// (the "Completing · Gym" card, "3 Tiles moving", "Plan updated").
///
/// Publishing again with the same [id] replaces the notice in place.
class ScheduleNotice {
  final Object id;
  final ScheduleNoticeSlot slot;

  /// Higher shows first. In the top slot a lower one sits beneath it; in
  /// the bottom slot only the highest shows.
  final int priority;
  final WidgetBuilder builder;

  const ScheduleNotice({
    required this.id,
    required this.slot,
    required this.priority,
    required this.builder,
  });

  /// The change in progress (the evaluation card).
  static const int statusPriority = 20;

  /// What a change is doing or did ("3 Tiles moving", "Plan updated").
  static const int progressPriority = 10;
}

/// A message that answers what the user just tried ("Wait for Completing ·
/// Gym to finish"); it goes wherever the user is looking.
class ScheduleInterruption {
  final int id;
  final String message;

  const ScheduleInterruption(this.id, this.message);
}

/// A place on screen that can show schedule notices, registered with the
/// bus while mounted.
abstract class ScheduleNoticeHost {
  /// Whether the host is on the route the user sees now (no sheet or page
  /// over it).
  bool get isVisibleNow;
}

/// Publish/subscribe for schedule notices.
///
/// Publishers say what to show; surfaces ([ScheduleNoticeSurface]) decide
/// where. Ambient notices ([show]/[hide]) go to the calendar's slots, where
/// the surface arbitrates between them. Interruptions ([interrupt]) go to
/// the most recently mounted surface the user can see, so a message about
/// a tap inside a sheet shows on that sheet; with no such surface they show
/// on the root overlay, above every route.
///
/// Not a [Listenable], so it can be provided like any other service; only
/// surfaces listen, and they rebuild themselves.
class ScheduleNoticeBus {
  ScheduleNoticeBus({this.interruptionFor = const Duration(seconds: 4)});

  /// How long an interruption stays.
  final Duration interruptionFor;

  final Map<Object, ScheduleNotice> _ambient = <Object, ScheduleNotice>{};
  final List<ScheduleNoticeHost> _hosts = <ScheduleNoticeHost>[];
  ScheduleInterruption? _interruption;
  ScheduleNoticeHost? _interruptionHost;
  OverlayEntry? _overlayEntry;
  Timer? _interruptionTimer;
  int _sequence = 0;
  bool _disposed = false;
  final List<VoidCallback> _listeners = <VoidCallback>[];

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  /// The bus the app provides, if any.
  static ScheduleNoticeBus? maybeOf(BuildContext context) {
    try {
      return context.read<ScheduleNoticeBus>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Shows [notice] (or replaces the one with its id).
  void show(ScheduleNotice notice) {
    _ambient[notice.id] = notice;
    _notify();
  }

  void hide(Object id) {
    if (_ambient.remove(id) != null) _notify();
  }

  /// The notices for [slot], highest priority first; among equals, the
  /// earliest published first.
  List<ScheduleNotice> notices(ScheduleNoticeSlot slot) {
    final inSlot = [
      for (final n in _ambient.values)
        if (n.slot == slot) n
    ];
    // List.sort is not stable: keep publish order among equal priorities.
    final order = {for (var i = 0; i < inSlot.length; i++) inSlot[i]: i};
    inSlot.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : order[a]!.compareTo(order[b]!);
    });
    return inSlot;
  }

  /// The interruption [host] should show now, if any.
  ScheduleInterruption? interruptionOn(ScheduleNoticeHost host) =>
      identical(_interruptionHost, host) ? _interruption : null;

  void register(ScheduleNoticeHost host) {
    _hosts.add(host);
  }

  void unregister(ScheduleNoticeHost host) {
    _hosts.remove(host);
    if (identical(_interruptionHost, host)) _clearInterruption();
  }

  /// Shows [message] where the user is looking. [context] is where the
  /// action was attempted; its root overlay is the fallback.
  void interrupt(BuildContext context, String message) {
    _clearInterruption(notify: false);
    final interruption = ScheduleInterruption(++_sequence, message);
    _interruption = interruption;
    ScheduleNoticeHost? host;
    for (final candidate in _hosts.reversed) {
      if (candidate.isVisibleNow) {
        host = candidate;
        break;
      }
    }
    _interruptionHost = host;
    if (host == null) {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay != null) {
        _overlayEntry = OverlayEntry(
            builder: (context) => Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: ScheduleInterruptionToast(interruption: interruption),
                ));
        overlay.insert(_overlayEntry!);
      }
    }
    _interruptionTimer = Timer(interruptionFor, _clearInterruption);
    _notify();
  }

  /// The interruption showing now, wherever it is.
  ScheduleInterruption? get interruption => _interruption;

  void _clearInterruption({bool notify = true}) {
    _interruptionTimer?.cancel();
    _interruptionTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    final had = _interruption != null;
    _interruption = null;
    _interruptionHost = null;
    if (notify && had) _notify();
  }

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void dispose() {
    _disposed = true;
    _clearInterruption(notify: false);
    _listeners.clear();
  }
}

/// How an interruption looks, on any surface.
class ScheduleInterruptionToast extends StatelessWidget {
  final ScheduleInterruption interruption;

  const ScheduleInterruptionToast({super.key, required this.interruption});

  static const Key toastKey = ValueKey('scheduleInterruption');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: toastKey,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.inverseSurface,
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(interruption.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onInverseSurface)),
        ),
      ),
    );
  }
}
