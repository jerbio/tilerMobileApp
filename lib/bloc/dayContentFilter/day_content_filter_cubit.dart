import 'package:bloc/bloc.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/util.dart';

/// The Daily view's UI-only content filter (P7): show the day's rigid
/// **blocks** only, its flexible **tiles** only, or **all** of it.
///
/// Block = `isRigid == true` (C29) — the same rule `TodayStats` and the
/// preview use; third-party calendar events are imported rigid, so they are
/// blocks (C30). Everything else is a tile.
///
/// Purely a rendering filter: nothing is fetched, re-evaluated or persisted.
enum DayContentFilter {
  all,
  blocks,
  tiles;

  /// Whether [tile] is shown under this filter.
  bool matches(TilerEvent tile) {
    switch (this) {
      case DayContentFilter.all:
        return true;
      case DayContentFilter.blocks:
        return tile.isRigid == true;
      case DayContentFilter.tiles:
        return tile.isRigid != true;
    }
  }

  /// [tiles] filtered to this filter, order preserved. `all` returns the
  /// SAME list instance (identity), so a page's `didUpdateWidget` sees an
  /// unchanged input and does not re-sync anything.
  List<T> apply<T extends TilerEvent>(List<T> tiles) {
    if (this == DayContentFilter.all) return tiles;
    return tiles.where(matches).toList();
  }
}

/// Session-only holder of the active [DayContentFilter] (C32): shared by
/// both Daily layouts and every day page; starts at (and resets to) `all`
/// on each app launch — never persisted.
class DayContentFilterCubit extends Cubit<DayContentFilter> {
  DayContentFilterCubit() : super(DayContentFilter.all);

  /// Switches the filter (no-op when unchanged). [dayIndex] / [layout] are
  /// analytics context only.
  void set(DayContentFilter filter, {int? dayIndex, String? layout}) {
    if (filter == state) return;
    emit(filter);
    Utility.debugPrint(
        'DayGrid:: filter -> ${filter.name} (dayIndex: $dayIndex, layout: $layout)');
    AnalysticsSignal.send('daygrid_filter_changed', additionalInfo: {
      'to': filter.name,
      'dayIndex': dayIndex,
      'layout': layout,
    });
  }

  /// Back to `all`.
  void clear() => set(DayContentFilter.all);

  /// Auto-clear (§17.2): when a tile that was just ADDED would be hidden by
  /// the active filter, reset to `all` so the addition never vanishes on
  /// arrival. Returns whether the filter was cleared.
  bool clearIfHides(Iterable<TilerEvent> addedTiles) {
    if (state == DayContentFilter.all) return false;
    final bool hidesOne = addedTiles.any((tile) => !state.matches(tile));
    if (!hidesOne) return false;
    emit(DayContentFilter.all);
    Utility.debugPrint('DayGrid:: filter auto-cleared (added tile hidden)');
    AnalysticsSignal.send('daygrid_filter_autocleared',
        additionalInfo: {'reason': 'added_tile'});
    return true;
  }
}
