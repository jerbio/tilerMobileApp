import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/components/dayGridPageBody.dart';
import 'package:tiler_app/components/dayGridAlertRows.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/util.dart';

/// One day page of the Daily carousel.
///
/// Renders the day either as the list view ([EnhancedTileBatch]) or the
/// day grid ([DayGridWidget]) depending on [DailyViewLayoutCubit]. The grid
/// input is parity-filtered with [gridTiles] so grid users see exactly the
/// tiles list users see in the main list (declined / pending-RSVP /
/// non-viable excluded; tiler-sourced tiles always included).
class DayGridPage extends StatelessWidget {
  final int dayIndex;
  final List<TilerEvent> tiles;
  final DateTime? endOfDayTime;
  final VoidCallback? onEndOfDayUpdated;

  /// Optional list-mode body builder (today's [EnhancedWithinNowBatch]),
  /// called with the day's tiles AFTER the content filter (P7) is applied
  /// and whether the between-tiles widgets (travel connectors, free-time
  /// gaps) should render — `false` while filtered. When omitted, list mode
  /// renders an [EnhancedTileBatch] built from the (filtered) [tiles].
  final Widget Function(List<TilerEvent> tiles, bool showConnectors)?
      listViewBuilder;

  /// List mode: whether the non-today list page renders its own day-summary
  /// block. `false` under the Daily top bar (which already shows the day
  /// pill + summary button).
  final bool showDaySummaryHeader;

  const DayGridPage({
    super.key,
    required this.dayIndex,
    required this.tiles,
    this.endOfDayTime,
    this.onEndOfDayUpdated,
    this.listViewBuilder,
    this.showDaySummaryHeader = true,
  });

  /// Parity filter — mirrors [EnhancedTileBatch]'s main-list rules:
  /// a tile renders when it is NOT pending-RSVP, NOT declined
  /// (third-party only), and viable. Tiler-sourced tiles are never
  /// filtered by the RSVP rules.
  static List<SubCalendarEvent> gridTiles(List<TilerEvent> tiles) {
    final renderable = <SubCalendarEvent>[];
    for (final eachTile in tiles) {
      if (eachTile.id == null) continue;
      final subEvent = eachTile is SubCalendarEvent ? eachTile : null;
      final isViable = subEvent?.isViable ?? true;
      final isFromTiler = eachTile.isFromTiler;
      final rsvpStatus = subEvent?.rsvp;
      final isPendingRsvp = !isFromTiler &&
          (rsvpStatus == RsvpStatus.needsAction ||
              rsvpStatus == RsvpStatus.tentative);
      final isDeclined = !isFromTiler && rsvpStatus == RsvpStatus.declined;
      final shouldShowInMainList = !isPendingRsvp && !isDeclined;
      if (shouldShowInMainList && isViable && subEvent != null) {
        renderable.add(subEvent);
      }
    }
    return renderable;
  }

  /// Preview (TileCast) grid input — same RSVP /
  /// declined parity filter as [gridTiles] but NON-VIABLE tiles are kept.
  /// TileCast surfaces non-viable placements so the user can see *why* the
  /// proposal conflicts; the grid renders them with non-viable styling
  /// (contrast the parity filtering used by the live grid).
  static List<SubCalendarEvent> previewGridTiles(List<TilerEvent> tiles) {
    final renderable = <SubCalendarEvent>[];
    for (final eachTile in tiles) {
      if (eachTile.id == null) continue;
      final subEvent = eachTile is SubCalendarEvent ? eachTile : null;
      if (subEvent == null) continue;
      final isFromTiler = eachTile.isFromTiler;
      final rsvpStatus = subEvent.rsvp;
      final isPendingRsvp = !isFromTiler &&
          (rsvpStatus == RsvpStatus.needsAction ||
              rsvpStatus == RsvpStatus.tentative);
      final isDeclined = !isFromTiler && rsvpStatus == RsvpStatus.declined;
      final shouldShowInMainList = !isPendingRsvp && !isDeclined;
      // NOTE: non-viable tiles are intentionally NOT filtered here.
      if (shouldShowInMainList) {
        renderable.add(subEvent);
      }
    }
    return renderable;
  }

  /// The active content filter (P7). `all` when no [DayContentFilterCubit]
  /// is provided (isolated hosts), so the page degrades to unfiltered.
  static DayContentFilter activeFilter(BuildContext context) {
    try {
      return context.watch<DayContentFilterCubit>().state;
    } catch (_) {
      return DayContentFilter.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<DailyViewLayoutCubit>().state;
    // P7 (C34): the filter shapes the DAY CONTENT only. The alert rows keep
    // the unfiltered set so the chrome always reflects the whole day; the
    // filtered set feeds the grid, the pinned card and the list.
    final DayContentFilter filter = activeFilter(context);
    final List<TilerEvent> visibleTiles = filter.apply(tiles);
    // No between-tiles widgets while filtered — travel bands/connectors and
    // free-time gaps are computed against the rendered set, so with tiles
    // hidden they would mislead (travel to a hidden tile, "free" time a
    // hidden tile occupies). A filtered view is about the tiles themselves.
    final bool showConnectors = filter == DayContentFilter.all;
    if (layout == DailyViewLayout.grid) {
      final parityTiles = gridTiles(visibleTiles);
      final DateTime day = Utility.getTimeFromIndex(dayIndex);
      final DayGridScope? scope = DayGridScope.maybeOf(context);
      return Column(
        children: [
          // Conflict / RSVP rows, in-flow (list mode has inline banners of
          // its own). The unfiltered day tiles feed the alert detectors.
          DayGridAlertRows(tiles: tiles),
          // Pinned >=16h / all-day tiles — excluded from
          // the grid timeline, kept visible here (outside the scroll, so it
          // stays put). AnimatedSize: the one chrome element that can
          // resize the grid viewport does so smoothly (no-snap rule 3).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: DayGridPinnedHeader(tiles: parityTiles),
          ),
          // The grid fills the remaining height (the page is hosted in a
          // bounded viewport); its internal scroll view keeps the day
          // pannable.
          Expanded(
            child: DayGridWidget(
              // Stable element identity: keeps the grid's enter/exit/position
              // transition state across rebuilds so an in-place
              // schedule update animates instead of remounting the whole grid.
              key: ValueKey<String>('daygrid_$dayIndex'),
              tiles: parityTiles,
              // The shared, already-restored zoom (see DayGridScope) — a
              // page never re-lays its tiles out on mount, and zoom is
              // live across days. Null (isolated tests) → grid-owned.
              controller: scope?.controller,
              // The page's calendar day, so an empty day can
              // still tap-to-add (the grid derives its own date only from
              // tiles, which is null on an empty day).
              day: day,
              // Scope the per-tile keys to this day so a tile
              // never re-animates (flies) across a day-page swap.
              dayKey: 'day_$dayIndex',
              showTravel: showConnectors,
              // The occupancy rail (P9) reads the whole day, not the
              // filtered set (C37): under `Tiles` it still shows the gaps
              // the hidden blocks claim.
              railTiles: tiles,
            ),
          ),
        ],
      );
    }
    if (listViewBuilder != null) {
      return listViewBuilder!(visibleTiles, showConnectors);
    }
    return EnhancedTileBatch(
      dayIndex: dayIndex,
      tiles: visibleTiles,
      showEnhancedCards: true,
      showTravelConnectors: showConnectors,
      showFreeSlots: showConnectors,
      showTimelineMarkers: true,
      showDaySummaryHeader: showDaySummaryHeader,
      endOfDayTime: endOfDayTime,
      onEndOfDayUpdated: onEndOfDayUpdated,
    );
  }
}
