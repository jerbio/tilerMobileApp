import 'package:flutter/widgets.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_feed.dart';

/// Hands the latest [ScheduleChange] down with the tiles it belongs to.
///
/// The host builds it from the same schedule state that supplies the tiles,
/// so a view can never receive a revision's tiles without its change.
class ScheduleChangeScope extends InheritedWidget {
  final ScheduleChange? change;

  const ScheduleChangeScope({
    super.key,
    required this.change,
    required super.child,
  });

  @override
  bool updateShouldNotify(ScheduleChangeScope oldWidget) =>
      change?.id != oldWidget.change?.id;
}

/// The one way a view reacts to schedule changes: [didReceiveScheduleChange]
/// runs exactly once per change, before the build that draws its tiles.
///
/// A view that mounts after a change does not replay it. Views outside a
/// [ScheduleChangeScope] (previews, isolated tests) never receive changes.
mixin ScheduleChangeConsumer<T extends StatefulWidget> on State<T> {
  bool _seeded = false;
  int? _handledId;

  /// Starts whatever this view shows for [change]. Called during the build
  /// phase, so it may change state directly; the following build sees it.
  void didReceiveScheduleChange(ScheduleChange change);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _takeChange();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _takeChange();
  }

  void _takeChange() {
    final change = context
        .dependOnInheritedWidgetOfExactType<ScheduleChangeScope>()
        ?.change;
    if (!_seeded) {
      // Whatever is current when the view first builds is already drawn.
      _seeded = true;
      _handledId = change?.id;
      return;
    }
    if (change == null || change.id == _handledId) return;
    _handledId = change.id;
    didReceiveScheduleChange(change);
  }
}
