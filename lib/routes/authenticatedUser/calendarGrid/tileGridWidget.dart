// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';

import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileCardStyle.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The persistence outcome of the tile's most recent drag-to-reschedule,
/// shown as a small overlay badge on the tile (no timer — the badge lingers
/// until the next drag interaction resets it). Shared by
/// `TileGridWidget`/`_TilerEventInnerGridWidget` and driven by the grid
/// (`DayGridWidget`) around the `updateSubEvent` request.
enum TileSaveStatus {
  idle,
  saving,
  saved,
  error,
}

class TileGridWidget extends GridPositionableWidget {
  final TilerEvent tilerEvent;
  final double? tileGridHeight;

  /// Pixels per hour — every position/height of this tile
  /// derives from it (legacy 80 when omitted).
  final double? pxPerHour;

  /// Day context for cross-midnight clamping. When omitted,
  /// the legacy time-of-day positioning applies.
  final DateTime? dayStart;

  /// Responsive tile width (legacy 270 when omitted).
  final double? tileGridWidth;
  final Function? onTap;

  /// Animate the tile's top/left delta on a position change
  /// (true by default). The parent passes `false` while the grid is
  /// zooming/dragging so positions track the controller directly. Reduced
  /// motion is also respected inside the widget.
  final bool? animate;

  /// Non-null when this tile was newly added and should slide
  /// in (scale + fade) from a corner. The value is the stagger delay applied
  /// before the reveal; `null` means the tile is static (no enter animation —
  /// the initial full-day render and day-swaps pass `null`).
  final Duration? enterDelay;

  /// `true` for a fading-out ghost of a removed tile — it
  /// renders at full opacity for one frame, then animates to `0`.
  final bool? exiting;

  /// TileCast (vibe-chat) preview mode — the tile is
  /// read-only. The grid-level gates (no tap-to-add, no refresh dispatch,
  /// no zoom persist) live in `DayGridWidget`; this flag keeps the per-tile
  /// surface aligned with `EnhancedTileCard.preview` if a preview-specific
  /// tile rendering is added later.
  final bool preview;

  /// The dotted-border treatment for the highlighted
  /// TileCast action tile — same rule as `EnhancedTileCard.hasDottedBorder`
  /// (id `contains` the action's entity id).
  final bool hasDottedBorder;

  /// Long-press lift for drag-and-drop reschedule. [localOffset] is the
  /// lift point in DAY-CONTENT coordinates (the detector sits inside
  /// the scroll content, so the grid derives `y / pxPerHour` from it).
  /// A quick vertical drag still loses the arena to the grid's scroll
  /// view (the long press never elapses) and scrolls normally.
  final void Function(Offset localOffset)? onLongPressStart;

  /// Drag move while the tile is lifted — [localPosition] is the
  /// finger's point in DAY-CONTENT coordinates (the detector sits
  /// inside the scroll content, so the grid derives `y / pxPerHour`).
  final void Function(Offset localPosition)? onDragUpdate;

  /// Drop (the finger lifted during a long-press drag).
  final VoidCallback? onDragEnd;

  /// Dim the tile while it is the drag source (the grid's ghost shows
  /// the drop slot) — `true` while its long-press drag is active.
  final bool dimmed;

  /// Suppress the ordinary tile tap (opening the detail) while a drag
  /// owns the surface or cancelled just before the tap could fire.
  final bool suppressTap;

  /// Local start-time override (ms) for optimistic rendering while a
  /// drag commit is in flight: the tile holds its dropped slot until
  /// the parent re-serves data with the confirmed time. `null` means
  /// the model owns the position.
  final int? localStartMsOverride;

