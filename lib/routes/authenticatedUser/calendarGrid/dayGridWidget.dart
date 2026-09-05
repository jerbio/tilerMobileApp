import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/overlapColumns.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// Full-day parametric event grid (DayGrid).
///
/// P1 C1: the grid is handed a plain [tiles] list instead of a `PeekDay`,
/// so the same widget serves the forecast peek day AND (step 1.5) the
/// Daily-view toggle. Callers adapt:
///   - `DayCast` passes `peekDay.subEvents`,
///   - the daily page passes its filtered schedule list.

/// P2 (step 2.1): the resolved start time + default duration for a tap-to-add.
class DayGridTapSeed {
  /// The seeded tile start time (snapped + clamped to the day; "now" when the
  /// tap resolved into the past — C14).
  final DateTime start;

  /// C13: the tap-to-add default duration (the user adjusts it in `AddTile`).
  final Duration duration;

  /// C14: true when the tapped time was in the past and [start] was prefilled
  /// with "now" instead.
  final bool prefilledFromNow;

  const DayGridTapSeed({
    required this.start,
    required this.duration,
    this.prefilledFromNow = false,
  });
}

class DayGridWidget extends StatefulWidget {
  /// The tiles to render. Never mutated by the grid.
  final List<SubCalendarEvent> tiles;

  /// Called with the tapped tile (named arg `tilerEvent`) on tile tap,
  /// matching the previous `DayCast` hook.
  final Function? onTileTap;

  /// P1 (step 1.4): the zoom source. When omitted the grid owns a default
  /// [DayGridController] (80 px/h, matching the historical constant).
  final DayGridController? controller;

  /// C10 (step 1.6): the clock feeding the now-line. When omitted a live
  /// [DateTime.now()] clock is used and advanced by a minute timer.
  /// Inject a fixed value in tests (the timer stays off).
  final DateTime? now;

  /// P2 (step 2.1): the calendar day this grid renders, used to seed the start
  /// time of a tile created by tapping an empty region (tap-to-add). When
  /// supplied, a background tap target opens `AddTile` with the tapped
  /// (snapped) time. When omitted (e.g. the forecast peek day) the grid stays
  /// read-only and no tap-to-add target is offered.
  final DateTime? day;

  /// P2 (step 2.2): an optional identity prefix for the per-tile `ValueKey`s.
  /// Prefixing the tile key with the day keeps element reuse scoped to one
  /// day, so a tile with the same `uniqueId` on a different day never "flies"
  /// into the new day's layout. When omitted the key is the bare `uniqueId`.
  final String? dayKey;

  const DayGridWidget({
    super.key,
    this.tiles = const <SubCalendarEvent>[],
    this.onTileTap,
    this.controller,
    this.now,
    this.day,
    this.dayKey,
  });

  /// P2 (step 2.1): pure tap-to-add time math — the inverse of the layout
  /// mapping `time(y) = y / pxPerHour`, snapped and guarded. Kept separate
  /// from the widget so the y→time inversion, snap, clamp and guards are
  /// unit-testable without pumping the grid.
  ///
  /// [dy] is in day-content coordinates (0 at midnight of [dayStart]). The raw
  /// tapped hour is snapped DOWN to [snapInterval] (C4, shared with
  /// drag-and-drop) and clamped to the visible day. C14: a tap resolving before
  /// [now] prefills with [now] (AddTile's default) rather than the past. C13:
  /// the default duration is 1 hour.
  static DayGridTapSeed computeTapSeed({
    required DateTime dayStart,
    required double dy,
    required double pxPerHour,
    required Duration snapInterval,
    required DateTime now,
  }) {
    final clampedDy = dy.clamp(0.0, 24.0 * pxPerHour);
    final rawMs = clampedDy / pxPerHour * Duration.millisecondsPerHour;
    final snapMs = snapInterval.inMilliseconds;
    final snappedMs = (rawMs / snapMs).floor() * snapMs;
    var start = dayStart.add(Duration(milliseconds: snappedMs));
    final dayEnd = dayStart.add(const Duration(hours: 24));
    if (!start.isBefore(dayEnd)) {
      // Tap on/past the day's end: clamp to the last snap slot.
      start = dayStart.add(const Duration(hours: 24) - snapInterval);
    }
    final prefilled = start.isBefore(now);
    if (prefilled) {
      start = now;
    }
    return DayGridTapSeed(
      start: start,
      duration: const Duration(hours: 1),
      prefilledFromNow: prefilled,
    );
  }

