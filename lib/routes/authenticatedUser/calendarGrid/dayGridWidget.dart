import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/overlapColumns.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/travelBandWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// Full-day parametric event grid (DayGrid).
///
/// The grid is handed a plain [tiles] list instead of a `PeekDay`,
/// so the same widget serves the forecast peek day AND the
/// Daily-view toggle. Callers adapt:
///   - `DayCast` passes `peekDay.subEvents`,
///   - the daily page passes its filtered schedule list.

/// `HH:mm:ss` format of a time for the `DayGrid::drag::` logs — accepts a
/// [DateTime] or an epoch-ms `int` (`--:--` when null).
String _dragLogTime(Object? t) {
  if (t == null) {
    return '--:--';
  }
  final dt = t is DateTime ? t : DateTime.fromMillisecondsSinceEpoch(t as int);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}

/// The resolved start time + default duration for a tap-to-add.
class DayGridTapSeed {
  /// The seeded tile start time (snapped + clamped to the day; "now" when the
  /// tap resolved into the past).
  final DateTime start;

  /// The tap-to-add default duration (the user adjusts it in `AddTile`).
  final Duration duration;

  /// True when the tapped time was in the past and [start] was prefilled
  /// with "now" instead.
  final bool prefilledFromNow;

  const DayGridTapSeed({
    required this.start,
    required this.duration,
    this.prefilledFromNow = false,
  });
}

/// The resolved drop target of a drag-and-drop reschedule — the
/// inverse of the layout mapping `time(y) = y / pxPerHour`, snapped
/// and constraint-checked. Kept separate from the widget so the
/// y→time inversion, snap, day clamp and range window are
/// unit-testable without pumping the grid.
class DayGridDragSeed {
  /// The snapped start of the dropped slot.
  final DateTime start;

  /// The new end (snapped start + the tile's original duration).
  final DateTime end;

  /// True when [start]/[end] fall inside the tile's allowed window
  /// (`rangeStart/rangeEnd`, falling back to
  /// `calendarEventStart/End`).
  final bool withinRange;

  /// Why the drop is blocked (`null` when [withinRange]).
  final String? blockReason;

  const DayGridDragSeed({
    required this.start,
    required this.end,
    required this.withinRange,
    this.blockReason,
  });
}

class DayGridWidget extends StatefulWidget {
  /// The tiles to render. Never mutated by the grid.
  final List<SubCalendarEvent> tiles;

  /// Called with the tapped tile (named arg `tilerEvent`) on tile tap,
  /// matching the previous `DayCast` hook.
  final Function? onTileTap;

  /// The zoom source. When omitted the grid owns a default
  /// [DayGridController] (80 px/h, matching the historical constant).
  final DayGridController? controller;

  /// The clock feeding the now-line. When omitted a live
  /// [DateTime.now()] clock is used and advanced by a minute timer.
  /// Inject a fixed value in tests (the timer stays off).
  final DateTime? now;

  /// The calendar day this grid renders, used to seed the start
  /// time of a tile created by tapping an empty region (tap-to-add). When
  /// supplied, a background tap target opens `AddTile` with the tapped
  /// (snapped) time. When omitted (e.g. the forecast peek day) the grid stays
  /// read-only and no tap-to-add target is offered.
  final DateTime? day;

  /// An optional identity prefix for the per-tile `ValueKey`s.
  /// Prefixing the tile key with the day keeps element reuse scoped to one
  /// day, so a tile with the same `uniqueId` on a different day never "flies"
  /// into the new day's layout. When omitted the key is the bare `uniqueId`.
  final String? dayKey;

  /// Read-only TileCast (vibe-chat preview) mode,
  /// mirroring `EnhancedTileBatch.preview`. In preview mode the grid does NOT
  /// offer tap-to-add, does NOT dispatch pull-to-refresh to
  /// [ScheduleBloc] (the preview tiles belong to `VibeChatBloc`), and a
  /// settled pinch does NOT persist to [DayGridPreferences] — the preview
  /// pinch must not overwrite the user's saved zoom. Zoom itself stays
  /// enabled (shared global pxPerHour). Drag-and-drop is likewise gated
  /// on this flag.
  final bool preview;

  /// The TileCast action currently highlighted in the
  /// carousel. The matching tile ([SubCalendarEvent.id] `contains` the
  /// entity id — the same rule as `_tileForAction` /
  /// `EnhancedTileCard.hasDottedBorder`) renders with the dotted-border
  /// treatment, is raised to top-z in its overlap cluster, and the grid
  /// auto-scrolls it into view (~0.15 alignment, matching the list's
  /// `jumpTo`). Carousel page swipes change only this id; the grid animates
  /// the highlight + scroll between actions instead of remounting.
  final String? selectedActionEntityId;

  /// Injectable sub-event persistence API — the drag commit path calls
  /// [SubCalendarEventApi.updateSubEvent]. When omitted a live API is
  /// created lazily on first commit.
  final SubCalendarEventApi? subCalendarEventApi;

  /// The px of the scroll viewport's bottom that sit behind a bottom
  /// navigation bar (and the system home-indicator inset) — used to park
  /// the bottom drag auto-scroll zone against the *visible* bottom edge
  /// rather than the raw viewport bottom. When omitted the grid
  /// auto-detects it from the enclosing [Scaffold] (a bottom bar is only
  /// counted when the body extends behind it via `extendBody`); a
  /// non-null value pins the clearance (used by tests).
  final double? edgeScrollBottomClearance;

  /// Optional chrome laid out ABOVE the 24h grid in the same scroll view,
  /// in NEGATIVE scroll extent (C18). The grid Stack is the scroll view's
  /// `center` sliver, so `pixels == 0` is always the top of the grid: the
  /// header lives in `[minScrollExtent, 0)` and is revealed only by the
  /// user pulling down. A header height change moves `minScrollExtent`,
  /// never the grid -- none of the scroll/time math below knows the header
  /// exists.
  final Widget? header;

  /// Reports how much of [header] is revealed, `0` (fully above the
  /// viewport) to `1` (fully visible, `pixels == minScrollExtent`). Fires
  /// only on change. Drives the top bar's cross-fade.
  final ValueChanged<double>? onHeaderRevealChanged;

  const DayGridWidget({
    super.key,
    this.tiles = const <SubCalendarEvent>[],
    this.onTileTap,
    this.controller,
    this.now,
    this.day,
    this.dayKey,
    this.preview = false,
    this.selectedActionEntityId,
    this.subCalendarEventApi,
    this.edgeScrollBottomClearance,
    this.header,
    this.onHeaderRevealChanged,
  });

  /// Pure: header reveal progress for a scroll [pixels] given
  /// [minScrollExtent] (<= 0): `0` at `pixels >= 0`, `1` at
  /// `pixels == minScrollExtent`; always `0` when there is no header.
  static double headerRevealProgress(double pixels, double minScrollExtent) {
    if (minScrollExtent >= 0) return 0.0;
    return (pixels / minScrollExtent).clamp(0.0, 1.0);
  }

  /// The top/bottom edge zones (px inside the scroll viewport) that
  /// trigger the drag edge auto-scroll.
  static const double edgeScrollZonePx = 48.0;

  /// Pure bottom-edge auto-scroll math: the viewport-space y that starts
  /// the bottom auto-scroll zone. The zone is [edgeScrollZonePx] tall and
  /// hugs the *visible* bottom of the scroll viewport — [viewportHeight]
  /// minus [bottomOcclusion] (the px of the viewport that sit behind a
  /// bottom navigation bar + the system home-indicator inset). When the
  /// body does not extend behind a bottom bar, [bottomOcclusion] is 0 and
  /// the zone hugs the raw viewport bottom (the historical behaviour).
  /// Kept pure so the clearance/occlusion math is unit-testable without
  /// pumping the grid. Returns a value in `0..viewportHeight`.
  static double bottomZoneStartY(
    double viewportHeight, {
    required double bottomOcclusion,
  }) {
    if (viewportHeight <= 0) {
      return 0.0;
    }
    final occlusion = bottomOcclusion.clamp(0.0, viewportHeight);
    final effectiveBottom = viewportHeight - occlusion;
    return (effectiveBottom - edgeScrollZonePx).clamp(0.0, viewportHeight);
  }

  /// A tile matches the highlighted TileCast action
  /// when its id contains the action's entity id — the same rule as
  /// `EnhancedTileBatch._tileForAction` /
  /// `EnhancedTileCard.hasDottedBorder` (`tile.id?.contains(entityId) ==
  /// true`). Kept pure so the matching rule is unit-testable and a drift
  /// from the list rule is detectable (highlight-miss funnel).
  static bool tileMatchesAction(
          SubCalendarEvent tile, String? selectedActionEntityId) =>
      selectedActionEntityId != null &&
      tile.id?.contains(selectedActionEntityId) == true;

  /// Pure tap-to-add time math — the inverse of the layout
  /// mapping `time(y) = y / pxPerHour`, snapped and guarded. Kept separate
  /// from the widget so the y→time inversion, snap, clamp and guards are
  /// unit-testable without pumping the grid.
  ///
  /// [dy] is in day-content coordinates (0 at midnight of [dayStart]). The raw
  /// tapped hour is snapped DOWN to [snapInterval] (shared with
  /// drag-and-drop) and clamped to the visible day. A tap resolving before
  /// [now] prefills with [now] (AddTile's default) rather than the past.
  /// The default duration is 1 hour.
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

