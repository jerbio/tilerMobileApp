import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridBannerStrip.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';

/// One day page of the Daily carousel (P1, step 1.5).
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

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<DailyViewLayoutCubit>().state;
    if (layout == DailyViewLayout.grid) {
      final parityTiles = gridTiles(tiles);
      return Column(
        children: [
          // Step 1.7 (C3): compact alert strip — the list-mode detectors
          // surfaced as a condensed chip row above the grid.
          DayGridBannerStrip(tiles: tiles),
          // Step 1.7 (C7): pinned >=16h / all-day tiles — excluded from
          // the grid timeline, kept visible here.
          DayGridPinnedHeader(tiles: parityTiles),
          // The grid fills the remaining height (the page is hosted in a
          // bounded viewport); its internal scroll view keeps the day
          // pannable.
          Expanded(child: DayGridWidget(tiles: parityTiles)),
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
