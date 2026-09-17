import 'package:flutter/material.dart';
import 'package:tiler_app/data/executionEnums.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileCardStyle.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Which side of the tile a travel band attaches to.
enum TravelBandKind {
  /// The pre-travel band: `height(travelTimeBefore)` immediately above
  /// the tile top (the grid-mode `TravelConnector`).
  pre,

  /// The post/return band: `height(travelTimeAfter)` immediately below
  /// the tile bottom (the grid-mode `ReturnConnector` travel section).
  post,
}

/// Pure geometry for the DayGrid travel/return bands.
///
/// The list-mode `TravelConnector` / `ReturnConnector` travel times are
/// drawn as thin bands in the grid's left gutter:
///   * the [TravelBandKind.pre] band spans `height(travelTimeBefore)`
///     immediately above the tile top,
///   * the [TravelBandKind.post] band spans `height(travelTimeAfter)`
///     immediately below the tile bottom.
///
/// Both bands clamp into the day `[0, 24h]` -- travel that starts before
/// midnight is clipped at the day top and return travel that runs past
/// midnight is clipped at the day bottom (the remainder belongs to the
/// neighbouring day's grid).
class TravelBand {
  final TravelBandKind kind;

  /// Band top in day-content px (0 at midnight of the grid day).
  final double top;

  /// Band height in day-content px.
  final double height;

  const TravelBand(this.kind, this.top, this.height);

  /// ms -> px at [pxPerHour] (the same mapping as the grid layout:
  /// `top(t) = pxPerHour * ms / msPerHour`).
  static double msToPx(double ms, double pxPerHour) =>
      ms / Duration.millisecondsPerHour * pxPerHour;

  /// The bands to render for [tile] on the day starting at [dayStart] at
  /// [pxPerHour] pixels per hour. Empty when the tile has no positive
  /// travel time, or when a band would fall fully outside the day.
  static List<TravelBand> bandsForTile({
    required SubCalendarEvent tile,
    required DateTime dayStart,
    required double pxPerHour,
  }) {
    assert(pxPerHour.isFinite && pxPerHour > 0,
        'TravelBand:: invalid pxPerHour $pxPerHour');
    final dayStartMs = dayStart.millisecondsSinceEpoch;
    final dayEndMs = dayStartMs + Duration.millisecondsPerDay;
    final dayPx = 24 * pxPerHour;

    final startMs = tile.start ?? dayStartMs;
    final endMs = tile.end ?? startMs;
    // Cross-midnight clamp, mirroring TileGridWidget._recomputePosition.
    final clampedStart = startMs < dayStartMs ? dayStartMs : startMs;
    final clampedEnd = endMs > dayEndMs ? dayEndMs : endMs;
    final tileTop =
        ((clampedStart - dayStartMs) / Duration.millisecondsPerHour) *
            pxPerHour;
    final tileBottom =
        ((clampedEnd - dayStartMs) / Duration.millisecondsPerHour) * pxPerHour;

    final List<TravelBand> bands = <TravelBand>[];

    // Pre-travel band: height(travelTimeBefore) immediately above the
    // tile top, clipped at the day top.
    final preMs = tile.travelTimeBefore;
    if (preMs != null && preMs > 0) {
      final top = (tileTop - msToPx(preMs, pxPerHour)).clamp(0.0, tileTop);
      final height = tileTop - top;
      if (height > 0) {
        bands.add(TravelBand(TravelBandKind.pre, top, height));
      }
    }

    // Post/return band: height(travelTimeAfter) immediately below the
    // tile bottom, clipped at the day bottom.
    final postMs = tile.travelTimeAfter;
    if (postMs != null && postMs > 0) {
      final bottom =
          (tileBottom + msToPx(postMs, pxPerHour)).clamp(tileBottom, dayPx);
      final height = bottom - tileBottom;
      if (height > 0) {
        bands.add(TravelBand(TravelBandKind.post, tileBottom, height));
      }
    }

    return bands;
  }

  /// Whether [tile]'s post (after-travel) band is superseded by the NEXT
  /// tile's pre (before-travel) band: A's after-travel and B's before-travel
  /// describe the same gap, so it must render once. Mirrors list mode,
  /// where the connector between two tiles is always the destination's
  /// before-travel and after-travel appears only for the last tile (the
  /// return home).
  ///
  /// "Next" is the first tile in [sortedTiles] (ascending start) whose
  /// start is at/after [tile]'s end — an overlapping later tile is not next
  /// (its pre band sits inside [tile], not in the gap after it).
  static bool postBandSuperseded(
      SubCalendarEvent tile, List<SubCalendarEvent> sortedTiles) {
    final int? end = tile.end;
    if (end == null) return false;
    for (final other in sortedTiles) {
      if (identical(other, tile) || other.uniqueId == tile.uniqueId) continue;
      final int? otherStart = other.start;
      if (otherStart == null || otherStart < end) continue;
      final double? before = other.travelTimeBefore;
      return before != null && before > 0;
    }
    return false;
  }