  /// [dropTopPx] is the tile's top in day-content coordinates (0 at
  /// midnight of [dayStart]), snapped DOWN to [snapInterval] (shared
  /// with tap-to-add) and clamped so the whole tile stays inside the
  /// visible day. The duration is preserved. The result is validated
  /// against the tile's allowed window — a violation is reported,
  /// never silently clamped.
  static DayGridDragSeed computeDragSeed({
    required SubCalendarEvent tile,
    required DateTime dayStart,
    required double dropTopPx,
    required double pxPerHour,
    required Duration snapInterval,
  }) {
    assert(pxPerHour.isFinite && pxPerHour > 0,
        'DayGrid:: invalid pxPerHour $pxPerHour');
    final dayStartMs = dayStart.millisecondsSinceEpoch;
    final dayEndMs = dayStartMs + Duration.millisecondsPerDay;
    final durationMs = tile.duration.inMilliseconds;

    final clampedDy = dropTopPx.clamp(0.0, 24.0 * pxPerHour);
    final rawMs = clampedDy / pxPerHour * Duration.millisecondsPerHour;
    final snapMs = snapInterval.inMilliseconds;
    final snappedMs = (rawMs / snapMs).floor() * snapMs;
    var startMs = dayStartMs + snappedMs;
    // Keep the whole tile inside the visible day (no partial tiles).
    if (startMs + durationMs > dayEndMs) {
      startMs = dayEndMs - durationMs;
    }
    if (startMs < dayStartMs) {
      startMs = dayStartMs;
    }
    final endMs = startMs + durationMs;

    // The allowed window. A usable *range* window needs both bounds with a
    // positive span (rangeEnd > rangeStart). Real data frequently carries
    // rangeStart == rangeEnd — the parent event's anchor instant, not a span
    // (see the biggerJson fixtures, where rangeStart == rangeEnd == the
    // parent's calendarEventStart and calendarEventEnd spans days) — so a
    // degenerate range must NOT block the drop. When the range window is
    // unusable (absent, single-instant, or inverted), fall back to the
    // parent calendar event's slot (calendarEventStart/End), the real
    // scheduling window; if that is also unusable the tile is unbounded
    // (the drop is still clamped to the visible day above).
    final rangeUsable = tile.rangeStart != null &&
        tile.rangeEnd != null &&
        tile.rangeEnd! > tile.rangeStart!;
    final double? windowStart =
        rangeUsable ? tile.rangeStart : tile.calendarEventStart;
    final double? windowEnd =
        rangeUsable ? tile.rangeEnd : tile.calendarEventEnd;
    final bool within;
    if (windowStart == null || windowEnd == null) {
      // No usable window at all → unbounded (clamped to the visible day).
      within = true;
    } else if (windowEnd <= windowStart) {
      // Degenerate (single-instant) or inverted window → unbounded.
      within = true;
    } else {
      within = startMs >= windowStart && endMs <= windowEnd;
    }

    return DayGridDragSeed(
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: DateTime.fromMillisecondsSinceEpoch(endMs),
      withinRange: within,
      blockReason: within ? null : 'out_of_range',
    );
  }

  /// Adaptive gutter: below this px/hour the 35px gutter is
  /// crowded, so hour *labels* thin out to every 2nd hour (the hour guide
  /// lines still render every hour).
  static const double gutterThinLabelThreshold = 64;

  /// How many hour-rows to skip between gutter *labels*. Pure so it
  /// is unit-testable without pumping the grid. Returns 1 (every hour) at or
  /// above [gutterThinLabelThreshold] and 2 (every 2nd hour) below it.
  static int gutterLabelStride(double pxPerHour) {
    return pxPerHour < gutterThinLabelThreshold ? 2 : 1;
  }

  /// Adaptive gutter lines: below the thin threshold the 35px gutter
  /// rows are < 64px tall, so a line every hour reads as a solid band —
  /// the hour *guide lines* thin to every 2nd hour, mirroring the label
  /// stride. Same threshold, same 1/2 result as [gutterLabelStride]; kept
  /// as its own function so the two can diverge if the visuals do.
  static int gutterLineStride(double pxPerHour) {
    return pxPerHour < gutterThinLabelThreshold ? 2 : 1;
  }

  /// At/above [gutterFineTickThreshold] (the fine-snap boundary of
  /// 160 px/h) sub-hour ticks become legible at 15
  /// minutes; between the thresholds they render at 30 minutes; below the
  /// thin threshold there is no room for sub-hour ticks (null).
  static const double gutterFineTickThreshold = 160;

  static int? gutterTickIntervalMinutes(double pxPerHour) {
    if (pxPerHour < gutterThinLabelThreshold) {
      return null;
    }
    return pxPerHour >= gutterFineTickThreshold ? 15 : 30;
  }

  @override
  DayGridWidgetState createState() => DayGridWidgetState();
}

class DayGridWidgetState extends State<DayGridWidget> {
  /// Created in [initState] with `initialScrollOffset` = the initial
  /// auto-scroll target, so a freshly mounted grid (a carousel day page
  /// sliding into view) PAINTS its first frame already at the first tile
  /// hour instead of at 12 AM and then jumping post-frame.
  late final ScrollController _scrollController;

  /// The `center` sliver of the scroll host -- the 24h grid Stack. Anchors
  /// `pixels == 0` at the grid top regardless of any [DayGridWidget.header].
  final GlobalKey _gridCenterKey = GlobalKey(debugLabel: 'daygrid_center');

  /// Last reported header reveal progress (dedupes the callback).
  double _lastHeaderReveal = 0.0;

  /// The zoom source. Either the caller's controller or a grid-owned
  /// default (disposed with the grid).
  late DayGridController _controller;
  DayGridController? _ownedController;

  /// Pinch-to-zoom: px/hour captured at pinch start so updates
  /// multiply a stable base by the total pinch ratio (no compounding).
  double? _pinchStartPxPerHour;

  /// Pinch-to-zoom: the day-hour at the viewport centre when a
  /// pinch began, kept pinned to the centre while zooming (anchor-zoom).
  double? _pinchHourAtCentre;

  /// 24 hour rows make up the day.
  static const int timeCellCount = 24;

  /// Fallback initial scroll position (hours) when the day has no tiles —
  /// keeps the previous 8am "active hour" behaviour.
  static const int defaultScrollHour = 8;

  /// Tiles of at least this length belong to the pinned strip,
  /// not the timeline (matches `Utility.activeDayDuration`).
  static const Duration extendedTileDuration = Duration(hours: 16);

  /// One-shot pending scroll target (px), applied clamped after the next
  /// frame. `null` when no initial sync is queued.
  double? _pendingScrollTo;

  /// Tapped tile ids. Selection only changes z-order (the selected tile
  /// draws on top); it never duplicates tile widgets.
  final Set<String> _selectedEventIds = <String>{};

  /// The clock feeding the now-line. Live [DateTime.now()]
  /// when [DayGridWidget.now] is omitted; fixed when injected.
  late DateTime _liveNow;

  /// Minute timer advancing [_liveNow]. Only runs when the
  /// caller did not inject a fixed clock; cancelled in dispose.
  Timer? _nowLineTimer;

  // Add/remove enter/exit bookkeeping.
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

  // TileCast preview bookkeeping.
  /// One-shot target px for the highlight auto-scroll (align the
  /// selected tile's top ~15% into the viewport, mirroring the list's
  /// `jumpTo(alignment: 0.15)`). `null` when no highlight scroll is queued.
  double? _pendingPreviewScroll;

  // Drag-and-drop reschedule bookkeeping.
  /// The tile being lifted by a long-press drag; `null` when idle.
  SubCalendarEvent? _dragTile;

  /// The dragged tile's original top (day-content px).
  double _dragOriginalTopPx = 0;

  /// The finger's content-space y when the long press began — the
  /// baseline for the drag delta.
  double _dragStartContentY = 0;

  /// The scroll offset when the drag lifted. Pointer MOVE events are
  /// routed through the hit-test transform captured at pointer DOWN, so
  /// the tile-local positions the drag callbacks report stay relative to
  /// where the tile was at lift time — they do NOT follow the content as
  /// the edge auto-scroll moves it under the finger. Every conversion of
  /// a tile-local dy to content/viewport space adds `pixels - this`.
  double _dragStartPixels = 0;

  /// The resolved drop slot (snapped + range-checked) the ghost is
  /// resting on (`null` while idle).
  DayGridDragSeed? _dragTargetStart;

  /// Periodic timer driving the edge auto-scroll while a drag is
  /// active; `null` when the finger is outside the edge zones (or idle).
  Timer? _edgeScrollTimer;

  /// The finger's viewport-space y (px from the top of the scroll
  /// viewport: day-content y - scroll offset) while a drag is active —
  /// the edge-zone input for the auto-scroll; `null` while idle.
  double? _dragFingerViewportY;

