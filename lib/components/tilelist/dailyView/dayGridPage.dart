import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/daySummaryHeader.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridBannerStrip.dart';
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

  /// Optional list-mode body (today's [EnhancedWithinNowBatch]). When
  /// omitted, list mode renders an [EnhancedTileBatch] built from [tiles].
  final Widget? listView;

  const DayGridPage({
    super.key,
    required this.dayIndex,
    required this.tiles,
    this.endOfDayTime,
    this.onEndOfDayUpdated,
    this.listView,
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

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<DailyViewLayoutCubit>().state;
    if (layout == DailyViewLayout.grid) {
      final parityTiles = gridTiles(tiles);
      return Column(
        children: [
          // C17: the grid-mode day-summary entry point. Today's day-page only
          // mounts the (unmodified) [DaySummaryHeader] list mode surfaces, so
          // tapping it opens TodayStatusScreen from grid mode too — same
          // TimelineSummary / ScheduleSummaryBloc pipeline. Other days get
          // no header (the "show it on every day" case is a separate,
          // deferred decision).
          if (dayIndex == Utility.currentTime().universalDayIndex)
            DaySummaryHeader(
              date: Utility.getTimeFromIndex(dayIndex),
              dayData: TimelineSummary()..dayIndex = dayIndex,
            ),
          // Compact alert strip — the list-mode detectors
          // surfaced as a condensed chip row above the grid.
          DayGridBannerStrip(tiles: tiles),
          // Pinned >=16h / all-day tiles — excluded from
          // the grid timeline, kept visible here.
          DayGridPinnedHeader(tiles: parityTiles),
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
              // The page's calendar day, so an empty day can
              // still tap-to-add (the grid derives its own date only from
              // tiles, which is null on an empty day).
              day: Utility.getTimeFromIndex(dayIndex),
              // Scope the per-tile keys to this day so a tile
              // never re-animates (flies) across a day-page swap.
              dayKey: 'day_$dayIndex',
            ),
          ),
        ],
      );
    }
    if (listView != null) {
      return listView!;
    }
    return EnhancedTileBatch(
      dayIndex: dayIndex,
      tiles: tiles,
      showEnhancedCards: true,
      showTravelConnectors: true,
      showTimelineMarkers: true,
      endOfDayTime: endOfDayTime,
      onEndOfDayUpdated: onEndOfDayUpdated,
    );
  }
}