  /// The drag-to-reschedule persistence outcome for THIS tile (the grid
  /// passes `idle` for every other tile). Rendered as a small overlay
  /// badge on the tile body — `saving` shows a spinner, `saved` a check,
  /// `error` a warning. Never alters the tile's size, caption or
  /// overlap layout (overlay-only).
  final TileSaveStatus saveStatus;
  TileGridWidget(
      {Key? key,
      required this.tilerEvent,
      double? left,
      this.tileGridHeight,
      this.pxPerHour,
      this.dayStart,
      this.tileGridWidth,
      this.onTap,
      this.animate,
      this.enterDelay,
      this.exiting,
      this.preview = false,
      this.hasDottedBorder = false,
      this.onLongPressStart,
      this.onDragUpdate,
      this.onDragEnd,
      this.dimmed = false,
      this.suppressTap = false,
      this.localStartMsOverride,
      this.saveStatus = TileSaveStatus.idle,
      Duration durationPerUnitTime = GridPositionableWidget.durationPerHeight})
      : super(
            key: key,
            left: left,
            height: pxPerHour ??
                tileGridHeight ??
                GridPositionableWidget.defaultHeigtPerDuration,
            durationPerCell: durationPerUnitTime);

  @override
  TileGridWidgetState createState() => TileGridWidgetState();
}

class TileGridWidgetState extends GridPositionableState {
  late TilerEvent? tilerEvent;
  static final Duration minDuration = Duration(minutes: 20);

  /// Pixel floor for a rendered tile, so the (compact) name caption always
  /// fits regardless of zoom. Must be >= [collapsedTileHeight].
  static const double minTileHeightPx = 20;

  /// Pure: the minimum RENDERED duration (ms) at [pxPerHour] — the larger
  /// of [minDuration] and the duration that spans [minTileHeightPx]. Both
  /// the tile's own height clamp and the overlap-column clustering use
  /// this, so two short tiles whose inflated boxes overlap get columns.
  static int minRenderedDurationMs(double pxPerHour) {
    final int floorMs = pxPerHour > 0
        ? (minTileHeightPx / pxPerHour * Duration.millisecondsPerHour).round()
        : 0;
    final int minDurationMs = minDuration.inMilliseconds;
    return floorMs > minDurationMs ? floorMs : minDurationMs;
  }

  /// Below this pixel height a tile collapses to a plain color bar (no
  /// name): one 11px line, vertically centred, needs ~16px. Between this
  /// and [timeRangeTileHeight] the card renders the COMPACT caption tier
  /// (single line, smaller font, no vertical padding) so names survive
  /// zooming out.
  static const double collapsedTileHeight = 16;

  /// Pure so the reflow threshold is
  /// unit-testable without pumping a tile — true when [tileHeight] is too
  /// short for the name caption.
  static bool tileContentCollapsed(double tileHeight) =>
      tileHeight < collapsedTileHeight;

  /// The second (time-range) line needs a name line + an 11px line + the
  /// card's vertical padding — tiles shorter than this render the name only
  /// (the compact tier).
  static const double timeRangeTileHeight = 48;

  /// Pure: the compact single-line caption tier (name only, small font,
  /// vertically centred) — between the bar and the full card.
  static bool tileCaptionCompact(double tileHeight) =>
      !tileContentCollapsed(tileHeight) && !tileTimeRangeVisible(tileHeight);

  /// Pure: caption font size for [tileHeight] — 13 at the full tier,
  /// stepping down to 11 for the shortest compact tiles.
  static double captionFontSize(double tileHeight) {
    if (tileHeight >= timeRangeTileHeight) return 13;
    if (tileHeight >= 26) return 12;
    return 11;
  }

  /// Pure: true when [tileHeight] has room for the time-range line under
  /// the name.
  static bool tileTimeRangeVisible(double tileHeight) =>
      tileHeight >= timeRangeTileHeight;
  late ThemeData theme;
  late ColorScheme colorScheme;

  // Enter/exit animation state.
  /// Enter: false until the stagger delay elapses (only when [TileGridWidget
  /// .enterDelay] is set); drives the 0 -> 1 fade/scale reveal.
  bool _revealed = true;

  /// Exit: flipped one frame after a ghost mounts; drives the 1 -> 0 fade-out.
  bool _fading = false;
  Timer? _enterTimer;

  /// The lift point of the active long-press drag (DAY-CONTENT
  /// coordinates — the detector sits inside the scroll content); the
  /// baseline the grid inverts into the drop time (`y / pxPerHour`).
  Offset? _longPressLiftOffset;