  /// Step 2.3 (adaptive gutter): below this px/hour the 35px gutter is
  /// crowded, so hour *labels* thin out to every 2nd hour (the hour guide
  /// lines still render every hour).
  static const double gutterThinLabelThreshold = 64;

  /// Step 2.3: how many hour-rows to skip between gutter *labels*. Pure so it
  /// is unit-testable without pumping the grid. Returns 1 (every hour) at or
  /// above [gutterThinLabelThreshold] and 2 (every 2nd hour) below it.
  static int gutterLabelStride(double pxPerHour) {
    return pxPerHour < gutterThinLabelThreshold ? 2 : 1;
  }

  @override
  DayGridWidgetState createState() => DayGridWidgetState();
}

class DayGridWidgetState extends State<DayGridWidget> {
  ScrollController _scrollController = ScrollController();

  /// The zoom source. Either the caller's controller or a grid-owned
  /// default (disposed with the grid).
  late DayGridController _controller;
  DayGridController? _ownedController;

  /// Step 2.3 (pinch-to-zoom): px/hour captured at pinch start so updates
  /// multiply a stable base by the total pinch ratio (no compounding).
  double? _pinchStartPxPerHour;

  /// Step 2.3 (pinch-to-zoom): the day-hour at the viewport centre when a
  /// pinch began, kept pinned to the centre while zooming (anchor-zoom).
  double? _pinchHourAtCentre;

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

  /// C10 (step 1.6): the clock feeding the now-line. Live [DateTime.now()]
  /// when [DayGridWidget.now] is omitted; fixed when injected.
  late DateTime _liveNow;

  /// C10 (step 1.6): minute timer advancing [_liveNow]. Only runs when the
  /// caller did not inject a fixed clock; cancelled in dispose.
  Timer? _nowLineTimer;

  // P2 (step 2.2b): add/remove enter/exit bookkeeping.
  /// Tiles rendered in the previous frame, by uniqueId (the diff source).
  /// Updated in [build] so the next [didUpdateWidget] diffs against it.
  Map<String, SubCalendarEvent> _lastTilesById = <String, SubCalendarEvent>{};
  /// The [DayGridWidget.dayKey] the previous frame rendered; a change means
  /// the day swapped (fresh keys -> no cross-day ghost/enter cascade).
  String? _lastDayKey;
  /// Last known (left, width) per uniqueId, captured in build so a removed
  /// tile's fading-out ghost sits where it was.
  final Map<String, _TileLayout> _lastLayoutById = <String, _TileLayout>{};
  /// Removed tiles still fading out; dropped by [_removeTimer].
  final Map<String, _RemovingTile> _removingTiles = <String, _RemovingTile>{};
  /// Stagger delay per newly-added uniqueId (reset each diff).
  final Map<String, Duration> _enterDelays = <String, Duration>{};
  /// One-shot timer that drops the fading-out ghosts once the fade finishes.
  Timer? _removeTimer;

  double get _pxPerHour => _controller.pxPerHour;

