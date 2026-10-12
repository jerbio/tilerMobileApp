import 'package:flutter/widgets.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

/// Where to put the list back after a schedule change: the anchor tile's
/// new row, at the same fraction down the viewport it sat at before.
class ListAnchorRestore {
  final String tileId;
  final int previousRow;
  final int row;

  /// The row's leading edge as a fraction of the viewport (0 = top).
  final double alignment;

  const ListAnchorRestore({
    required this.tileId,
    required this.previousRow,
    required this.row,
    required this.alignment,
  });

  /// Rows were added or removed above the anchor, so the list would jump.
  bool get moved => row != previousRow;
}

/// Keeps the daily list from jumping when a schedule change adds or removes
/// rows above what the user is looking at.
///
/// Before the rows for a schedule change are built, [capture] picks the
/// anchor tile from the change (the tile the user acted on, else the nearest
/// unchanged tile by the change, else the first unchanged tile in view) and
/// notes where it sits on screen. After the rows are built, [resolve] says
/// where it should sit now. Without a change nothing moves.
class ListAnchorKeeper {
  Map<String, int> _rowOfTile = const <String, int>{};
  _Captured? _captured;
  ListChange? _change;

  /// The change seen by the last [capture]; handed out once.
  ListChange? takeChange() {
    final change = _change;
    _change = null;
    return change;
  }

  /// Call at the start of a build with the tiles about to be shown and the
  /// schedule [change] they come with (null when there is none).
  ///
  /// [visibleRows] are the row indexes fully on screen right now, in screen
  /// order, and [alignmentOf] gives a row's leading edge as a fraction of
  /// the viewport (null when it is not laid out).
  void capture({
    required ScheduleChange? change,
    required List<SubCalendarEvent> tiles,
    required Timeline day,
    required List<int> visibleRows,
    required double? Function(int row) alignmentOf,
  }) {
    _captured = null;
    _change = null;
    if (change == null || _rowOfTile.isEmpty) return;
    final tileOfRow = <int, String>{};
    _rowOfTile.forEach((id, row) => tileOfRow.putIfAbsent(row, () => id));
    final visibleIds = [
      for (final row in visibleRows)
        if (tileOfRow[row] != null) tileOfRow[row]!,
    ];
    bool otherDay(SubCalendarEvent t) =>
        t.start != null && (t.start! < day.start! || t.start! >= day.end!);
    // The change's own before/after, limited to tiles this list shows (or
    // just showed) plus other days, so hidden tiles never count and tiles
    // that left for another day read as moved rather than removed.
    final shown = <String>{
      ..._rowOfTile.keys,
      for (final t in tiles) t.uniqueId
    };
    final delta = ScheduleDelta.compute(
      before: [
        for (final t in change.before)
          if (otherDay(t) || shown.contains(t.uniqueId)) t,
      ],
      after: [...tiles, ...change.after.where(otherDay)],
      day: day,
    );
    final attribution = change.attribution;
    _change = ListChange(delta, attribution);
    final anchorId = delta.anchorFor(
      visibleIds: visibleIds,
      subjectId: attribution.subjectId,
    );
    if (anchorId == null) return;
    final row = _rowOfTile[anchorId];
    final alignment = row == null ? null : alignmentOf(row);
    if (row == null || alignment == null) return;
    _captured = _Captured(anchorId, row, alignment);
  }

  /// Call once the new rows are built. Records them for the next change and
  /// returns where the captured anchor should go, if anywhere.
  ListAnchorRestore? resolve(Map<String, int> rowOfTile) {
    _rowOfTile = rowOfTile;
    final captured = _captured;
    _captured = null;
    if (captured == null) return null;
    final row = rowOfTile[captured.tileId];
    if (row == null) return null;
    return ListAnchorRestore(
      tileId: captured.tileId,
      previousRow: captured.row,
      row: row,
      alignment: captured.alignment,
    );
  }
}

/// A new schedule revision as the list saw it: what changed on the day and
/// what caused it.
class ListChange {
  final ScheduleDelta delta;
  final ScheduleChangeAttribution attribution;

  const ListChange(this.delta, this.attribution);
}

/// Where each built row sits, for lists that keep a pixel scroll offset
/// (rather than a row index) and so can't report row positions themselves.
class ListRowRegistry {
  final Map<String, BuildContext> _rows = <String, BuildContext>{};

  /// [rowKey]'s leading edge as a fraction of the scroll viewport [scroll]
  /// (0 = top); null when the row is not built or laid out.
  double? alignmentOf(String rowKey, ScrollPosition scroll) {
    final row = _rows[rowKey]?.findRenderObject();
    final viewport = scroll.context.storageContext.findRenderObject();
    if (row is! RenderBox ||
        viewport is! RenderBox ||
        !row.attached ||
        !row.hasSize ||
        scroll.viewportDimension <= 0) {
      return null;
    }
    final top = row.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return top / scroll.viewportDimension;
  }

  /// [rowKey]'s box in [ancestor]'s coordinates; null when the row is not
  /// built or laid out.
  Rect? rectOf(String rowKey, RenderBox ancestor) {
    final row = _rows[rowKey]?.findRenderObject();
    if (row is! RenderBox || !row.attached || !row.hasSize) return null;
    final topLeft = row.localToGlobal(Offset.zero, ancestor: ancestor);
    return topLeft & row.size;
  }
}

/// Registers a list row in a [ListRowRegistry] while it is built.
class ListRowProbe extends StatefulWidget {
  final String rowKey;
  final ListRowRegistry registry;
  final Widget child;

  ListRowProbe({
    required this.rowKey,
    required this.registry,
    required this.child,
  }) : super(key: ValueKey<String>(rowKey));

  @override
  State<ListRowProbe> createState() => _ListRowProbeState();
}

class _ListRowProbeState extends State<ListRowProbe> {
  @override
  void initState() {
    super.initState();
    widget.registry._rows[widget.rowKey] = context;
  }

  @override
  void didUpdateWidget(ListRowProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowKey != widget.rowKey) {
      _forget(oldWidget.rowKey);
      widget.registry._rows[widget.rowKey] = context;
    }
  }

  @override
  void dispose() {
    _forget(widget.rowKey);
    super.dispose();
  }

  void _forget(String rowKey) {
    if (identical(widget.registry._rows[rowKey], context)) {
      widget.registry._rows.remove(rowKey);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Captured {
  final String tileId;
  final int row;
  final double alignment;

  const _Captured(this.tileId, this.row, this.alignment);
}