  @override
  void initState() {
    super.initState();
    if (this.widget is TileGridWidget) {
      tilerEvent = (this.widget as TileGridWidget).tilerEvent;
      // Start hidden only when the parent marks this as a fresh add; a null
      // enterDelay (initial render / day-swap) stays visible from frame one.
      _revealed = (this.widget as TileGridWidget).enterDelay == null;
    }
    _recomputePosition();
    // Legacy default when the parent supplies no gutter offset.
    if (this.widget.left == null) {
      this.leftPosition = 80.0;
    }
    this.widgetWidth = (this.widget as TileGridWidget).tileGridWidth ?? 270;
    WidgetsBinding.instance.addPostFrameCallback(_onFirstFrame);
  }

  /// After the first frame, kick off the enter reveal (after
  /// the stagger delay) or the exit fade-out, honouring the reduced-motion
  /// and zoom/drag gates.
  void _onFirstFrame(Duration _) {
    if (!mounted) {
      return;
    }
    final w = this.widget as TileGridWidget;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animate = (w.animate ?? true) && !reduce;
    if (w.exiting ?? false) {
      if (!_fading) {
        setState(() => _fading = true);
      }
      return;
    }
    final delay = w.enterDelay;
    if (delay == null) {
      return;
    }
    if (!animate) {
      // Jump cut (zooming/dragging or reduced motion): reveal immediately.
      if (!_revealed) {
        setState(() => _revealed = true);
      }
      return;
    }
    _enterTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    super.dispose();
  }

  /// Derives top/height from the effective px-per-hour. With
  /// a [TileGridWidget.dayStart] the tile is clamped into that day
  /// (cross-midnight clamp). Shared by initState and didUpdateWidget so
  /// zoom/position changes re-derive in place instead of going stale.
  void _recomputePosition() {
    if (this.tilerEvent == null) {
      return;
    }
    final grid = this.widget as TileGridWidget;
    final pxPerHour = this.widget.height;
    final dayStart = grid.dayStart;
    if (dayStart == null) {
      // Legacy path: time-of-day positioning without a day context.
      this.topPosition = this
          .evalTopPosition(TimeOfDay.fromDateTime(this.tilerEvent!.startTime));
      this.widgetHeight = durationToHeight();
    } else {
      assert(pxPerHour.isFinite && pxPerHour > 0,
          'DayGrid:: invalid pxPerHour $pxPerHour');
      final dayStartMs = dayStart.millisecondsSinceEpoch;
      final dayEndMs = dayStartMs + Duration.millisecondsPerDay;
      // The local start override (optimistic drag settle) wins over the
      // model's start while it is set; the duration is preserved.
      final overrideStartMs = grid.localStartMsOverride;
      final modelStartMs = this.tilerEvent!.start ?? 0;
      final startMs = overrideStartMs ?? modelStartMs;
      // When the start override is applied, shift the end by the same
      // delta so the tile's duration is preserved (leaving the end at the
      // model time would invert a downward-move and collapse the tile to
      // a plain color bar — no name).
      final endMs = (overrideStartMs != null && this.tilerEvent!.end != null)
          ? this.tilerEvent!.end! + (overrideStartMs - modelStartMs)
          : (this.tilerEvent!.end ?? startMs);
      // Cross-midnight clamp into the grid day.
      final clampedStart = startMs < dayStartMs ? dayStartMs : startMs;
      final clampedEnd = endMs > dayEndMs ? dayEndMs : endMs;
      if (clampedEnd <= dayStartMs || clampedStart >= dayEndMs) {
        // Fully outside the grid day — the pinned strip owns this.
        this.topPosition = 0;
        this.widgetHeight = 0;
        return;
      }
      this.topPosition =
          ((clampedStart - dayStartMs) / Duration.millisecondsPerHour) *
              pxPerHour;
      this.widgetHeight =
          ((clampedEnd - clampedStart) / Duration.millisecondsPerHour) *
              pxPerHour;
      // Minimum visible height: the larger of minDuration at this zoom and
      // the pixel floor (see [minRenderedDurationMs]).
      final minPx =
          (TileGridWidgetState.minRenderedDurationMs(pxPerHour) /
                  Duration.millisecondsPerHour) *
              pxPerHour;
      if (this.widgetHeight < minPx) {
        this.widgetHeight = minPx;
      }
      // Invariant: the tile stays within [0, 24h] of the day.
      final dayPx = 24 * pxPerHour;
      assert(this.topPosition >= 0 && this.topPosition <= dayPx,
          'DayGrid:: top ${this.topPosition} outside day bounds [0, $dayPx]');
      if (this.topPosition + this.widgetHeight > dayPx) {
        this.widgetHeight = dayPx - this.topPosition;
      }
    }
    this.widgetHeight = grid.tileGridHeight ?? this.widgetHeight;
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant TileGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEvent = (this.widget as TileGridWidget).tilerEvent;
    final eventChanged = !identical(oldWidget.tilerEvent, newEvent);
    final zoomChanged = oldWidget.height != this.widget.height;
    final geometryChanged = oldWidget.left != this.widget.left ||
        oldWidget.tileGridWidth !=
            (this.widget as TileGridWidget).tileGridWidth ||
        oldWidget.dayStart != (this.widget as TileGridWidget).dayStart;
    // Drag inputs: the optimistic start override moves the tile (drop
    // settle / rollback), dimming and tap suppression change its surface.
    final dragInputsChanged = oldWidget.dimmed !=
            (this.widget as TileGridWidget).dimmed ||
        oldWidget.suppressTap != (this.widget as TileGridWidget).suppressTap ||
        oldWidget.localStartMsOverride !=
            (this.widget as TileGridWidget).localStartMsOverride;
    if (!eventChanged &&
        !zoomChanged &&
        !geometryChanged &&
        !dragInputsChanged) {
      return; // same tile, same zoom, same geometry: nothing to re-derive.
    }
    // A different tile/zoom/geometry now owns this element: re-sync
    // the state fields that would otherwise keep
    // rendering the OLD event at the OLD zoom.
    this.tilerEvent = newEvent;
    if (this.widget.left != null) {
      this.leftPosition = this.widget.left!;
    }
    this.widgetWidth = (this.widget as TileGridWidget).tileGridWidth ?? 270;
    _recomputePosition();
  }