  @override
  void initState() {
    super.initState();
    _ownedController = null;
    _controller = widget.controller ?? (_ownedController = DayGridController());
    _liveNow = widget.now ?? DateTime.now();
    if (widget.now == null) {
      _nowLineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _liveNow = DateTime.now();
        });
      });
    }
    if (_ownedController != null) {
      // C6: restore the last settled zoom for a grid-owned controller.
      // Externally-injected controllers are restored by their owner.
      _controller.restoreFromPrefs();
    }
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
    if (oldWidget.now != widget.now) {
      _liveNow = widget.now ?? _liveNow;
    }
    // P2 (step 2.2b): diff the tile set for add/remove enter/exit animations
    // (runs before build so the result is visible in the upcoming frame).
    _diffTiles(oldWidget, widget);
    if (identical(oldWidget.tiles, widget.tiles)) {
      return; // same instance: parent rebuilt with the same data.
    }
    // New data: a selection may now point at a tile that is gone, and the
    // initial scroll syncs to the first tile again (previous UX).
    _selectedEventIds.clear();
    _resyncInitialScroll();
  }

  /// P2 (step 2.2b): compare the current tile set with the previous frame
  /// (captured in [build]) to drive a staggered enter for added tiles and a
  /// fade-out ghost for removed ones. A day swap resets the bookkeeping so
  /// nothing animates across days (fresh keys, matching step 2.2).
  void _diffTiles(DayGridWidget oldWidget, DayGridWidget newWidget) {
    final String? newDayKey = newWidget.dayKey;
    final List<SubCalendarEvent> newTiles = newWidget.tiles;
    if (_lastDayKey != newDayKey) {
      // Day changed: fresh keys, no cross-day ghost or enter cascade.
      _removingTiles.clear();
      _enterDelays.clear();
      _lastDayKey = newDayKey;
      return;
    }
    final Set<String> prevIds = _lastTilesById.keys.toSet();
    final Set<String> curIds = newTiles.map((t) => t.uniqueId).toSet();

    // Added: staggered enter (~40ms each, capped ~400ms total, per §6.6).
    _enterDelays.clear();
    int i = 0;
    for (final t in newTiles) {
      if (!prevIds.contains(t.uniqueId)) {
        _enterDelays[t.uniqueId] =
            Duration(milliseconds: (i * 40).clamp(0, 400));
        i++;
      }
    }

    // Removed: fade-out ghost (idle only — while zooming/dragging the tiles
    // track the controller, so a fading ghost would fight the gesture).
    if (_controller.mode == DayGridMode.idle) {
      for (final id in prevIds) {
        if (!curIds.contains(id)) {
          final tile = _lastTilesById[id];
          if (tile == null) {
            continue;
          }
          final layout = _lastLayoutById[id];
          _removingTiles[id] = _RemovingTile(
            tile,
            layout?.left ?? 80.0,
            layout?.width ?? 270.0,
          );
        }
      }
    } else {
      _removingTiles.clear();
    }

    if (_removingTiles.isNotEmpty) {
      _removeTimer?.cancel();
      _removeTimer = Timer(const Duration(milliseconds: 220), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _removingTiles.clear();
        });
      });
    }
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

  /// P2 (step 2.1): tap-to-add. [details.localPosition] is in day-content
  /// coordinates (the detector sits inside the scroll content), so
  /// `dy / pxPerHour` is the tapped hour of the grid day. Only the daily view
  /// (which supplies [DayGridWidget.day]) offers tap-to-add; the forecast peek
  /// has no day and stays read-only. C14: taps while a pinch/drag is active are
  /// ignored.
  void _onEmptyGridTap(TapUpDetails details) {
    if (_controller.mode != DayGridMode.idle) {
      return; // C14: a pinch/drag owns the grid — don't start a tile.
    }
    final dayStart = widget.day;
    if (dayStart == null) {
      return; // no day supplied (e.g. DayCast) — read-only.
    }
    final seed = DayGridWidget.computeTapSeed(
      dayStart: dayStart,
      dy: details.localPosition.dy,
      pxPerHour: _pxPerHour,
      snapInterval: _controller.snapInterval,
      now: _liveNow,
    );
    final preTile = SimpleAdditionTile()
      ..startTime = seed.start
      ..duration = seed.duration;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AddTile(preTile: preTile)),
    );
  }

  // Step 2.3 (pinch-to-zoom): the two-finger scale claims the gesture arena
  // and drives the controller's pxPerHour. A single finger never satisfies the
  // scale recognizer, so vertical scroll, the horizontal day carousel, tile
  // taps and tap-to-add are left untouched.
  void _onScaleStart(ScaleStartDetails details) {
    if (_controller.mode == DayGridMode.zooming) {
      return; // guard against a re-entrant start.
    }
    _controller.mode = DayGridMode.zooming;
    final startPx = _controller.pxPerHour;
    _pinchStartPxPerHour = startPx;
    _pinchHourAtCentre = null;
    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      if (pos.hasContentDimensions) {
        // Anchor: remember the hour at the viewport centre so it stays put.
        _pinchHourAtCentre =
            (pos.pixels + pos.viewportDimension / 2.0) / startPx;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final startPx = _pinchStartPxPerHour;
    if (startPx == null || startPx <= 0) {
      return;
    }
    // Stable base * total ratio: no compounding on an already-mutated value.
    final newPx = startPx * details.scale;
    _controller.setPxPerHour(newPx);
    _anchorZoomToCentre(newPx);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_controller.mode != DayGridMode.zooming) {
      return;
    }
    _controller.mode = DayGridMode.idle;
    _pinchStartPxPerHour = null;
    _pinchHourAtCentre = null;
    // Settle to a clean step (clamped to the C8 range) and persist it
    // (C6: global across all days).
    final settled = DayGridController.settlePxPerHour(_controller.pxPerHour);
    _controller.setPxPerHour(settled);
    _persistSettledZoom();
  }

  /// Step 2.3 (anchor-zoom): keep the pinch-start centre hour pinned to the
  /// viewport centre as pxPerHour changes. `jumpTo` is safe here because the
  /// scale recognizer has already won the arena (the scroll physics are idle).
  void _anchorZoomToCentre(double pxPerHour) {
    final anchorHour = _pinchHourAtCentre;
    if (anchorHour == null || !_scrollController.hasClients) {
      return;
    }
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) {
      return;
    }
    final target = (anchorHour * pxPerHour - pos.viewportDimension / 2.0)
        .clamp(0.0, pos.maxScrollExtent);
    if ((target - pos.pixels).abs() > 0.5) {
      _scrollController.jumpTo(target);
    }
  }

  /// Step 2.3: best-effort persistence of the settled zoom.
  Future<void> _persistSettledZoom() async {
    try {
      await DayGridPreferences.setPxPerHour(_controller.pxPerHour);
    } catch (e) {
      Utility.debugPrint('DayGrid:: persist zoom failed: $e');
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

  /// C10 (step 1.6): pull-to-refresh — the same ScheduleBloc wiring as
  /// [EnhancedTileBatch]: dispatch `GetScheduleEvent(forceRefresh: true)`,
  /// carrying the current state's subEvents/timeline when it holds them.
  Future<void> _onGridRefresh() async {
    Utility.debugPrint('DayGrid:: pull-to-refresh -> '
        'GetScheduleEvent(forceRefresh: true)');
    await AnalysticsSignal.send('daygrid_pull_refresh');
    final scheduleBloc = context.read<ScheduleBloc>();
    final state = scheduleBloc.state;
    List<SubCalendarEvent>? subEvents;
    Timeline? timeline;
    if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
      timeline = state.lookupTimeline;
    } else if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
      timeline = state.lookupTimeline;
    } else if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
      timeline = state.previousLookupTimeline;
    }
    scheduleBloc.add(GetScheduleEvent(
      isAlreadyLoaded: true,
      previousSubEvents: subEvents,
      scheduleTimeline: timeline,
      previousTimeline: timeline,
      forceRefresh: true,
    ));
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

            // C10 (step 1.6): live now-line + gutter time bubble, today
            // only (the grid day is midnight of the earliest tile).
            final now = _liveNow;
            final isToday = dayStart != null &&
                dayStart.year == now.year &&
                dayStart.month == now.month &&
                dayStart.day == now.day;
            final nowLineTop =
                (now.hour + now.minute / 60.0 + now.second / 3600.0) *
                    pxPerHour;
            final nowLineMax = timeCellCount * pxPerHour;
            final nowLineColor = Theme.of(context).colorScheme.error;
            final nowLabel = TimeOfDay.fromDateTime(now).format(context);

            // Renderable tiles: id'd, inside the grid day, and not extended
            // (>=16h / all-day -> the pinned strip, step 1.7).
            final renderable = sortedTiles
                .where((t) => t.id.isNot_NullEmptyOrWhiteSpace())
                .where((t) => _renderableInTimeline(t, dayStart))
                .toList();

            // C11: overlap columns. Cluster the renderable tiles and give
            // each a shared-width column so overlapping tiles sit side by
            // side instead of stacking. A one-tile cluster keeps the full
            // [tileLeft, tileLeft + tileWidth] region (the pre-C11 single
            // tile geometry). Empty when tileWidth <= 0; the per-tile
            // fallback below then uses the full region.
            final columnLayout =
                OverlapColumns.assign<String, SubCalendarEvent>(
                  tiles: renderable,
                  keyOf: (t) => t.uniqueId,
                  left: tileLeft,
                  width: tileWidth,
                );

            // Z-order: the selected tile renders last (on top) — same
            // behaviour as before, without duplicating the widget.
            final unselected = renderable
                .where((t) => !_selectedEventIds.contains(t.id))
                .toList();
            final selected = renderable
                .where((t) => _selectedEventIds.contains(t.id))
                .toList();

            // 24-hour gutter: time labels + hour rows at pxPerHour.
            // Step 2.3 (adaptive): hour guide lines always render every hour;
            // hour *labels* thin out at low zoom so the 35px gutter stays
            // legible as the rows shrink.
            final labelStride = DayGridWidget.gutterLabelStride(pxPerHour);
            final gutterWidgets = <Widget>[];
            for (int hour = 0; hour < timeCellCount; hour++) {
              final timeOfDay = TimeOfDay(hour: hour, minute: 0);
              if (hour % labelStride == 0) {
                gutterWidgets.add(TimeOfDayTimeCellWidget(
                  start: timeOfDay,
                  height: pxPerHour,
                ));
              }
              gutterWidgets.add(TileTimeCellWidget(
                start: timeOfDay,
                left: gutter,
                height: pxPerHour,
              ));
            }

            // P2 (step 2.2): animate position deltas only while idle; during a
            // pinch/drag the tiles track the controller directly (no double
            // animation). Day-scope the per-tile keys so a tile's element never
            // carries across days.
            final animate = _controller.mode == DayGridMode.idle;
            final keyPrefix =
                (widget.dayKey == null || widget.dayKey!.isEmpty) ? '' : 'day_${widget.dayKey}_';

            final tileWidgets = [...unselected, ...selected]
                .map(
                  (tile) {
                    final column = columnLayout[tile.uniqueId];
                    return TileGridWidget(
                    // Stable per-tile identity: add/remove/replace of
                    // tiles maps to element remove/update — never a stale
                    // reused state.
                    key: ValueKey<String>('daygrid_tile_${keyPrefix}${tile.uniqueId}'),
                    tilerEvent: tile,
                    onTap: onTileGridTap,
                    pxPerHour: pxPerHour,
                    dayStart: dayStart,
                    left: column?.left ?? tileLeft,
                    tileGridWidth: column?.width ?? tileWidth,
                    animate: animate,
                    // P2 (step 2.2b): newly-added tiles slide in (staggered);
                    // existing/static tiles pass null (no enter animation).
                    enterDelay: _enterDelays[tile.uniqueId],
                    );
                  },
                )
                .toList();

            // P2 (step 2.2b): capture this frame's layout + tile set so the
            // next [didUpdateWidget] can diff for add/remove and place
            // fading-out ghosts at their last-known spot.
            _lastTilesById = {
              for (final t in renderable) t.uniqueId: t,
            };
            _lastLayoutById.clear();
            for (final t in renderable) {
              final column = columnLayout[t.uniqueId];
              _lastLayoutById[t.uniqueId] = _TileLayout(
                column?.left ?? tileLeft,
                column?.width ?? tileWidth,
              );
            }
            _lastDayKey = widget.dayKey;

            // P2 (step 2.2b): fading-out ghosts for removed tiles. Each is a
            // [TileGridWidget] pinned at its last-known spot, animated to
            // opacity 0, then dropped by [_removeTimer]. A distinct `exit`
            // key keeps it from colliding with a live tile of the same id.
            final ghostWidgets = _removingTiles.values
                .map(
                  (g) => TileGridWidget(
                    key: ValueKey<String>(
                        'daygrid_tile_exit_${g.tile.uniqueId}'),
                    tilerEvent: g.tile,
                    pxPerHour: pxPerHour,
                    dayStart: dayStart,
                    left: g.left,
                    tileGridWidth: g.width,
                    animate: animate,
                    exiting: true,
                  ),
                )
                .toList();

            if (_pendingScrollTo != null) {
              WidgetsBinding.instance.addPostFrameCallback(_applyPendingScroll);
            }

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.tertiary,
              onRefresh: _onGridRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Stack(
                  children: <Widget>[
                    // P2 (step 2.1): tap-to-add. A background tap target
                    // behind the tiles (first child => lowest z, so the
                    // positioned tiles on top win the hit test and keep their
                    // onTileTap behaviour). The handler no-ops unless a
                    // [day] is supplied, so the forecast peek (DayCast) stays
                    // read-only.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _onEmptyGridTap,
                      // Step 2.3 (pinch-to-zoom): the two-finger scale claims
                      // the gesture arena and drives the controller's
                      // pxPerHour. This detector already spans the whole grid
                      // (behind the tiles), so it is a full-area pinch target.
                      // A single finger never satisfies the scale recognizer,
                      // so vertical scroll, the horizontal day carousel, tile
                      // taps and tap-to-add behave exactly as before.
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      child: SizedBox(
                        width: double.infinity,
                        height: timeCellCount * pxPerHour,
                      ),
                    ),
                    ...gutterWidgets,
                    ...tileWidgets,
                    ...ghostWidgets,
                    if (isToday) ...<Widget>[
                      // 1-2px now-line across the day at the clock's y.
                      Positioned(
                        key: const Key('daygrid_now_line'),
                        top: nowLineTop.clamp(0.0, nowLineMax),
                        left: 0,
                        right: 0,
                        height: 2,
                        child: ColoredBox(color: nowLineColor),
                      ),
                      // Gutter time bubble.
                      Positioned(
                        key: const Key('daygrid_now_bubble'),
                        top: (nowLineTop - 10).clamp(0.0, nowLineMax - 20),
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: nowLineColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            nowLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nowLineTimer?.cancel(); // C10: no leaked minute timers
    _removeTimer?.cancel(); // P2 (2.2b): no leaked ghost-cleanup timers
    _ownedController?.dispose(); // own resources first (C1: dispose order)
    _scrollController.dispose();
    super.dispose();
  }
}

// P2 (step 2.2b): a removed tile's last-known geometry, for ghost placement.
class _TileLayout {
  final double left;
  final double width;
  _TileLayout(this.left, this.width);
}

// P2 (step 2.2b): a removed tile still fading out in the grid.
class _RemovingTile {
  final SubCalendarEvent tile;
  final double left;
  final double width;
  _RemovingTile(this.tile, this.left, this.width);
}
