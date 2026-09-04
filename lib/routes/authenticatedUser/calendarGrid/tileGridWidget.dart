// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';

import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class TileGridWidget extends GridPositionableWidget {
  final TilerEvent tilerEvent;
  final double? tileGridHeight;

  /// P1 (step 1.4): pixels per hour — every position/height of this tile
  /// derives from it (legacy 80 when omitted).
  final double? pxPerHour;

  /// P1 (step 1.4): day context for cross-midnight clamping. When omitted,
  /// the legacy time-of-day positioning applies.
  final DateTime? dayStart;

  /// P1 (step 1.4): responsive tile width (legacy 270 when omitted).
  final double? tileGridWidth;
  final Function? onTap;

  /// P2 (step 2.2): animate the tile's top/left delta on a position change
  /// (true by default). The parent passes `false` while the grid is
  /// zooming/dragging so positions track the controller directly. Reduced
  /// motion is also respected inside the widget.
  final bool? animate;

  /// P2 (step 2.2b): non-null when this tile was newly added and should slide
  /// in (scale + fade) from a corner. The value is the stagger delay applied
  /// before the reveal; `null` means the tile is static (no enter animation —
  /// the initial full-day render and day-swaps pass `null`).
  final Duration? enterDelay;

  /// P2 (step 2.2b): `true` for a fading-out ghost of a removed tile — it
  /// renders at full opacity for one frame, then animates to `0`.
  final bool? exiting;
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
  late ThemeData theme;
  late ColorScheme colorScheme;

  // P2 (step 2.2b): enter/exit animation state.
  /// Enter: false until the stagger delay elapses (only when [TileGridWidget
  /// .enterDelay] is set); drives the 0 -> 1 fade/scale reveal.
  bool _revealed = true;
  /// Exit: flipped one frame after a ghost mounts; drives the 1 -> 0 fade-out.
  bool _fading = false;
  Timer? _enterTimer;

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

  /// P2 (step 2.2b): after the first frame, kick off the enter reveal (after
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

  /// P1 (step 1.4): derives top/height from the effective px-per-hour. With
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
      final startMs = this.tilerEvent!.start ?? 0;
      final endMs = this.tilerEvent!.end ?? startMs;
      // Cross-midnight clamp into the grid day.
      final clampedStart = startMs < dayStartMs ? dayStartMs : startMs;
      final clampedEnd = endMs > dayEndMs ? dayEndMs : endMs;
      if (clampedEnd <= dayStartMs || clampedStart >= dayEndMs) {
        // Fully outside the grid day — the pinned strip (C7) owns this.
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
      // Minimum visible height (minDuration at the current zoom).
      final minPx = (TileGridWidgetState.minDuration.inMilliseconds /
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
    if (!eventChanged && !zoomChanged && !geometryChanged) {
      return; // same tile, same zoom, same geometry: nothing to re-derive.
    }
    // A different tile/zoom/geometry now owns this element (C1 hardening +
    // step 1.4): re-sync the state fields that would otherwise keep
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

      // P2 (step 2.2b): enter (slide-in from a corner) / exit (fade-out) for
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
      final double opacityTarget;
      final double scaleTarget;
      final Duration fadeDuration;
      if (isExiting) {
        opacityTarget = _fading ? 0.0 : 1.0;
        scaleTarget = 1.0;
        fadeDuration = animate
            ? const Duration(milliseconds: 200)
            : Duration.zero;
      } else if (hasEnter) {
        opacityTarget = _revealed ? 1.0 : (animate ? 0.0 : 1.0);
        scaleTarget = _revealed ? 1.0 : (animate ? 0.86 : 1.0);
        fadeDuration = animate
            ? const Duration(milliseconds: 200)
            : Duration.zero;
      } else {
        opacityTarget = 1.0;
        scaleTarget = 1.0;
        fadeDuration = Duration.zero;
      }

      // P2 (step 2.2): slide to the new top/left instead of teleporting. A
      // stable key (set by the parent) reuses this element so the delta
      // animates; gated off while zooming/dragging and by reduced motion.
      return AnimatedPositioned(
        top: topPosition,
        left: leftPosition,
        duration:
            animate ? const Duration(milliseconds: 300) : Duration.zero,
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
              height: this.widgetHeight,
              width: widgetWidth,
              child: InkWell(
                  onTap: () {
                    onTapPreviewTile(tilerEvent!);
                    if (this.widget is TileGridWidget) {
                      if ((this.widget as TileGridWidget).onTap != null) {
                        (this.widget as TileGridWidget).onTap!(
                            tilerEvent: this.tilerEvent);
                      }
                    }
                  },
                  child: _TilerEventInnerGridWidget(tilerEvent: tilerEvent!)),
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

  _TilerEventInnerGridWidget({required this.tilerEvent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    EdgeInsets gridPadding = EdgeInsets.all(10);
    if (this.tilerEvent.duration.inMilliseconds <=
        TileGridWidgetState.minDuration.inMilliseconds) {
      gridPadding = EdgeInsets.fromLTRB(10, 5, 0, 0);
    }
    Color color = Color.fromRGBO(tilerEvent.colorRed ?? 255,
        tilerEvent.colorGreen ?? 255, tilerEvent.colorGreen ?? 255, 1);
    String name = this.tilerEvent.name ?? "--no--name";
    Decoration uiDecoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      boxShadow: [
        BoxShadow(
          color: tileThemeExtension.shadowSecondary.withValues(alpha: 0.1),
          spreadRadius: 0.5,
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
    if (tilerEvent.isWhatIf == true) {
      color = Utility.randomColor;
      name = AppLocalizations.of(context)!.foreCastTile;
      uiDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: colorScheme.primary,
          width: 1,
        ),
      );
    }
    return Container(
        decoration: uiDecoration,
        padding: gridPadding,
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: new TextStyle(
            fontSize: 13.0,
            fontFamily: TileTextStyles.rubikFontName,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ));
  }
}