  /// Cached bottom-bar occlusion (px of the scroll viewport's bottom that
  /// sit behind a bottom navigation + the home-indicator inset).
  /// Recomputed in [didChangeDependencies] so it tracks MediaQuery inset
  /// changes; `null` until first computed.
  double? _edgeScrollBottomClearanceCache;

  /// The top/bottom edge zones (px inside the scroll viewport) that
  /// trigger the drag edge auto-scroll. Single source of truth lives on
  /// [DayGridWidget.edgeScrollZonePx] (aliased here for the existing call
  /// sites).
  static const double _edgeScrollZonePx = DayGridWidget.edgeScrollZonePx;

  /// The auto-scroll tick cadence (~display refresh; each tick moves the
  /// grid toward the finger by its edge-zone depth).
  static const Duration _edgeScrollTickInterval = Duration(milliseconds: 16);

  /// The in-flight settle move — the dragged tile holds the dropped
  /// slot (optimistically) until the parent re-serves data with a
  /// changed time for the tile, or a rollback fires.
  _SettlingMove? _settlingMove;

  /// `true` while a long-press drag gesture owns a finger. Together
  /// with [_settlingMove] it is the in-flight/duplicate-drop guard:
  /// a second drop issued while either is active is ignored (no
  /// double-write race).
  bool _dragging = false;

  /// The uniqueId of the tile the save badge belongs to; `null` when no
  /// drag commit has a save state. The badge overlays this tile only.
  String? _savingTileId;

  /// The drag-to-reschedule persistence outcome shown on [_savingTileId]'s
  /// tile: `saving` while the `updateSubEvent` request is in flight
  /// (driven by the field, cleared when the request settles — never leaves
  /// an active spinner at teardown), `saved`/`error` linger until the next
  /// drag lift/commit resets the state (no timer, mirroring the app's
  /// existing save-state behaviour).
  TileSaveStatus _saveStatus = TileSaveStatus.idle;

  /// The dragged tile's column (left, width) at lift — the ghost's
  /// horizontal geometry (re-derived per build for the ghost's left).
  double _dragGhostLeft = 0;
  double _dragGhostWidth = 270;

  /// True while an ordinary tap that was cancelled by a failed drag
  /// attempt must be swallowed (the long-press detector eats the tap
  /// only for recognizers it started; a cancelled long press would
  /// otherwise still fire the tile's `onTap`).
  bool _dragSuppressTap = false;

  /// The last snapped drop start (haptic tick when it changes).
  DateTime? _lastDragSnapStart;

  /// Lazily created persistence API (the injected one wins).
  SubCalendarEventApi? _subCalendarEventApi;

  double get _pxPerHour => _controller.pxPerHour;

  @override
  void initState() {
    super.initState();
    _ownedController = null;
    _controller = widget.controller ?? (_ownedController = DayGridController());
    // First frame lands on the initial target (no post-frame jump). The
    // position clamps it to the content once laid out; a later
    // `_applyPendingScroll` is then a no-op unless the target moved.
    _scrollController =
        ScrollController(initialScrollOffset: _initialScrollTarget());
    _scrollController.addListener(_onScrollChanged);
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
      // Restore the last settled zoom for a grid-owned controller.
      // Externally-injected controllers are restored by their owner.
      _controller.restoreFromPrefs();
    }
    if (widget.preview) {
      // One-shot TileCast grid funnel (initState runs once
      // per grid mount, so this fires exactly once per preview session).
      AnalysticsSignal.send('daygrid_tilecast_shown',
          additionalInfo: {'actionCount': widget.tiles.length});
    }
    _resyncInitialScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh the bottom-bar occlusion when the MediaQuery insets (or the
    // enclosing Scaffold's bottom bar) change, so the bottom auto-scroll
    // zone tracks the visible bottom edge.
    _edgeScrollBottomClearanceCache = _computeEdgeScrollBottomClearance();
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
    // A TileCast carousel page swipe changes ONLY the
    // selected action — the grid animates the highlight + auto-scroll into
    // view (stable tile keys, no remount) instead of re-syncing the initial
    // scroll. The *change* (old != new) is what drives it; the initial
    // presence is not (that's the initial sync's job).
    if (oldWidget.selectedActionEntityId != widget.selectedActionEntityId) {
      _onSelectedActionChanged();
    }
    // Diff the tile set for add/remove enter/exit animations
    // (runs before build so the result is visible in the upcoming frame).
    _diffTiles(oldWidget, widget);
    // Reconcile the in-flight settle override with the new tile set
    // (the server confirmation/rollback clears it).
    _syncSettlingMove(widget.tiles);
    if (identical(oldWidget.tiles, widget.tiles)) {
      return; // same instance: parent rebuilt with the same data.
    }
    // New data: a selection may now point at a tile that is gone.
    _selectedEventIds.clear();
    // Re-sync the initial scroll ONLY when the data is structurally new:
    // a day swap (different dayKey → fresh grid for a new day) or the first
    // tiles arriving on an empty grid (initial data load). Post-commit tile
    // refreshes (same day, same element) must NOT jump the scroll — the
    // user's position is preserved so a drag-commit or pull-to-refresh
    // loading cycle does not snap the grid back to the top.
    final bool dayChanged = oldWidget.dayKey != widget.dayKey;
    final bool wasEmpty = oldWidget.tiles.isEmpty;
    if (dayChanged || wasEmpty) {
      _resyncInitialScroll();
    } else {
      // Scroll-preservation evidence: the re-served tile set did NOT
      // jump the grid (grep `DayGrid::scroll::keep`).
      Utility.debugPrint(
          'DayGrid::scroll::keep pixels=${_scrollController.hasClients ? _scrollController.position.pixels.toStringAsFixed(1) : 'n/a'} '
          '(tile refresh — no initial scroll resync)');
    }
  }