  /// The "leave by" time of a pre-travel band (tile start minus the
  /// travel time) -- the same rule as `TravelConnector._getLeaveByTime`.
  /// `null` when the tile has no positive travel time or no start.
  static DateTime? leaveByTime(SubCalendarEvent tile) {
    final travelTime = tile.travelTimeBefore;
    final tileStart = tile.start;
    if (travelTime == null || travelTime <= 0 || tileStart == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      (tileStart - travelTime).toInt(),
    );
  }
}

/// The grid-mode rendering of the list-mode `TravelConnector` (pre) /
/// `ReturnConnector` travel section (post): a thin segment in the left
/// gutter (gradient hairline + travel-medium icon) with the same
/// tap-to-directions behaviour as the list connectors.
///
/// Zoom-aware tiers by the band's REAL height — a band NEVER inflates into
/// a neighbouring tile's box (fit-the-gap):
///   * `>= 56px` — a full-column pastel card inside the tile column
///     (`Travel • 24 min` + the travel window, e.g. `2:00 – 2:24 PM`);
///   * `>= 18px` — a compact single-line card inside the tile column
///     (`Travel • 24 min`), at the gap's real height;
///   * otherwise — a compact MARKER (travel-medium icon + hairline) in the
///     grid's dedicated right-hand travel rail, centred on the gap. The rail
///     sits outside every tile column (and away from the hour labels), so
///     the marker can never be covered by, or cover, a tile.
/// Cards are drawn in the grid's travel layer BENEATH the tiles and never
/// enter the overlap layout (no-snap rule 6).
class TravelBandWidget extends StatelessWidget {
  final SubCalendarEvent tile;
  final TravelBandKind kind;

  /// The band's top (px from the day top) and height (px), from
  /// [TravelBand.bandsForTile].
  final double top;
  final double height;

  /// The tile's column left (px) -- the band's gutter segment sits just
  /// left of it.
  final double left;

  /// The tile's column width (px) -- the card tiers stay inside it.
  final double width;

  /// Left edge (px) of the grid's right-hand travel rail — where the
  /// compact marker renders when the gap is too short for a card. Defaults
  /// to just right of the column.
  final double? railLeft;

  /// The previously scheduled tile (for the pre band only) -- the
  /// "from" location fallback, the same role as `TravelConnector`'s
  /// `fromTile`. `null` for the first tile of the day and for post bands.
  final SubCalendarEvent? fromTile;

  /// Animate the band's top/left delta on a position change (true by
  /// default). The parent passes `false` while the grid is zooming so
  /// positions track the controller directly; reduced motion is also
  /// respected inside the widget.
  final bool animate;

  /// Dim the band while a drag (or its commit request) is in flight —
  /// the band's real travel times depend on the tile's new neighbours
  /// and only the server knows post-`EvaluateSchedule` (the list-mode
  /// "recalculating" treatment, without fabricating estimates).
  final bool dimmed;

  /// The band height (px) at which the band expands from the gutter
  /// icon + hairline tier to the full-column card.
  static const double expandedHeightThreshold = 56;

  /// Test/spotlight key for the in-column card (compact or full).
  static const Key cardKey = ValueKey('daygrid_travel_band_card');

  /// The band's REAL height (px) from which the compact single-line card
  /// fits inside the gap (rendered at the gap's real height).
  static const double compactCardHeightThreshold = 18;

  /// The rail marker's box height (px): the 14px icon with breathing room.
  /// A marker for a shorter gap is centred on the gap inside this box.
  static const double iconHeightThreshold = 18;

  /// Width of the right-hand travel rail / the compact marker (14px icon +
  /// 2px gap + 2px hairline).
  static const double gutterSpan = 20;

  const TravelBandWidget({
    Key? key,
    required this.tile,
    required this.kind,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    this.railLeft,
    this.fromTile,
    this.animate = true,
    this.dimmed = false,
  }) : super(key: key);

  // ---------------------------------------------------------------------------
  // Data helpers (mirror the list-mode connectors)
  // ---------------------------------------------------------------------------

