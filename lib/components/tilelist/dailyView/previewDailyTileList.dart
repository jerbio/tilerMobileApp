import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedWithinNowBatch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/data/timeline.dart';

class PreviewDailyTileList extends TileList {
  final DateTime displayDate;
  PreviewDailyTileList({Key? key, required this.displayDate}) : super(key: key);

  @override
  _PreviewDailyTileListState createState() => _PreviewDailyTileListState();
}

class _PreviewDailyTileListState extends TileListState {
  @override
  PreviewDailyTileList get widget => super.widget as PreviewDailyTileList;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildDayWidget(List<SubCalendarEvent> dayTiles) {
    DateTime now = Utility.currentTime();

    bool isToday = widget.displayDate.dayDate.millisecondsSinceEpoch ==
        now.dayDate.millisecondsSinceEpoch;

    // P2 (step 2.4, §6.7): the preview follows the user's layout choice —
    // grid mode renders a read-only DayGridWidget over the preview tiles
    // (same C7 pinned header as the live page; the C3 banner strip is
    // suppressed because TileCast's own header sheet / action list is the
    // chrome there). List mode keeps the existing EnhancedTileBatch /
    // EnhancedWithinNowBatch path below.
    final layout = context.watch<DailyViewLayoutCubit>().state;
    if (layout == DailyViewLayout.grid) {
      // P2 (step 2.4, §6.7): preview grid input keeps non-viable tiles so
      // the user can see *why* the proposal conflicts (contrast §6.1 parity
      // filtering for the live grid).
      final parityTiles = DayGridPage.previewGridTiles(dayTiles);
      final dayIndex = Utility.getDayIndex(widget.displayDate);
      return Column(
        children: [
          // C7: pinned >=16h / all-day preview tiles — excluded from the
          // grid timeline, kept visible here.
          DayGridPinnedHeader(tiles: parityTiles),
          // The grid fills the remaining height; its internal scroll view
          // keeps the day pannable.
          Expanded(
            child: DayGridWidget(
              // Stable element identity across TileCast carousel pages: the
              // page swipe changes ONLY selectedActionEntityId, so the grid
              // animates the highlight + auto-scroll instead of remounting
              // (§6.7). Preview tiles keep stable keys across pages since
              // every page shows the same schedule.
              key: const ValueKey<String>('daygrid_preview'),
              tiles: parityTiles,
              day: Utility.getTimeFromIndex(dayIndex),
              dayKey: 'preview',
              // P2 (step 2.4): read-only TileCast preview — no tap-to-add /
              // drag / ScheduleBloc refresh; zoom persists are skipped.
              preview: true,
              selectedActionEntityId:
                  context.read<VibeChatBloc>().state.selectedActionEntityId,
            ),
          ),
        ],
      );
    }

    if (isToday) {
      List<TilerEvent> elapsedTiles = [];
      List<TilerEvent> upcomingTiles = [];

      for (TilerEvent event in dayTiles) {
        if (event.endTime.millisecondsSinceEpoch > now.millisecondsSinceEpoch) {
          upcomingTiles.add(event);
        } else {
          elapsedTiles.add(event);
        }
      }

      return EnhancedWithinNowBatch(
        key: ValueKey("today_batch"),
        tiles: [...elapsedTiles, ...upcomingTiles],
        preview: true,
        selectedActionEntityId:
            context.read<VibeChatBloc>().state.selectedActionEntityId,
        endOfDayTime: endOfDayDateTimeFor(now, Utility.defaultEndOfDay),
      );
    } else {
      int dayIndex = Utility.getDayIndex(widget.displayDate);

      return EnhancedTileBatch(
        dayIndex: dayIndex,
        tiles: dayTiles,
        key: ValueKey("day_batch_$dayIndex"),
        showEnhancedCards: true,
        showTravelConnectors: true,
        showTimelineMarkers: true,
        preview: true,
        selectedActionEntityId:
            context.read<VibeChatBloc>().state.selectedActionEntityId,
        endOfDayTime:
            endOfDayDateTimeFor(widget.displayDate, Utility.defaultEndOfDay),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final tiles = (state.previewTiles ?? [])
            .where((tile) => tile.isInterfering(Timeline.fromDateTime(
                  widget.displayDate.dayDate,
                  widget.displayDate.dayDate.add(Duration(days: 1)),
                )))
            .toList();
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: colorScheme.surfaceContainerLowest),
          child: state.step == VibeChatStep.loadingPreview
              ? PendingWidget()
              : _buildDayWidget(tiles),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
