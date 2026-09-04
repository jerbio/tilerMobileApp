import 'package:flutter/material.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// Full-day parametric event grid (DayGrid).
///
/// P1 C1: the grid is handed a plain [tiles] list instead of a `PeekDay`,
/// so the same widget serves the forecast peek day AND (step 1.5) the
/// Daily-view toggle. Callers adapt:
///   - `DayCast` passes `peekDay.subEvents`,
///   - the daily page passes its filtered schedule list.
class DayGridWidget extends StatefulWidget {
  /// The tiles to render. Never mutated by the grid.
  final List<SubCalendarEvent> tiles;

  /// Called with the tapped tile (named arg `tilerEvent`) on tile tap,
  /// matching the previous `DayCast` hook.
  final Function? onTileTap;

  /// P1 (step 1.4): the zoom source. When omitted the grid owns a default
  /// [DayGridController] (80 px/h, matching the historical constant).
  final DayGridController? controller;

  const DayGridWidget({
    this.tiles = const <SubCalendarEvent>[],
    this.onTileTap,
    this.controller,
  });

  @override
  DayGridWidgetState createState() => DayGridWidgetState();
}

class DayGridWidgetState extends State<DayGridWidget> {
  ScrollController _scrollController = ScrollController();

  /// The zoom source. Either the caller's controller or a grid-owned
  /// default (disposed with the grid).
  late DayGridController _controller;
  DayGridController? _ownedController;

  /// 24 hour rows make up the day.
  static const int timeCellCount = 24;

  /// Fallback initial scroll position (hours) when the day has no tiles —
  /// keeps the previous 8am "active hour" behaviour.
  static const int defaultScrollHour = 8;

  /// Tiles of at least this length belong to the pinned strip (C7, step
  /// 1.7), not the timeline (matches `Utility.activeDayDuration`).
  static const Duration extendedTileDuration = Duration(hours: 16);

  /// One-shot pending scroll target (px), applied clamped after the next
  /// frame. `null` when no initial sync is queued.
  double? _pendingScrollTo;

  /// Tapped tile ids. Selection only changes z-order (the selected tile
  /// draws on top); it never duplicates tile widgets.
  final Set<String> _selectedEventIds = <String>{};

  double get _pxPerHour => _controller.pxPerHour;

  @override
  void initState() {
    super.initState();
    _ownedController = null;
    _controller = widget.controller ?? (_ownedController = DayGridController());
    _resyncInitialScroll();
  }