  double durationToHeight() {
    Duration duration = minDuration;
    if (this.tilerEvent?.duration != null &&
        this.tilerEvent!.duration.inMilliseconds > duration.inMilliseconds) {
      duration = this.tilerEvent!.duration;
    }

    return (duration.inMilliseconds /
            this.widget.durationPerCell.inMilliseconds) *
        this.widget.height;
  }

  // Drag-and-drop: move/drop/cancel of the long-press lift (the
  /// callbacks are only non-null when the grid wired this tile as
  /// draggable — Tiler-owned, live, non-what-if).
  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    (this.widget as TileGridWidget).onDragUpdate?.call(details.localPosition);
  }

  void _onLongPressEnd() {
    _longPressLiftOffset = null;
    (this.widget as TileGridWidget).onDragEnd?.call();
  }

  /// The long-press lift callback (haptic tick + grid hand-off of the
  /// lift point); a no-op when the grid did not wire this tile as
  /// draggable.
  void _handleLongPressLift(Offset localOffset) {
    final onLongPressStart = (this.widget is TileGridWidget)
        ? (this.widget as TileGridWidget).onLongPressStart
        : null;
    if (onLongPressStart == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    onLongPressStart(localOffset);
  }

  void _onLongPressCancel() {
    // A cancelled lift (e.g. the scroll view won the arena) never
    // dropped anything; the grid's drop handler no-ops it.
    _longPressLiftOffset = null;
    (this.widget as TileGridWidget).onDragEnd?.call();
  }

  void onTapPreviewTile(TilerEvent tile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TileDimensions.borderRadius)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: PreviewDetailsTileWidget(tile),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (this.tilerEvent != null) {
      final animateEnabled = (this.widget is TileGridWidget)
          ? ((this.widget as TileGridWidget).animate ?? true)
          : true;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final animate = animateEnabled && !disableAnimations;

      // Enter (slide-in from a corner) / exit (fade-out) for
      // added/removed tiles. The Positioned root below is unchanged so the
      // Stack keeps placing the tile; opacity + scale apply to the body and
      // are identity (1.0 / 0ms) for static tiles, so existing positions and
      // key-identity tests are unaffected.
      final isExiting = (this.widget is TileGridWidget)
          ? ((this.widget as TileGridWidget).exiting ?? false)
          : false;
      final hasEnter = (this.widget is TileGridWidget)
          ? ((this.widget as TileGridWidget).enterDelay != null)
          : false;
      // Long-press drag wiring — non-null / true only when the grid
      // marked this tile draggable (Tiler-owned, live, non-what-if).
      final bool dimmed = (this.widget is TileGridWidget)
          ? (this.widget as TileGridWidget).dimmed
          : false;
      final bool suppressTap = (this.widget is TileGridWidget)
          ? (this.widget as TileGridWidget).suppressTap
          : false;
      final void Function(Offset localOffset)? onLongPressStart =
          (this.widget is TileGridWidget)
              ? (this.widget as TileGridWidget).onLongPressStart
              : null;
      final double opacityTarget;
      final double scaleTarget;
      final Duration fadeDuration;
      if (isExiting) {
        opacityTarget = _fading ? 0.0 : 1.0;
        scaleTarget = 1.0;
        fadeDuration =
            animate ? const Duration(milliseconds: 200) : Duration.zero;
      } else if (hasEnter) {
        opacityTarget = _revealed ? 1.0 : (animate ? 0.0 : 1.0);
        scaleTarget = _revealed ? 1.0 : (animate ? 0.86 : 1.0);
        fadeDuration =
            animate ? const Duration(milliseconds: 200) : Duration.zero;
      } else if (dimmed) {
        // The drag source dims (the grid's ghost shows the drop slot);
        // the haptic + dimmed surface marks the tile as "lifted".
        opacityTarget = 0.35;
        scaleTarget = 1.0;
        fadeDuration =
            animate ? const Duration(milliseconds: 150) : Duration.zero;
      } else {
        opacityTarget = 1.0;
        scaleTarget = 1.0;
        fadeDuration = Duration.zero;
      }

      // Slide/resize to the new geometry instead of teleporting: top, left,
      // width AND height all animate (an overlap re-cluster narrows the
      // neighbours; a duration change re-heights) so no dimension ever
      // snaps. A stable key (set by the parent) reuses this element so the
      // delta animates; gated off while zooming/dragging and by reduced
      // motion.
      return AnimatedPositioned(
        top: topPosition,
        left: leftPosition,
        width: widgetWidth,
        height: this.widgetHeight,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: opacityTarget,
          duration: fadeDuration,
          curve: Curves.easeIn,
          child: AnimatedScale(
            scale: scaleTarget,
            duration: fadeDuration,
            alignment: Alignment.center,
            child: Container(
              child: GestureDetector(
                  // A plain tap that was cancelled by a drag attempt
                  // must not open the tile detail (suppressTap is held
                  // briefly after a failed lift); a live drag owns the
                  // surface and swallows the tap too.
                  onTap: suppressTap
                      ? null
                      : () {
                          onTapPreviewTile(tilerEvent!);
                          if (this.widget is TileGridWidget) {
                            if ((this.widget as TileGridWidget).onTap != null) {
                              (this.widget as TileGridWidget).onTap!(
                                  tilerEvent: this.tilerEvent);
                            }
                          }
                        },
                  // Long-press lift + drag (day-content coordinates —
                  // the detector sits inside the scroll content). A
                  // QUICK drag loses the arena to the grid's scroll
                  // view (the long press never elapses) and scrolls
                  // instead of dragging; the long press also fires a
                  // light haptic tick. Non-null callbacks are wired by
                  // the grid ONLY for draggable (Tiler-owned, live,
                  // non-what-if) tiles, so third-party and preview
                  // tiles keep the plain tap/scroll behaviour.
                  onLongPress: onLongPressStart == null
                      ? null
                      : () => _handleLongPressLift(
                          _longPressLiftOffset ?? Offset.zero),
                  onLongPressStart: onLongPressStart == null
                      ? null
                      : (LongPressStartDetails d) {
                          _longPressLiftOffset = d.localPosition;
                        },
                  onLongPressMoveUpdate:
                      onLongPressStart == null ? null : _onLongPressMoveUpdate,
                  onLongPressEnd: onLongPressStart == null
                      ? null
                      : (_) => _onLongPressEnd(),
                  onLongPressCancel:
                      onLongPressStart == null ? null : _onLongPressCancel,
                  child: _TilerEventInnerGridWidget(
                    tilerEvent: tilerEvent!,
                    // The rendered
                    // pixel height decides whether the caption fits.
                    tileHeight: this.widgetHeight,
                    // The drag-to-reschedule persistence outcome
                    // (overlay badge only — never alters size/caption/layout).
                    saveStatus: (this.widget is TileGridWidget)
                        ? ((this.widget as TileGridWidget).saveStatus)
                        : TileSaveStatus.idle,
                    hasDottedBorder: (this.widget is TileGridWidget)
                        ? ((this.widget as TileGridWidget).hasDottedBorder)
                        : false,
                  )),
            ),
          ),
        ),
      );
    }
    if (constant.isDebug) {
      return Container(
        color: colorScheme.onError,
        child: Text("failed to render tiler grid widget"),
      );
    }
    return SizedBox.shrink();
  }
}