  TravelData? get _travelData => kind == TravelBandKind.pre
      ? tile.travelDetail?.before
      : tile.travelDetail?.after;

  TravelMedium get _travelMedium =>
      TravelMediumExtension.fromString(_travelData?.travelMedium);

  bool get _isTardy => tile.isTardy ?? false;

  /// True when the return destination is the user's home location -- the
  /// same rule as `ReturnConnector._isHome` (no directions offered for
  /// home).
  bool get _isHome =>
      kind == TravelBandKind.post &&
      _destination?.description?.toLowerCase() == Location.homeLocationNickName;

  Location? get _origin {
    final data = _travelData;
    if (kind == TravelBandKind.pre) {
      // TravelConnector: `before.startLocation ?? fromTile.location`.
      return data?.startLocation ?? fromTile?.location;
    }
    // ReturnConnector: `after.startLocation ?? lastTile.location`.
    return data?.startLocation ?? tile.location;
  }

  Location? get _destination {
    final data = _travelData;
    if (kind == TravelBandKind.pre) {
      // TravelConnector: `before.endLocation ?? toTile.location`.
      return data?.endLocation ?? tile.location;
    }
    // ReturnConnector: `after.endLocation`.
    return data?.endLocation;
  }

  /// True when the band can open Google Maps -- a known, non-default
  /// destination, and (for the return band) not the home location
  /// (`ReturnConnector._canOpenMaps`).
  bool get _canOpenDirections {
    final destination = _destination;
    if (destination?.isNotNullAndNotDefault != true) {
      return false;
    }
    if (kind == TravelBandKind.post && _isHome) {
      return false;
    }
    return true;
  }

  /// The duration shown in the expanded pill. ReturnConnector prefers
  /// the travel detail's duration and falls back to the tile field.
  double? get _durationMs {
    final data = _travelData;
    return data?.duration ??
        (kind == TravelBandKind.pre
            ? tile.travelTimeBefore
            : tile.travelTimeAfter);
  }

  /// The same duration formatting as `TravelConnector._formatDuration`
  /// (l10n minutes / hours / hours+minutes).
  static String formatDuration(BuildContext context, double? durationMs) {
    if (durationMs == null || durationMs <= 0) return '';
    final l10n = AppLocalizations.of(context)!;
    final minutes = (durationMs / 60000).round();
    if (minutes < 60) {
      return l10n.travelDurationMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return l10n.travelDurationHours(hours);
    }
    return l10n.travelDurationHoursMinutes(hours, remainingMinutes);
  }

  /// The travel window this band covers: pre = `[tile.start - d, tile.start]`,
  /// post = `[tile.end, tile.end + d]`. `null` without a tile bound.
  (int, int)? get _windowMs {
    final d = _durationMs;
    if (d == null || d <= 0) return null;
    if (kind == TravelBandKind.pre) {
      final end = tile.start;
      if (end == null) return null;
      return ((end - d).round(), end);
    }
    final start = tile.end;
    if (start == null) return null;
    return (start, (start + d).round());
  }