  @override
  void didUpdateWidget(covariant DayGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _ownedController?.dispose();
      _ownedController = null;
      _controller =
          widget.controller ?? (_ownedController = DayGridController());
    }
    if (identical(oldWidget.tiles, widget.tiles)) {
      return; // same instance: parent rebuilt with the same data.
    }
    // New data: a selection may now point at a tile that is gone, and the
    // initial scroll syncs to the first tile again (previous UX).
    _selectedEventIds.clear();
    _resyncInitialScroll();
  }

  /// Queue an initial scroll to the first tile's start hour.
  void _resyncInitialScroll() {
    final firstHour = _firstTileStartHour();
    _pendingScrollTo = _pxPerHour * (firstHour ?? defaultScrollHour);
  }

  int? _firstTileStartHour() {
    int? minStart;
    for (final tile in widget.tiles) {
      final start = tile.start;
      if (start != null && (minStart == null || start < minStart)) {
        minStart = start;
      }
    }
    if (minStart == null) {
      return null;
    }
    return Utility.localDateTimeFromMs(minStart).hour;
  }

  /// The grid day: midnight of the earliest tile's start date. `null` for
  /// an empty day (nothing renders anyway).
  DateTime? _gridDayStart() {
    int? minStart;
    for (final tile in widget.tiles) {
      final start = tile.start;
      if (start != null && (minStart == null || start < minStart)) {
        minStart = start;
      }
    }
    if (minStart == null) {
      return null;
    }
    final dt = Utility.localDateTimeFromMs(minStart);
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Step 1.4 exclusions: extended (>=16h / all-day) tiles belong to the
  /// pinned strip (C7), and tiles fully outside the grid day have no
  /// presence in this day's timeline.
  bool _renderableInTimeline(SubCalendarEvent tile, DateTime? dayStart) {
    if (tile.isAllDay || tile.duration >= extendedTileDuration) {
      return false;
    }
    if (dayStart == null) {
      return true;
    }
    final dayStartMs = dayStart.millisecondsSinceEpoch;
    final dayEndMs = dayStartMs + Duration.millisecondsPerDay;
    final startMs = tile.start ?? dayStartMs;
    final endMs = tile.end ?? dayEndMs;
    return endMs > dayStartMs && startMs < dayEndMs;
  }

  /// Time-sorted copy — never sorts [DayGridWidget.tiles] in place (C1).
  List<SubCalendarEvent> _sortedTiles() {
    final sorted = List<SubCalendarEvent>.of(widget.tiles);
    sorted.sort((a, b) => (a.start ?? 0).compareTo((b.start ?? 0)));
    return sorted;
  }

  void onTileGridTap({TilerEvent? tilerEvent}) {
    if (tilerEvent != null && tilerEvent.id.isNot_NullEmptyOrWhiteSpace()) {
      if (tilerEvent is SubCalendarEvent) {
        setState(() {
          _selectedEventIds.clear();
          _selectedEventIds.add(tilerEvent.id!);
        });
      }
    }
    if (widget.onTileTap != null) {
      widget.onTileTap!(tilerEvent: tilerEvent);
    }
  }

  void _applyPendingScroll(Duration _) {
    final target = _pendingScrollTo;
    _pendingScrollTo = null;
    if (!mounted || target == null) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }
    // C1: clamp — jumpTo asserts on out-of-range values in debug.
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) {
      _scrollController.jumpTo(clamped);
    }
    Utility.debugPrint('DayGrid:: initial scroll -> '
        '${clamped.toStringAsFixed(1)}px');
  }

  @override
  Widget build(BuildContext context) {
    // C1 hardening: everything below is derived fresh from
    // [DayGridWidget.tiles] — no state-list appends, no in-place sort.
    final sortedTiles = _sortedTiles();

    // Invariant: no duplicate tile ids per build.
    final seenIds = <String>{};
    for (final tile in sortedTiles) {
      if (tile.id.isNot_NullEmptyOrWhiteSpace()) {
        assert(seenIds.add(tile.id!),
            'DayGrid:: duplicate tile id "${tile.id}" in one build');
      }
    }

    if (constant.isDebug) {
      Utility.debugPrint('DayGrid:: rebuild with ${sortedTiles.length} tiles');
    }

    // Step 1.4: every position/height derives from the controller's
    // pxPerHour and the real viewport width — no hard-coded 80 / 270.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final pxPerHour = _pxPerHour;
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth.isFinite ? constraints.maxWidth : null;
            final gutter = TileDimensions.timeOfDayCellWidth;
            final tileLeft = gutter + 4;
            final tileWidth = maxWidth != null ? maxWidth - gutter - 8 : 270.0;
            final dayStart = _gridDayStart();

            // Renderable tiles: id'd, inside the grid day, and not extended
            // (>=16h / all-day -> the pinned strip, step 1.7).
            final renderable = sortedTiles
                .where((t) => t.id.isNot_NullEmptyOrWhiteSpace())
                .where((t) => _renderableInTimeline(t, dayStart))
                .toList();

            // Z-order: the selected tile renders last (on top) — same
            // behaviour as before, without duplicating the widget.
            final unselected = renderable
                .where((t) => !_selectedEventIds.contains(t.id))
                .toList();
            final selected = renderable
                .where((t) => _selectedEventIds.contains(t.id))
                .toList();

            // 24-hour gutter: time labels + hour rows at pxPerHour.
            final gutterWidgets = <Widget>[];
            for (int hour = 0; hour < timeCellCount; hour++) {
              final timeOfDay = TimeOfDay(hour: hour, minute: 0);
              gutterWidgets.add(TimeOfDayTimeCellWidget(
                start: timeOfDay,
                height: pxPerHour,
              ));
              gutterWidgets.add(TileTimeCellWidget(
                start: timeOfDay,
                left: gutter,
                height: pxPerHour,
              ));
            }

            final tileWidgets = [...unselected, ...selected]
                .map(
                  (tile) => TileGridWidget(
                    // Stable per-tile identity: add/remove/replace of
                    // tiles maps to element remove/update — never a stale
                    // reused state.
                    key: ValueKey<String>('daygrid_tile_${tile.uniqueId}'),
                    tilerEvent: tile,
                    onTap: onTileGridTap,
                    pxPerHour: pxPerHour,
                    dayStart: dayStart,
                    left: tileLeft,
                    tileGridWidth: tileWidth,
                  ),
                )
                .toList();

            if (_pendingScrollTo != null) {
              WidgetsBinding.instance.addPostFrameCallback(_applyPendingScroll);
            }

            return SingleChildScrollView(
              controller: _scrollController,
              child: Stack(
                children: <Widget>[
                  Container(height: timeCellCount * pxPerHour),
                  ...gutterWidgets,
                  ...tileWidgets,
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _ownedController?.dispose(); // own resources first (C1: dispose order)
    _scrollController.dispose();
    super.dispose();
  }
}