class _TilerEventInnerGridWidget extends StatelessWidget {
  final TilerEvent tilerEvent;

  /// Dotted-border treatment for the highlighted
  /// TileCast action tile (same visual as `EnhancedTileCard.hasDottedBorder`).
  final bool hasDottedBorder;

  /// The tile's rendered pixel height.
  /// Below [TileGridWidgetState.collapsedTileHeight] the body collapses to
  /// a plain color bar — the name caption would not fit.
  final double tileHeight;

  /// The drag-to-reschedule persistence outcome — rendered as a small
  /// overlay badge on the tile body. [TileSaveStatus.idle] renders nothing.
  final TileSaveStatus saveStatus;

  _TilerEventInnerGridWidget(
      {required this.tilerEvent,
      this.hasDottedBorder = false,
      required this.tileHeight,
      this.saveStatus = TileSaveStatus.idle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    Color color = Color.fromRGBO(tilerEvent.colorRed ?? 255,
        tilerEvent.colorGreen ?? 255, tilerEvent.colorBlue ?? 255, 1);
    String name = this.tilerEvent.name ?? "--no--name";
    // Pastel card: tile color tinted over surface, full color kept for the
    // leading accent bar, text on the theme's surface tokens.
    final TileCardStyle style = TileCardStyle.from(color, colorScheme);
    const double cardRadius = 12;
    Decoration uiDecoration = BoxDecoration(
      color: style.background,
      borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
      boxShadow: [
        BoxShadow(
          color: tileThemeExtension.shadowSecondary.withValues(alpha: 0.06),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    );
    bool showAccent = true;
    if (tilerEvent.isWhatIf == true) {
      name = AppLocalizations.of(context)!.foreCastTile;
      showAccent = false;
      uiDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: colorScheme.primary,
          width: 1,
        ),
      );
    }

    // The card shell: decoration + clip + the 3px accent bar down the left
    // edge. [content] is null for the collapsed (too-short) bar.
    Widget shell(Widget? content) {
      return Container(
        decoration: uiDecoration,
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showAccent)
              Container(
                key: const Key('daygrid_tile_accent'),
                width: 3,
                color: style.accent,
              ),
            // The caption/time-range decision is made on the TARGET height
            // (`tileHeight`), but the box itself animates there (width/height
            // on AnimatedPositioned) — so mid-transition the box can be
            // shorter than its content. Lay the content out at its natural
            // size and clip, instead of overflowing the Column.
            if (content != null)
              Expanded(
                child: ClipRect(
                  child: TileGridWidgetState.tileCaptionCompact(tileHeight)
                      // Compact: fill the box so the line centres in it.
                      ? content
                      : OverflowBox(
                          alignment: Alignment.topLeft,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: content,
                        ),
                ),
              ),
          ],
        ),
      );
    }

    Widget withHighlight(Widget child) {
      if (!hasDottedBorder) return child;
      // The highlighted TileCast action's dotted border —
      // the same DashedBorderPainter treatment as `EnhancedTileCard`; it
      // survives the collapse because it is the only signal marking the
      // selected TileCast action tile.
      return CustomPaint(
        painter: DashedBorderPainter(
          color: colorScheme.primary,
          strokeWidth: 3,
          dashWidth: 8,
          dashSpace: 4,
          borderRadius: cardRadius,
        ),
        child: child,
      );
    }

    // Too short for the caption —
    // collapse to a plain color bar (no padding, no name).
    Widget body;
    if (TileGridWidgetState.tileContentCollapsed(tileHeight)) {
      body = withHighlight(shell(null));
    } else {
      // No glyph on the card: location/meeting details live in the tap-out
      // bottom sheet (PreviewDetailsTileWidget), not on the grid tile.
      final bool showTimeRange =
          TileGridWidgetState.tileTimeRangeVisible(tileHeight) &&
              tilerEvent.start != null &&
              tilerEvent.end != null;
      String? timeRange;
      if (showTimeRange) {
        final localizations = MaterialLocalizations.of(context);
        String fmt(int ms) => localizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms)),
            );
        timeRange = TileCardStyle.compactTimeRange(
            fmt(tilerEvent.start!), fmt(tilerEvent.end!));
      }
      final bool compact = TileGridWidgetState.tileCaptionCompact(tileHeight);
      final Widget content = Padding(
        // Compact tier: no vertical padding, the single line is centred by
        // the Column below; full tier keeps the 10px top inset.
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8)
            : const EdgeInsets.fromLTRB(8, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: TileGridWidgetState.captionFontSize(tileHeight),
                height: 1.2,
                fontFamily: TileTextStyles.rubikFontName,
                color: style.title,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (timeRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.0,
                    height: 1.2,
                    fontFamily: TileTextStyles.rubikFontName,
                    color: style.subtitle,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      );
      body = withHighlight(shell(content));
    }
    // Overlay-only save badge: a `Stack` (the body is the top-left,
    // non-positioned child, so the tile's size/caption/overlap layout and
    // drag hit-testing are untouched) with a small `Positioned` chip in the
    // top-right. Rendered only when the drag commit has a save state;
    // `TileSaveStatus.idle` returns the bare body.
    if (saveStatus == TileSaveStatus.idle) {
      return body;
    }
    return Stack(
      // `expand` so the (top-left, non-positioned) body fills the full
      // allocated tile slot instead of shrinking to its caption text
      // width — otherwise the `right: 4` badge anchors to the full-width
      // slot and floats off to the side of the narrower box.
      fit: StackFit.expand,
      children: [
        body,
        Positioned(top: 4, right: 4, child: _saveStatusBadge(context)),
      ],
    );
  }

  /// The small save-state chip: a spinner while the commit is in flight,
  /// a check on success, a warning on rollback/failure. No localization —
  /// icon + color only. Overlay-only, so it never changes the tile's
  /// geometry (see `build`).
  Widget _saveStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget child;
    final Color background;
    switch (saveStatus) {
      case TileSaveStatus.saving:
        child = SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurface),
          ),
        );
        background = Colors.white.withValues(alpha: 0.92);
        break;
      case TileSaveStatus.saved:
        child = Icon(
          Icons.check_circle_outline,
          size: 14,
          color: colorScheme.primary,
        );
        background = Colors.white.withValues(alpha: 0.92);
        break;
      case TileSaveStatus.error:
      case TileSaveStatus.idle:
        child = Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: Colors.white,
        );
        background = colorScheme.error;
        break;
    }
    return Container(
      key: const Key('daygrid_tile_save_badge'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