  /// `Travel • 24 min` — the card title.
  static String cardTitle(BuildContext context, double? durationMs) {
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.travel} • ${formatDuration(context, durationMs)}';
  }

  // ---------------------------------------------------------------------------
  // Tap-to-directions (mirror TravelConnector / ReturnConnector)
  // ---------------------------------------------------------------------------

  Future<void> _onTap() async {
    await AnalysticsSignal.send(
      'daygrid_travel_band_tap',
      additionalInfo: {
        'kind': kind.name,
        'tileId': tile.uniqueId,
        'travelMode': _travelMedium.name,
      },
    );
    await _launchDirections();
  }

  /// Launch Google Maps directions -- the same URL construction as
  /// `TravelConnector._launchGoogleMaps` / `ReturnConnector._launchMaps`
  /// (address over coordinates, travel mode from the travel detail).
  Future<void> _launchDirections() async {
    if (!_canOpenDirections) {
      return;
    }
    final destination = _destination!;

    String dest;
    if (destination.address?.isNotEmpty == true) {
      dest = Uri.encodeComponent(destination.address!);
    } else {
      dest = '${destination.latitude},${destination.longitude}';
    }

    String? originParam;
    final origin = _origin;
    if (origin != null && origin.isNotNullAndNotDefault) {
      if (origin.address?.isNotEmpty == true) {
        originParam = Uri.encodeComponent(origin.address!);
      } else {
        originParam = '${origin.latitude},${origin.longitude}';
      }
    }

    final travelMode = _travelMedium.googleMapsMode;
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=$travelMode';
    if (originParam != null) {
      url += '&origin=$originParam';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (height <= 0 || width <= 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final anim = animate && !reduce;

    // Fit-the-gap: a card renders only when the REAL gap has room for it;
    // anything shorter becomes a rail marker centred on the gap. Nothing
    // ever inflates into a neighbouring tile's box.
    final expanded = height >= expandedHeightThreshold;
    final compactCard = !expanded && height >= compactCardHeightThreshold;
    final showCard = expanded || compactCard;
    final double effectiveHeight = showCard
        ? height
        : (height >= iconHeightThreshold ? height : iconHeightThreshold);
    final double effectiveTop = showCard
        ? top
        : (top + height / 2 - effectiveHeight / 2).clamp(0.0, double.infinity);
    final double boxLeft = showCard ? left : (railLeft ?? left + width);
    final double boxWidth = showCard ? width : gutterSpan;

    // Same colour rule as the design: `TileColors.travel`,
    // `TileColors.late` when the tile is tardy.
    final color = _isTardy ? TileColors.late : TileColors.travel;
    // ReturnConnector shows the home icon instead of the medium icon
    // when the return destination is home.
    final icon = _isHome ? Icons.home : _travelMedium.icon;

    // The gutter hairline: the pre band fades INTO the tile top (strong
    // near the tile), the post band fades OUT from the tile bottom
    // (strong near the tile) -- the gradient language of the list
    // connectors.
    final line = Container(
      width: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: kind == TravelBandKind.pre
              ? [
                  colorScheme.outline.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.5),
                ]
              : [
                  color.withValues(alpha: 0.5),
                  colorScheme.outline.withValues(alpha: 0.3),
                ],
        ),
      ),
    );

    // The expanded full-column card (mock tier): pastel band inside the
    // tile column with the travel-medium glyph, `Travel • N min`, and the
    // travel window. Replaces the gutter hairline + icon at this tier.
    Widget? card;
    if (showCard) {
      final window = _windowMs;
      String? windowLabel;
      if (expanded && window != null) {
        final localizations = MaterialLocalizations.of(context);
        String fmt(int ms) => localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms)));
        windowLabel =
            TileCardStyle.compactTimeRange(fmt(window.$1), fmt(window.$2));
      }
      card = Container(
        key: cardKey,
        padding: expanded
            ? const EdgeInsets.fromLTRB(8, 6, 10, 6)
            : const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
              color.withValues(alpha: 0.16), colorScheme.surface),
          borderRadius: BorderRadius.circular(expanded ? 12 : 8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: expanded ? 16 : 13, color: color),
            SizedBox(width: expanded ? 8 : 5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardTitle(context, _durationMs),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: expanded ? 13 : 11,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (windowLabel != null)
                    Text(
                      windowLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 11,
                        color: _isTardy
                            ? TileColors.late
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (_canOpenDirections) ...[
              const SizedBox(width: 6),
              Icon(Icons.navigation_outlined, size: 14, color: color),
            ],
          ],
        ),
      );
    }

    // Card tiers: the box IS the tile column. Marker tier: the box is the
    // rail slot (outside every column).
    return AnimatedPositioned(
      top: effectiveTop,
      left: boxLeft,
      width: boxWidth,
      height: effectiveHeight,
      duration: anim ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeInOutCubic,
      // A non-tappable band (no valid destination) leaves `onTap` null so
      // taps fall through to the grid's tap-to-add background. Dimmed
      // while a drag (or its commit request) is in flight — the real
      // travel times only settle once the server re-evaluates.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canOpenDirections ? _onTap : null,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              // Marker tier (icon + hairline) in the rail — below the card
              // tiers. The hairline spans the REAL gap (min 2px), centred.
              if (!showCard)
                Positioned(
                  right: 0,
                  top: ((effectiveHeight - height) / 2)
                      .clamp(0.0, effectiveHeight),
                  width: 2,
                  height: height < 2 ? 2 : height,
                  child: line,
                ),
              if (!showCard)
                Positioned(
                  right: 4,
                  top: (effectiveHeight - 14) / 2,
                  width: 14,
                  height: 14,
                  child: Icon(icon, size: 14, color: color),
                ),
              if (card != null)
                Positioned(
                  left: 0,
                  top: 0,
                  width: width,
                  height: effectiveHeight,
                  child: card,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