  /// Compare the current tile set with the previous frame
  /// (captured in [build]) to drive a staggered enter for added tiles and a
  /// fade-out ghost for removed ones. A day swap resets the bookkeeping so
  /// nothing animates across days (fresh keys).
  void _diffTiles(DayGridWidget oldWidget, DayGridWidget newWidget) {
    final String? newDayKey = newWidget.dayKey;
    final List<SubCalendarEvent> newTiles = newWidget.tiles;
    if (_lastDayKey != newDayKey) {
      // Day changed: fresh keys, no cross-day ghost or enter cascade.
      _removingTiles.clear();
      _enterDelays.clear();
      _dragTile = null; // a drag can never span a day swap.
      _lastDayKey = newDayKey;
      return;
    }
    final Set<String> prevIds = _lastTilesById.keys.toSet();
    final Set<String> curIds = newTiles.map((t) => t.uniqueId).toSet();

    // Added: staggered enter (~40ms each, capped ~400ms total).
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

  /// The initial auto-scroll target: the first tile's start hour (or
  /// [defaultScrollHour] on an empty day) at the current zoom.
  double _initialScrollTarget() {
    final firstHour = _firstTileStartHour();
    return _pxPerHour * (firstHour ?? defaultScrollHour);
  }

  /// Queue an initial scroll to the first tile's start hour.
  void _resyncInitialScroll() {
    _pendingScrollTo = _initialScrollTarget();
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

  /// The highlighted TileCast action changed (a
  /// carousel page swipe). Queue an auto-scroll that aligns the new tile's
  /// top ~15% into the viewport (mirroring `EnhancedTileBatch`'s preview
  /// `jumpTo(alignment: 0.15)`). The dotted border + top-z raise happen in
  /// [build] off [DayGridWidget.selectedActionEntityId]; the tile's element
  /// (stable key) is reused, so nothing remounts.
  void _onSelectedActionChanged() {
    final entityId = widget.selectedActionEntityId;
    if (entityId == null) {
      return;
    }
    final gridDay = _gridDayStart();
    SubCalendarEvent? match;
    for (final tile in widget.tiles) {
      if (tile.id == null ||
          !tile.id!.isNotEmpty ||
          !DayGridWidget.tileMatchesAction(tile, entityId)) {
        continue;
      }
      match = tile;
      break;
    }
    if (match == null) {
      // Silent-highlight-miss funnel: the id-matching rule drifted from the
      // list's `_tileForAction` (or the preview schedule changed under the
      // carousel) — the carousel highlights nothing in the grid.
      if (constant.isDebug) {
        Utility.debugPrint('DayGrid:: highlight miss: no tile for entity '
            '"$entityId"');
      }
      AnalysticsSignal.send('daygrid_error', additionalInfo: {
        'reason': 'tilecast_highlight_miss',
        'entityId': entityId
      });
      return;
    }
    final pxPerHour = _pxPerHour;
    // A matching tile implies a non-empty tile set, so [_gridDayStart] has a
    // day; the `??` only satisfies the nullable type.
    final dayStartMs = gridDay?.millisecondsSinceEpoch ?? match.start!;
    final clampedStart = match.start! < dayStartMs ? dayStartMs : match.start!;
    final top = ((clampedStart - dayStartMs) / Duration.millisecondsPerHour) *
        pxPerHour;
    _pendingPreviewScroll = top * 0.15;
  }

  /// Apply the queued highlight auto-scroll after the
  /// frame (the position exists only once the content is laid out). Animated
  /// while `mode == idle` unless reduced-motion, which jump-cuts.
  void _applyPreviewScroll(Duration _) {
    final target = _pendingPreviewScroll;
    _pendingPreviewScroll = null;
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
    // Clamp — animateTo asserts on out-of-range targets in debug.
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() < 0.5) {
      return;
    }
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_controller.mode != DayGridMode.idle || reduce) {
      _scrollController.jumpTo(clamped);
    } else {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
    Utility.debugPrint('DayGrid:: highlight scroll -> '
        '${clamped.toStringAsFixed(1)}px');
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

  /// Exclusions: extended (>=16h / all-day) tiles belong to the
  /// pinned strip, and tiles fully outside the grid day have no
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

  /// Time-sorted copy — never sorts [DayGridWidget.tiles] in place.
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

  /// Tap-to-add. [details.localPosition] is in day-content
  /// coordinates (the detector sits inside the scroll content), so
  /// `dy / pxPerHour` is the tapped hour of the grid day. Only the daily view
  /// (which supplies [DayGridWidget.day]) offers tap-to-add; the forecast peek
  /// has no day and stays read-only. Taps while a pinch/drag is active are
  /// ignored.
  void _onEmptyGridTap(TapUpDetails details) {
    if (widget.preview) {
      return; // Preview is read-only — no tap-to-add.
    }
    if (_controller.mode != DayGridMode.idle) {
      return; // A pinch/drag owns the grid — don't start a tile.
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

  // Pinch-to-zoom: the two-finger scale claims the gesture arena
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
    // Anchor on the CLAMPED zoom. Past the min/max the controller stops
    // changing, so the anchor must stop too — anchoring on the raw
    // `newPx` kept re-deriving the scroll target from a zoom that was not
    // being applied, turning an over-pinch into a scroll.
    _anchorZoomToCentre(_controller.pxPerHour);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_controller.mode != DayGridMode.zooming) {
      return;
    }
    _controller.mode = DayGridMode.idle;
    _pinchStartPxPerHour = null;
    _pinchHourAtCentre = null;
    // Settle to a clean step (clamped to the valid range) and persist it
    // (global across all days).
    final settled = DayGridController.settlePxPerHour(_controller.pxPerHour);
    _controller.setPxPerHour(settled);
    if (widget.preview) {
      // The preview pinch must not overwrite the user's
      // saved zoom — the shared pxPerHour applies for the session, but
      // persistence is skipped.
      return;
    }
    _persistSettledZoom();
  }

  /// Anchor-zoom: keep the pinch-start centre hour pinned to the
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

  /// Best-effort persistence of the settled zoom.
  Future<void> _persistSettledZoom() async {
    try {
      await DayGridPreferences.setPxPerHour(_controller.pxPerHour);
    } catch (e) {
      Utility.debugPrint('DayGrid:: persist zoom failed: $e');
    }
  }

  // -------------------------------------------------------------------
  // Drag-and-drop reschedule (long-press lift → snapped ghost → drop).
  //
  // The gesture lives on the tile itself (see [TileGridWidget]'s
  // long-press-drag detector) so a quick vertical drag still loses the
  // arena to the grid's scroll view and scrolls normally. A long press
  // lifts ONLY Tiler-owned, non-what-if tiles of the live grid (the
  // preview stays read-only, and third-party tiles are not resizable).
  // -------------------------------------------------------------------

  /// Long-press lift: the tile becomes the drag target and the ghost
  /// appears on the tile's current slot (the lift point is the seed, so
  /// no move has happened yet).
  void _onTileLongPressStart(
      SubCalendarEvent tile, Offset localOffset, double left, double width) {
    if (widget.preview ||
        _controller.mode != DayGridMode.idle ||
        _dragging ||
        !_renderableInTimeline(tile, _gridDayStart()) ||
        tile.isWhatIf == true ||
        !tile.isFromTiler) {
      return; // read-only surfaces and non-Tiler tiles never lift.
    }
    _dragging = true;
    _controller.mode = DayGridMode.dragging;
    _dragTile = tile;
    _dragSuppressTap = true; // swallow the tap this long press cancels.
    _lastDragSnapStart = null;
    _clearSaveState(); // a new lift resets the previous commit's badge.
    final dayStart = _gridDayStart()!;
    _dragOriginalTopPx = _topPx(dayStart: dayStart, startMs: tile.start!);
    _dragStartContentY = localOffset.dy;
    _dragStartPixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0;
    _dragGhostLeft = left;
    _dragGhostWidth = width;
    // The finger is still at the lift point: pass the recorded lift
    // offset (the detector-local baseline) so the drag delta starts
    // at zero and the ghost sits on the tile's current slot.
    _dragTargetStart = _dragSeedForOffset(_dragStartContentY);
    _syncDragState();
    Utility.debugPrint('DayGrid::drag::lift ${tile.uniqueId}: '
        'start=${_dragLogTime(tile.start)} end=${_dragLogTime(tile.end)} '
        'duration=${tile.duration.inMinutes}m '
        'topPx=${_dragOriginalTopPx.toStringAsFixed(1)} '
        'seedStart=${_dragLogTime(_dragTargetStart?.start)}');
    // A lift that already sits inside an edge zone (a tile at the very
    // top/bottom of the viewport) arms the auto-scroll immediately.
    _syncEdgeScroll(_fingerViewportY(localOffset.dy));
  }

  /// Drag move: re-derive the snapped drop slot from the finger's
  /// content-space offset (the same y→time inversion as tap-to-add).
  void _onTileDragUpdate(Offset localPosition) {
    final tile = _dragTile;
    if (tile == null || _controller.mode != DayGridMode.dragging) {
      return;
    }
    // Tile-local dy → the tile's lift-time frame; add the scroll delta so
    // the slot tracks the finger's TRUE content point after an auto-scroll.
    _dragTargetStart =
        _dragSeedForOffset(localPosition.dy + _scrollDeltaSinceLift());
    final snapped = _dragTargetStart;
    if (snapped != null &&
        !snapped.start.isAtSameMomentAs(
            _lastDragSnapStart ?? DateTime.fromMillisecondsSinceEpoch(-1))) {
      _lastDragSnapStart = snapped.start;
      HapticFeedback.lightImpact(); // snap tick.
    }
    _syncDragState();
    // Re-arm (or stop) the edge auto-scroll from the finger's
    // viewport-space point.
    _syncEdgeScroll(_fingerViewportY(localPosition.dy));
  }

  /// Drop: commit an in-range move, or cancel (tile returns, nothing
  /// persisted) when the drop fell outside the tile's allowed window.
  void _onTileDragEnd(SubCalendarEvent tile) {
    if (_controller.mode != DayGridMode.dragging || _dragTile != tile) {
      _dragTile = null;
      _dragging = false;
      _controller.mode = DayGridMode.idle;
      _syncDragState();
      return;
    }
    _stopEdgeScroll(); // the drag no longer owns the finger.
    final seed = _dragTargetStart;
    final originalTopPx = _dragOriginalTopPx;
    final dayStart = _gridDayStart()!;
    _dragTile = null;
    _dragging = false;
    _lastDragSnapStart = null;
    if (seed != null && !seed.withinRange) {
      // Blocked: the tile never moves (no request, no event).
      Utility.debugPrint(
          'DayGrid::drag::blocked ${tile.uniqueId}: reason=${seed.blockReason}');
      _dragTargetStart = null;
      _controller.mode = DayGridMode.idle;
      _syncDragState();
      AnalysticsSignal.send('daygrid_drag_blocked', additionalInfo: {
        'tileId': tile.uniqueId,
        'reason': seed.blockReason
      });
      return;
    }
    if (seed == null ||
        _topPx(
                dayStart: dayStart,
                startMs: seed.start.millisecondsSinceEpoch) ==
            originalTopPx) {
      // Dropped back on (or at the lift offset of) its own slot —
      // a no-op move never issues a request.
      Utility.debugPrint(
          'DayGrid::drag::noop ${tile.uniqueId}: dropped on its own slot');
      _dragTargetStart = null;
      _controller.mode = DayGridMode.idle;
      _syncDragState();
      return;
    }
    Utility.debugPrint('DayGrid::drag::drop ${tile.uniqueId}: '
        'start=${_dragLogTime(seed.start)} end=${_dragLogTime(seed.end)} '
        'duration=${seed.end.difference(seed.start).inMinutes}m '
        'within=${seed.withinRange}');
    _commitDragMove(tile, seed);
  }

  /// The snapped drop slot for a finger offset [dy] in day-content px
  /// (the lift point is the baseline: `dy - _dragStartContentY` is the
  /// vertical drag delta applied to the tile's current top).
  DayGridDragSeed? _dragSeedForOffset(double dy) {
    final tile = _dragTile;
    final dayStart = _gridDayStart();
    if (tile == null || dayStart == null) {
      return null;
    }
    final dropTopPx = _dragOriginalTopPx + (dy - _dragStartContentY);
    final seed = DayGridWidget.computeDragSeed(
      tile: tile,
      dayStart: dayStart,
      dropTopPx: dropTopPx,
      pxPerHour: _pxPerHour,
      snapInterval: _controller.snapInterval,
    );
    return seed;
  }

  /// Viewport-space y (px from the top of the scroll viewport) of the
  /// finger dragging [_dragTile]. The tile's drag callbacks report
  /// positions LOCAL TO THE TILE (the detector's origin is the tile's
  /// top), so the tile's content top ([_dragOriginalTopPx], static while
  /// the drag owns the finger) plus the local y is the day-content y —
  /// minus the scroll offset, the viewport y. `null` when nothing is
  /// dragged or the grid has no attached scroll position.
  double? _fingerViewportY(double localDy) {
    final tile = _dragTile;
    if (tile == null || !_scrollController.hasClients) {
      return null;
    }
    // localDy is relative to the tile's LIFT-TIME position (see
    // [_dragStartPixels]): content y = originalTop + localDy + scroll delta;
    // viewport y = content y - pixels = originalTop + localDy - liftPixels.
    return _dragOriginalTopPx + localDy - _dragStartPixels;
  }

  /// How far the grid has scrolled since the drag lifted.
  double _scrollDeltaSinceLift() {
    if (!_scrollController.hasClients) return 0;
    return _scrollController.position.pixels - _dragStartPixels;
  }

  /// The px of the scroll viewport's bottom that sit behind a bottom
  /// navigation bar + the system home-indicator inset (0 when the body
  /// does not extend behind a bottom bar). Pinned by
  /// [DayGridWidget.edgeScrollBottomClearance] when set; otherwise
  /// auto-detected from the enclosing [Scaffold].
  double _edgeScrollBottomClearance() {
    final cached = _edgeScrollBottomClearanceCache;
    if (cached != null) {
      return cached;
    }
    return _computeEdgeScrollBottomClearance();
  }

  double _computeEdgeScrollBottomClearance() {
    final override = widget.edgeScrollBottomClearance;
    if (override != null) {
      return override;
    }
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    final occluded = scaffold != null &&
        scaffold.extendBody &&
        scaffold.bottomNavigationBar != null;
    final navHeight = occluded ? kBottomNavigationBarHeight : 0.0;
    final bottomInset = MediaQuery.maybeOf(context)?.padding.bottom ?? 0.0;
    return navHeight + bottomInset;
  }

  /// The viewport-space y that starts the bottom auto-scroll zone for a
  /// scroll viewport of [viewportHeight] — the raw bottom pulled up by the
  /// detected bottom-bar occlusion (see [_edgeScrollBottomClearance]).
  double _bottomZoneStartY(double viewportHeight) {
    return DayGridWidget.bottomZoneStartY(
      viewportHeight,
      bottomOcclusion: _edgeScrollBottomClearance(),
    );
  }

  /// Re-arms (or stops) the edge auto-scroll for a finger at
  /// viewport-space y [viewportY]: inside the top zone the grid scrolls
  /// up, inside the bottom zone it scrolls down — toward the finger.
  void _syncEdgeScroll(double? viewportY) {
    _dragFingerViewportY = viewportY;
    // A finger ABOVE the viewport (over the fixed top bar) or BELOW it is
    // "deep in" that edge zone, not outside it — the step is capped anyway.
    final inEdge = viewportY != null &&
        _scrollController.hasClients &&
        (viewportY < _edgeScrollZonePx ||
            viewportY >
                _bottomZoneStartY(
                    _scrollController.position.viewportDimension));
    if (inEdge) {
      _edgeScrollTimer ??=
          Timer.periodic(_edgeScrollTickInterval, (_) => _edgeScrollStep());
    } else {
      _stopEdgeScroll();
    }
  }

  /// One auto-scroll tick: move the grid toward the finger by its
  /// edge-zone depth (a deeper finger scrolls faster; the step is capped
  /// by the zone so a tick never teleports the grid) and re-derive the
  /// drop slot from the finger's (now changed) content position — the
  /// ghost tracks the finger's viewport point as the grid moves.
  void _edgeScrollStep() {
    final viewportY = _dragFingerViewportY;
    if (!mounted || viewportY == null || !_scrollController.hasClients) {
      _stopEdgeScroll();
      return;
    }
    final position = _scrollController.position;
    final viewportHeight = position.viewportDimension;
    final bottomZoneStart = _bottomZoneStartY(viewportHeight);
    final inTop = viewportY < _edgeScrollZonePx;
    final inBottom = viewportY > bottomZoneStart;
    if (!inTop && !inBottom) {
      _stopEdgeScroll(); // left the zone; the next drag update re-arms it.
      return;
    }
    final zoneDepth =
        (inTop ? _edgeScrollZonePx - viewportY : viewportY - bottomZoneStart)
            .abs();
    final step = zoneDepth.clamp(0.0, _edgeScrollZonePx);
    final target = inTop ? position.pixels - step : position.pixels + step;
    // Lower bound 0.0 (not minScrollExtent): a drag near the top edge
    // must never pull the header into view.
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if (clamped == position.pixels) {
      _stopEdgeScroll(); // at the content edge -- nothing left to scroll.
      return;
    }
    position.jumpTo(clamped);
    // The content moved under the (stationary) finger: re-derive the
    // drop slot so the ghost follows the finger's viewport point.
    // `_dragSeedForOffset` takes the same TILE-LOCAL dy as the drag
    // callbacks: finger content y (viewport y + new scroll offset)
    // minus the tile's content top.
    _dragTargetStart =
        _dragSeedForOffset(viewportY + clamped - _dragOriginalTopPx);
    _syncDragState();
  }

  /// Stop the edge auto-scroll (drag end/cancel, the finger left the
  /// edge zone, or the content edge was reached).
  void _stopEdgeScroll() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
    _dragFingerViewportY = null;
  }

  /// Day-content px top for a start (ms) on [dayStart] (cross-midnight
  /// clamp mirrors [TileGridWidget._recomputePosition]).
  double _topPx({required DateTime dayStart, required int startMs}) {
    final dayStartMs = dayStart.millisecondsSinceEpoch;
    final clampedStart = startMs < dayStartMs ? dayStartMs : startMs;
    return ((clampedStart - dayStartMs) / Duration.millisecondsPerHour) *
        _pxPerHour;
  }

  /// Drop commit — the sub-event's Start/End move to the snapped slot;
  /// the parent calendar-event window (CalStart/CalEnd) is PRESERVED
  /// from the tile's original `calendarEventStart/End` so the scheduler
  /// keeps the sub-event inside its original (often multi-day) slot —
  /// the tile's height (its own start/end span) is untouched by the
  /// commit. Only a tile without a usable parent window keeps the hard
  /// pin (CalStart/CalEnd = the snapped slot) so the request always
  /// carries a usable window. The request rides
  /// [EvaluateSchedule](callBack:) on the schedule state the grid
  /// dispatched on (the [playBackButtons] `setAsNowTile` pattern): the
  /// tile holds the dropped slot optimistically while in flight.
  void _commitDragMove(SubCalendarEvent tile, DayGridDragSeed seed) {
    // A new commit resets the previous commit's badge (the lift already
    // clears it too; the duplicate-drop guard below still runs after).
    _clearSaveState();
    // In-flight/duplicate-drop guard: a second drop while the first
    // request is in flight (or another drag owns a finger) is ignored.
    if (_settlingMove != null || _dragging) {
      _dragTargetStart = null;
      _controller.mode = DayGridMode.idle;
      _syncDragState();
      return;
    }
    final hasParentWindow = tile.calendarEventStartTime != null &&
        tile.calendarEventEndTime != null;
    final edit = EditTilerEvent()
      ..id = tile.id
      ..name = tile.name
      ..splitCount = tile.split
      ..startTime = seed.start
      ..endTime = seed.end
      // Preserve the parent calendar-event window — only Start/End move.
      // No usable parent window: hard pin the snapped slot.
      ..calStartTime =
          hasParentWindow ? tile.calendarEventStartTime! : seed.start
      ..calEndTime = hasParentWindow ? tile.calendarEventEndTime! : seed.end
      ..thirdPartyType =
          tile.thirdpartyType?.name // 'tiler' — the lift gate above.
      ..thirdPartyId = tile.thirdpartyId
      ..thirdPartyUserId = tile.thirdPartyUserId;
    Utility.debugPrint('DayGrid::drag::commit ${tile.uniqueId}: '
        'start=${_dragLogTime(edit.startTime)} '
        'end=${_dragLogTime(edit.endTime)} '
        'calStart=${_dragLogTime(edit.calStartTime)} '
        'calEnd=${_dragLogTime(edit.calEndTime)} '
        '${hasParentWindow ? 'parentWindow' : 'hardPin'}');

    final scheduleState = context.read<ScheduleBloc>().state;
    List<SubCalendarEvent> preDragSubEvents = <SubCalendarEvent>[];
    List<Timeline> renderedTimelines = <Timeline>[];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();
    if (scheduleState is ScheduleEvaluationState) {
      preDragSubEvents = scheduleState.subEvents;
      renderedTimelines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    } else if (scheduleState is ScheduleLoadedState) {
      preDragSubEvents = scheduleState.subEvents;
      renderedTimelines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    } else if (scheduleState is ScheduleLoadingState) {
      preDragSubEvents = scheduleState.subEvents;
      renderedTimelines = scheduleState.timelines;
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }
    // The bloc may not hold the rendered schedule (e.g. tiles are served
    // straight through the widget): fall back to what is actually on
    // screen so the optimistic re-evaluation and rollback restore the
    // real pre-drag tiles.
    if (preDragSubEvents.isEmpty) {
      preDragSubEvents = widget.tiles;
    }

    final dayStart = _gridDayStart();
    final request = (widget.subCalendarEventApi ??
            (_subCalendarEventApi ??
                (_subCalendarEventApi =
                    SubCalendarEventApi(getContextCallBack: () => context))))
        .updateSubEvent(edit);
    final move = _SettlingMove(
      tileId: tile.uniqueId,
      topPx: _topPx(
          dayStart: dayStart!, startMs: seed.start.millisecondsSinceEpoch),
      preDragTop: _topPx(dayStart: dayStart, startMs: tile.start!),
      preDragSubEvents: preDragSubEvents,
    );
    setState(() {
      // Optimistic settle: the tile holds the dropped slot (no
      // animation while mode != idle; the ghost goes away).
      _settlingMove = move;
      _dragTargetStart = null;
      _controller.mode = DayGridMode.idle;
      // Show the `saving` spinner on this tile while the commit is in
      // flight (the spinner itself is driven by the in-flight settle
      // move, so it can never outlive the request).
      _savingTileId = tile.uniqueId;
      _saveStatus = TileSaveStatus.saving;
    });
    Utility.debugPrint('DayGrid::drag::hold ${tile.uniqueId}: '
        'topPx=${move.topPx.toStringAsFixed(1)} '
        'preDragTop=${move.preDragTop.toStringAsFixed(1)} '
        'overrideStart=${_dragLogTime(seed.start)} '
        'overrideEnd=${_dragLogTime(seed.end)}');
    request.then((confirmed) {
      // The position settles when the parent re-serves data with a
      // changed time for the tile ([_syncSettlingMove] clears it). The
      // request has settled — the `saving` spinner clears and the
      // `saved` badge shows on the moved tile (no timer; it lingers
      // until the next drag interaction).
      AnalysticsSignal.send('daygrid_drag_commit', additionalInfo: {
        'tileId': tile.uniqueId,
        'start': seed.start.millisecondsSinceEpoch,
        'end': seed.end.millisecondsSinceEpoch,
      });
      if (mounted && _savingTileId == tile.uniqueId) {
        setState(() {
          _saveStatus = TileSaveStatus.saved;
        });
      }
    }).catchError((Object e) {
      Utility.debugPrint('DayGrid:: drag commit failed: $e');
      AnalysticsSignal.send('daygrid_drag_rollback',
          additionalInfo: {'tileId': tile.uniqueId});
      // The request failed — the `error` badge shows on the moved tile
      // (the rollback slides it back to its pre-drag slot).
      if (mounted && _savingTileId == tile.uniqueId) {
        setState(() {
          _saveStatus = TileSaveStatus.error;
        });
      }
      _rollbackDragMove();
      _showDragErrorToast();
    });
    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: preDragSubEvents,
        renderedTimelines: renderedTimelines,
        renderedScheduleTimeline: lookupTimeline,
        scheduleStatus: scheduleStatus,
        isAlreadyLoaded: true,
        callBack: request));
  }

  /// Rollback: restore the pre-drag schedule state (the tile slides
  /// back to its pre-drag slot via the layout transition) and drop the
  /// optimistic override.
  void _rollbackDragMove() {
    final move = _settlingMove;
    _settlingMove = null;
    if (!mounted) {
      return;
    }
    if (move != null) {
      Utility.debugPrint('DayGrid::drag::rollback ${move.tileId}: '
          'preDragTop=${move.preDragTop.toStringAsFixed(1)} '
          '-> restoring pre-drag tiles');
      context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
          subEvents: move.preDragSubEvents,
          timelines: <Timeline>[],
          lookupTimeline: Utility.todayTimeline(),
          previousLookupTimeline: Utility.initialScheduleTimeline,
          scheduleStatus: ScheduleStatus()));
    }
    _syncDragState();
  }

  /// Localized failure toast (best-effort — a missing localization
  /// never blocks the rollback itself).
  void _showDragErrorToast() {
    try {
      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n?.failedToUpdateTile ?? 'Failed to move the tile.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Utility.debugPrint('DayGrid:: drag toast failed: $e');
    }
  }

  /// Reconcile the in-flight settle override with a freshly re-served
  /// tile set: once the model carries the settled time for the moved
  /// tile (server confirmation) — or the rollback restored the
  /// pre-drag time — the position is model-owned again and the
  /// override clears (the layout transition settles the tile).
  void _syncSettlingMove(List<SubCalendarEvent> tiles) {
    final move = _settlingMove;
    if (move == null) {
      return;
    }
    final dayStart = _gridDayStart();
    SubCalendarEvent? tile;
    for (final t in tiles) {
      if (t.uniqueId == move.tileId) {
        tile = t;
        break;
      }
    }
    if (tile == null || dayStart == null) {
      return; // the tile is gone from the day — the override is moot.
    }
    final modelTop = _topPx(dayStart: dayStart, startMs: tile.start ?? 0);
    if ((modelTop - move.preDragTop).abs() >= 0.5) {
      // The model moved off its pre-drag position — the parent has
      // re-served with a confirmed or corrected time. Release the
      // optimistic hold; the position becomes model-owned and the
      // layout transition slides the tile to the new slot.
      Utility.debugPrint('DayGrid::drag::settle ${move.tileId}: '
          'modelTop=${modelTop.toStringAsFixed(1)} '
          'preDragTop=${move.preDragTop.toStringAsFixed(1)} '
          'modelStart=${_dragLogTime(tile.start)} '
          'modelEnd=${_dragLogTime(tile.end)} '
          'duration=${tile.duration.inMinutes}m '
          '-> releasing override');
      _settlingMove = null;
      _controller.mode = DayGridMode.idle;
    }
  }

  /// The optimistic start (ms) override for [tile] while a settle move
  /// is in flight (`null` when the model owns the position).
  int? _settledStartOverride(SubCalendarEvent tile) {
    final move = _settlingMove;
    if (move == null || move.tileId != tile.uniqueId) {
      return null;
    }
    final dayStart = _gridDayStart();
    if (dayStart == null) {
      return null;
    }
    return (dayStart.millisecondsSinceEpoch +
            (move.topPx / _pxPerHour * Duration.millisecondsPerHour))
        .toInt();
  }

  /// One setState for drag-bookkeeping changes (mode, target, flags).
  void _syncDragState() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  /// Reset the drag-commit save badge to idle. Called at the start of the
  /// next lift and commit, so a lingering `saved`/`error` chip clears on
  /// the next drag interaction (no timer). No-op when already idle.
  void _clearSaveState() {
    if (_saveStatus == TileSaveStatus.idle) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saveStatus = TileSaveStatus.idle;
    });
  }

  /// The [TileSaveStatus] to pass to [tile]'s [TileGridWidget]. `saving`
  /// is derived from the in-flight settle move (so it can never linger as
  /// an active spinner); `saved`/`error` are read from the field. `idle`
  /// for every other tile (only the committed tile carries a badge).
  TileSaveStatus _saveStatusFor(SubCalendarEvent tile) {
    final id = _savingTileId;
    if (id == null || id != tile.uniqueId) {
      return TileSaveStatus.idle;
    }
    // `saving` only while the commit is actually in flight (the optimistic
    // settle move is still held). Once the request settles the field holds
    // `saved`/`error` and takes precedence — even before the parent
    // re-serves data and clears [_settlingMove] — so the spinner never
    // lingers past the response.
    if (_saveStatus == TileSaveStatus.saving) {
      final move = _settlingMove;
      if (move != null && move.tileId == tile.uniqueId) {
        return TileSaveStatus.saving;
      }
    }
    return _saveStatus;
  }

  /// The live drag ghost: a snap line at the snapped slot, a dashed
  /// slot outline at the tile's column, and a floating time chip with
  /// the snapped start (out-of-range drops turn the ghost red — the
  /// drop itself is still blocked).
  Widget _dragGhost() {
    final tile = _dragTile;
    final seed = _dragTargetStart;
    final dayStart = _gridDayStart();
    if (tile == null || seed == null || dayStart == null) {
      return const SizedBox.shrink();
    }
    final top =
        _topPx(dayStart: dayStart, startMs: seed.start.millisecondsSinceEpoch);
    final height = (seed.end.difference(seed.start).inMilliseconds /
            Duration.millisecondsPerHour) *
        _pxPerHour;
    final label = TimeOfDay.fromDateTime(seed.start).format(context);
    final blocked = !seed.withinRange;
    final accent = blocked
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return AnimatedPositioned(
      key: const Key('daygrid_drag_ghost'),
      top: top,
      left: 0,
      right: 0,
      height: height.clamp(1.0, double.infinity),
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Snap line across the day at the slot's top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: accent.withValues(alpha: 0.8),
            ),
          ),
          // Slot outline at the tile's column.
          Positioned(
            top: 1,
            left: _dragGhostLeft,
            width: _dragGhostWidth.clamp(1.0, double.infinity),
            height: (height - 1).clamp(1.0, double.infinity),
            child: Container(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: accent.withValues(alpha: 0.8), width: 1.5),
              ),
            ),
          ),
          // Floating time chip on the snap line.
          Positioned(
            top: -9,
            left: _dragGhostLeft.clamp(0.0, double.infinity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reports header reveal progress (C18) when it changes.
  void _onScrollChanged() {
    final cb = widget.onHeaderRevealChanged;
    if (cb == null || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final progress = DayGridWidget.headerRevealProgress(
        position.pixels, position.minScrollExtent);
    if ((progress - _lastHeaderReveal).abs() < 0.001) return;
    _lastHeaderReveal = progress;
    cb(progress);
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
    // Clamp — jumpTo asserts on out-of-range values in debug.
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) {
      _scrollController.jumpTo(clamped);
    }
    Utility.debugPrint('DayGrid:: initial scroll -> '
        '${clamped.toStringAsFixed(1)}px');
  }

  /// Pull-to-refresh — the same ScheduleBloc wiring as
  /// [EnhancedTileBatch]: dispatch `GetScheduleEvent(forceRefresh: true)`,
  /// carrying the current state's subEvents/timeline when it holds them.
  Future<void> _onGridRefresh() async {
    if (widget.preview) {
      // The preview tiles belong to VibeChatBloc — a
      // pull-to-refresh here must not dispatch to ScheduleBloc. (The
      // RefreshIndicator is not even rendered in preview; this guards the
      // shared code path.)
      return;
    }
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
    // Everything below is derived fresh from
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

    // if (constant.isDebug) {
    //   Utility.debugPrint('DayGrid:: rebuild with ${sortedTiles.length} tiles');
    // }

    // The TileCast action id to highlight in this
    // frame (null unless preview mode supplies one).
    final highlightedEntityId =
        widget.preview ? widget.selectedActionEntityId : null;

    // Every position/height derives from the controller's
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

            // Live now-line + gutter time bubble, today
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
            // (>=16h / all-day -> the pinned strip).
            //
            // Preview (TileCast) mode does NOT filter
            // non-viable tiles — the user must see *why* the proposal
            // conflicts. Live mode keeps the parity filter (non-viable
            // excluded).
            final renderable = sortedTiles
                .where((t) => t.id.isNot_NullEmptyOrWhiteSpace())
                .where((t) => _renderableInTimeline(t, dayStart))
                .where((t) =>
                    widget.preview ||
                    (t.isViable ?? true) ||
                    DayGridWidget.tileMatchesAction(t, highlightedEntityId))
                .toList();

            // Overlap columns. Cluster the renderable tiles and give
            // each a shared-width column so overlapping tiles sit side by
            // side instead of stacking. A one-tile cluster keeps the full
            // [tileLeft, tileLeft + tileWidth] region (the single
            // tile geometry). Empty when tileWidth <= 0; the per-tile
            // fallback below then uses the full region.
            // Clustered on the RENDERED range (each tile is at least the
            // pixel-floor duration tall), so short tiles whose inflated
            // boxes overlap get side-by-side columns instead of stacking.
            final columnLayout =
                OverlapColumns.assign<String, SubCalendarEvent>(
              tiles: renderable,
              keyOf: (t) => t.uniqueId,
              left: tileLeft,
              width: tileWidth,
              minDurationMs:
                  TileGridWidgetState.minRenderedDurationMs(pxPerHour),
            );

            // Z-order: the tapped tile renders last (on top) — same
            // behaviour as before, without duplicating the widget.
            // The highlighted TileCast action tile
            // renders above the unhighlighted tiles (top-z in its overlap
            // cluster), below the user-tapped tile.
            final highlighted = highlightedEntityId != null
                ? renderable
                    .where((t) =>
                        DayGridWidget.tileMatchesAction(t, highlightedEntityId))
                    .toList()
                : <SubCalendarEvent>[];
            final highlightedIds = highlighted.map((t) => t.id).toSet();
            final unselected = renderable
                .where((t) =>
                    !_selectedEventIds.contains(t.id) &&
                    !highlightedIds.contains(t.id))
                .toList();
            final selected = renderable
                .where((t) => _selectedEventIds.contains(t.id))
                .toList();

            // 24-hour gutter: time labels + hour rows at pxPerHour.
            // Adaptive gutter: hour guide lines AND labels thin out to
            // every 2nd hour below the threshold so the 35px gutter stays
            // legible as the rows shrink; at high zoom, sub-hour tick
            // hairlines (30 min; 15 min at/above the fine-snap boundary)
            // fill in the finer structure.
            final labelStride = DayGridWidget.gutterLabelStride(pxPerHour);
            final lineStride = DayGridWidget.gutterLineStride(pxPerHour);
            final tickMinutes =
                DayGridWidget.gutterTickIntervalMinutes(pxPerHour);
            final tickColor =
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
            final gutterWidgets = <Widget>[];
            for (int hour = 0; hour < timeCellCount; hour++) {
              final timeOfDay = TimeOfDay(hour: hour, minute: 0);
              if (hour % labelStride == 0) {
                gutterWidgets.add(TimeOfDayTimeCellWidget(
                  start: timeOfDay,
                  height: pxPerHour,
                ));
              }
              if (hour % lineStride == 0) {
                gutterWidgets.add(TileTimeCellWidget(
                  start: timeOfDay,
                  left: gutter,
                  height: pxPerHour,
                ));
              }
              // Sub-hour tick hairlines (full width, faint) between the
              // major hour lines.
              if (tickMinutes != null && lineStride == 1) {
                for (int minute = tickMinutes;
                    minute < 60;
                    minute += tickMinutes) {
                  gutterWidgets.add(Positioned(
                    key: ValueKey<String>('daygrid_tick_h${hour}m${minute}'),
                    top: hour * pxPerHour + (minute / 60) * pxPerHour,
                    left: gutter,
                    right: 0,
                    height: 1,
                    child: ColoredBox(color: tickColor),
                  ));
                }
              }
            }

            // Animate position deltas only while idle; during a
            // pinch/drag the tiles track the controller directly (no double
            // animation). Day-scope the per-tile keys so a tile's element never
            // carries across days.
            final animate = _controller.mode == DayGridMode.idle;
            final keyPrefix = (widget.dayKey == null || widget.dayKey!.isEmpty)
                ? ''
                : 'day_${widget.dayKey}_';

            final tileWidgets =
                [...unselected, ...highlighted, ...selected].map(
              (tile) {
                final column = columnLayout[tile.uniqueId];
                // The dragged tile dims (the ghost shows its drop slot);
                // the optimistic start override holds the moved tile at
                // its dropped slot while the commit request is in flight.
                final isDragSource =
                    _dragTile != null && _dragTile!.uniqueId == tile.uniqueId;
                final settleOverride = _settledStartOverride(tile);
                return TileGridWidget(
                  // Stable per-tile identity: add/remove/replace of
                  // tiles maps to element remove/update — never a stale
                  // reused state.
                  key: ValueKey<String>(
                      'daygrid_tile_${keyPrefix}${tile.uniqueId}'),
                  tilerEvent: tile,
                  onTap: onTileGridTap,
                  pxPerHour: pxPerHour,
                  dayStart: dayStart,
                  left: column?.left ?? tileLeft,
                  tileGridWidth: column?.width ?? tileWidth,
                  animate: animate,
                  // TileCast preview mode (read-only
                  // per-tile surface, mirrors `EnhancedTileCard.preview`).
                  preview: widget.preview,
                  // The highlighted TileCast
                  // action's tile gets the dotted-border treatment (same
                  // rule as `EnhancedTileCard.hasDottedBorder`).
                  hasDottedBorder: highlightedIds.contains(tile.id) == true,
                  // Newly-added tiles slide in (staggered);
                  // existing/static tiles pass null (no enter animation).
                  enterDelay: _enterDelays[tile.uniqueId],
                  // Long-press drag-and-drop (lift/move/drop) — the
                  // tile's own detector loses quick drags to the grid's
                  // scroll view (scrolls instead of dragging).
                  onLongPressStart: (offset) => _onTileLongPressStart(
                      tile,
                      offset,
                      column?.left ?? tileLeft,
                      column?.width ?? tileWidth),
                  onDragUpdate: _onTileDragUpdate,
                  onDragEnd: () => _onTileDragEnd(tile),
                  dimmed: isDragSource,
                  suppressTap: isDragSource && (_dragging || _dragSuppressTap),
                  localStartMsOverride: settleOverride,
                  // Drag-commit save badge (overlay-only): the committed
                  // tile shows saving/saved/error; every other tile idle.
                  saveStatus: _saveStatusFor(tile),
                );
              },
            ).toList();

            // Travel/return bands: the grid-mode equivalent of the list-mode
            // `TravelConnector` (pre) and `ReturnConnector` travel section
            // (post). One band per positive travel time, clamped into the grid
            // day, so the gutter shows the same travel info the day list does.
            // Built here and rendered below the tiles so tile content is never
            // covered by a band.
            // Bands dim while a drag (or its commit request) is in
            // flight — the real travel times depend on the new
            // neighbors and only the server knows post-EvaluateSchedule.
            final bandDimming = _dragging || _settlingMove != null;
            final travelBandWidgets = <Widget>[];
            if (dayStart != null && pxPerHour.isFinite && pxPerHour > 0) {
              // Previous tile in time = the pre-band "from" fallback (the same
              // role as `TravelConnector.fromTile`). `renderable` is sorted by
              // start via [_sortedTiles].
              final previousTileById = <String, SubCalendarEvent?>{};
              SubCalendarEvent? previousTile;
              for (final tile in renderable) {
                previousTileById[tile.uniqueId] = previousTile;
                previousTile = tile;
              }
              for (final tile in renderable) {
                final column = columnLayout[tile.uniqueId];
                final bands = TravelBand.bandsForTile(
                  tile: tile,
                  dayStart: dayStart,
                  pxPerHour: pxPerHour,
                );
                if (bands.isEmpty) {
                  continue;
                }
                final colLeft = column?.left ?? tileLeft;
                final colWidth = column?.width ?? tileWidth;
                for (final band in bands) {
                  travelBandWidgets.add(TravelBandWidget(
                    key: ValueKey<String>(
                      'daygrid_band_${keyPrefix}${tile.uniqueId}_${band.kind}',
                    ),
                    tile: tile,
                    kind: band.kind,
                    top: band.top,
                    height: band.height,
                    left: colLeft,
                    width: colWidth,
                    fromTile: band.kind == TravelBandKind.pre
                        ? previousTileById[tile.uniqueId]
                        : null,
                    animate: animate,
                    dimmed: bandDimming,
                  ));
                }
              }
            }

            // Capture this frame's layout + tile set so the
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

            // Fading-out ghosts for removed tiles. Each is a
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

            // Apply the queued highlight auto-scroll
            // (set by [_onSelectedActionChanged] on a carousel page change).
            if (_pendingPreviewScroll != null) {
              WidgetsBinding.instance.addPostFrameCallback(_applyPreviewScroll);
            }

            // The grid body — pull-to-refresh only in
            // the live grid; the TileCast preview renders the bare scroll
            // view (the preview schedule belongs to VibeChatBloc, and
            // TileCast's own header sheet is the chrome there).
            // The px of the scroll viewport's bottom that sit behind a bottom
            // navigation bar + home-indicator (0 when the body does not extend
            // behind a bottom bar). Reused so the scrollable content and the
            // bottom auto-scroll zone stop at the same visible edge.
            final bottomClearance = _edgeScrollBottomClearance();
            // Center-anchored scroll host (C18): the grid Stack is the
            // `center` sliver so `pixels == 0` is always the top of the day;
            // the optional header sliver sits BEFORE it, in negative extent.
            final Widget gridStack = Stack(
                children: <Widget>[
                  // Tap-to-add. A background tap target
                  // behind the tiles (first child => lowest z, so the
                  // positioned tiles on top win the hit test and keep their
                  // onTileTap behaviour). The handler no-ops unless a
                  // [day] is supplied, so the forecast peek (DayCast) stays
                  // read-only.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _onEmptyGridTap,
                    child: SizedBox(
                      width: double.infinity,
                      height: timeCellCount * pxPerHour,
                    ),
                  ),
                  ...gutterWidgets,
                  ...travelBandWidgets,
                  ...tileWidgets,
                  if (_dragTile != null && _dragTargetStart != null)
                    _dragGhost(),
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
                  // Pinch-to-zoom overlay: the TOPMOST, translucent full-area
                  // layer. Translucent hit-testing means EVERY pointer inside
                  // the day area reaches the scale recognizer — even fingers
                  // resting on event tiles (which sit below this overlay and
                  // would otherwise route their pointers away). A single
                  // finger never satisfies the scale recognizer, so tile
                  // taps, empty-area tap-to-add, vertical scroll and the
                  // horizontal day carousel are left untouched; when a
                  // two-finger pinch does win the arena the tiles' taps are
                  // cancelled, so no accidental tile selection mid-pinch.
                  //
                  // The recognizer resolves as soon as the second pointer
                  // lands (a plain `ScaleGestureRecognizer` only resolves
                  // once its span clears `computeScaleSlop`, by which time
                  // the vertical scroll and/or the day carousel's pan slop
                  // has already won the arena and the pinch scrolls instead
                  // of zooms).
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: timeCellCount * pxPerHour,
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.translucent,
                      gestures: <Type, GestureRecognizerFactory>{
                        _ArenaWinningScaleGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                                _ArenaWinningScaleGestureRecognizer>(
                          () => _ArenaWinningScaleGestureRecognizer(),
                          (_ArenaWinningScaleGestureRecognizer instance) {
                            instance
                              ..onStart = _onScaleStart
                              ..onUpdate = _onScaleUpdate
                              ..onEnd = _onScaleEnd;
                          },
                        ),
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            final Widget gridBody = CustomScrollView(
              controller: _scrollController,
              center: _gridCenterKey,
              slivers: <Widget>[
                if (widget.header != null)
                  SliverToBoxAdapter(child: widget.header),
                SliverToBoxAdapter(key: _gridCenterKey, child: gridStack),
                // The scroll content is exactly one 24h day tall (the
                // tap-to-add background SizedBox above). With
                // `Scaffold(extendBody: true)` the raw scroll viewport is
                // taller than the visible area, so at max extent the bottom
                // of the day is pinned BEHIND the bottom bar and unreachable
                // -- the last ~56px + home-indicator (~the final hour) never
                // scrolled into view. Growing the scrollable content by the
                // detected clearance lifts the day end up to the visible
                // bottom edge. `bottomClearance` is 0 when the body does not
                // extend behind a bottom bar, so hosts without one are
                // unchanged.
                SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
              ],
            );

            if (widget.preview) {
              // Read-only preview — no pull-to-refresh
              // chrome; TileCast's own header sheet is the chrome there.
              return gridBody;
            }
            return RefreshIndicator(
              color: Theme.of(context).colorScheme.tertiary,
              onRefresh: _onGridRefresh,
              child: gridBody,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nowLineTimer?.cancel(); // no leaked minute timers
    _removeTimer?.cancel(); // no leaked ghost-cleanup timers
    _edgeScrollTimer?.cancel(); // no leaked drag auto-scroll timers
    _ownedController?.dispose(); // own resources first (dispose order)
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }
}

// A two-finger scale recognizer that claims the gesture arena the moment the
// second pointer lands.
//
// Must be mounted on the TOPMOST, `HitTestBehavior.translucent` full-area
// overlay of the grid Stack — only then does it receive BOTH pinch pointers
// even when the fingers land on event tiles (each pointer is hit-tested
// independently, and a `ScaleGestureRecognizer` needs two pointers on the
// SAME recognizer instance to resolve).
//
// Flutter's default [ScaleGestureRecognizer] only calls
// `resolve(GestureDisposition.accepted)` once its span / focal-point delta
// crosses `computeScaleSlop`. A real pinch usually spreads along a diagonal,
// so by the time the scale clears that slop the grid's vertical scroll and/or
// the horizontal day carousel (carousel_slider `PageView`) have already
// cleared the smaller pan slop and won the arena — the pinch then scrolls or
// pages instead of zooming. By resolving as soon as two fingers are down (an
// unambiguous pinch, before any movement) this recognizer pre-empts those
// competing drag recognizers, so a two-finger gesture always zooms while a
// single finger still scrolls and taps.
class _ArenaWinningScaleGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerDownEvent && pointerCount >= 2) {
      // Claim the arena for the whole multi-pointer gesture now that two
      // fingers are down. Redundant (and harmless) if the base state machine
      // already accepted on this same event.
      resolve(GestureDisposition.accepted);
    }
  }
}

// A removed tile's last-known geometry, for ghost placement.
class _TileLayout {
  final double left;
  final double width;
  _TileLayout(this.left, this.width);
}

// A removed tile still fading out in the grid.
class _RemovingTile {
  final SubCalendarEvent tile;
  final double left;
  final double width;
  _RemovingTile(this.tile, this.left, this.width);
}

/// The in-flight drag-and-drop settle move.
///
/// While non-null the dragged tile renders at [topPx] (its dropped,
/// snapped slot) even though the model still carries the pre-drag
/// time — the position only becomes model-owned once the parent
/// re-serves data with a changed time for the tile (or a rollback
/// fires and [_SettlingMove.tileId]'s start is restored).
class _SettlingMove {
  /// The moved tile's [TilerEvent.uniqueId].
  final String tileId;

  /// The optimistic settled top (day-content px at the drop).
  final double topPx;

  /// The pre-drag subEvents of the schedule state the commit dispatched
  /// on — restored via [ReloadLocalScheduleEvent] when the request fails.
  final List<SubCalendarEvent> preDragSubEvents;

  /// The tile's pre-drag top (day-content px). The optimistic hold is
  /// released once the model moves off this position (the server has
  /// re-served with a confirmed or corrected time).
  final double preDragTop;

  _SettlingMove({
    required this.tileId,
    required this.topPx,
    required this.preDragTop,
    required this.preDragSubEvents,
  });
}
