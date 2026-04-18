import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedWithinNowBatch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/data/timeline.dart';

class PreviewDailyTileList extends TileList {
  final DateTime displayDate;
  PreviewDailyTileList({
    Key? key,
    required this.displayDate
  }) : super(key: key);

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
        selectedActionEntityId: context.read<VibeChatBloc>().state.selectedActionEntityId
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
        selectedActionEntityId: context.read<VibeChatBloc>().state.selectedActionEntityId
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final tiles = (state.previewTiles ?? []).where((tile) =>
            tile.isInterfering(Timeline.fromDateTime(
              widget.displayDate.dayDate,
              widget.displayDate.dayDate.add(Duration(days: 1)),
            ))
        ).toList();
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