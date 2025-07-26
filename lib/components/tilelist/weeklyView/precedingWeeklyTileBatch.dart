import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/weeklyDetailsTile.dart';
import 'package:tiler_app/components/tileUI/weeklyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';


class PrecedingWeeklyTileBatch extends TileBatch {
  PrecedingWeeklyTileBatch({required int dayIndex,List<TilerEvent>? tiles, Key? key})
      : super(dayIndex: dayIndex,tiles: tiles, key: key);

  @override
  TileBatchState createState() => _PrecedingWeeklyTileBatchState();
}

class _PrecedingWeeklyTileBatchState extends TileBatchState {
  Widget? retValue;
  TimelineSummary? dayData = TimelineSummary();
  List<Widget> childrenColumnWidgets = [];
  late ThemeData theme;
  late ColorScheme colorScheme;
  @override
  void initState() {
    super.initState();
    if (this.widget.dayIndex != null) {
      dayData!.dayIndex = this.widget.dayIndex;
    }
  }
  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = (screenWidth-10)/7;
    return BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          childrenColumnWidgets.clear();
          if (state is ScheduleDaySummaryLoaded) {
            TimelineSummary? latestDayData = state.dayData!
                .where((timelineSummary) => timelineSummary.dayIndex == dayData?.dayIndex)
                .singleOrNull;
            if (latestDayData != null) {
              dayData = latestDayData;
            }
          }
          List<TilerEvent> allEvents = [];
          if(dayData!.complete !=null) {
            allEvents.addAll(dayData!.complete!);
          }
          if (widget.tiles != null) {
            allEvents.addAll(widget.tiles!);
          }
          allEvents.sort((a, b) => a.start!.compareTo(b.start!));
          if (allEvents.isNotEmpty) {
            allEvents.forEach((tile) {
              childrenColumnWidgets.add(WeeklyTileWidget(
                  subEvent: tile,
                  isPreceding: true,
                  onTap: () {
                    if(tile.name == null || tile.name!.isEmpty) return;
                    tile.isComplete?onTapCompletedTile(tile):onTapUnassignedTile(tile);
                  }
                ),
              );
            });

            retValue = Column(children: childrenColumnWidgets);
          } else {
            retValue = Container(width: calculatedWidth);
          }

          return retValue!;
        }
    );
  }

  void onTapCompletedTile(TilerEvent tile){
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditTile(
                  tileId: (tile.isFromTiler
                      ? tile.id
                      : tile.thirdpartyId) ?? "",
                  tileSource: tile.thirdpartyType,
                  thirdPartyUserId: tile.thirdPartyUserId,
                ),
        ),
    );
  }

  void onTapUnassignedTile(TilerEvent tile){
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TileDimensions.borderRadius)),
        ),
        builder: (BuildContext context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: WeeklyDetailsTile(tile),
              ),
            ),
          );
          },
      );
  }
}
