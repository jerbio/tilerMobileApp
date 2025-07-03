import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/monthlyDailyTile.dart';
import 'package:tiler_app/components/tileUI/monthlyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

class PrecedingMonthlyTileBatch extends TileBatch {
  PrecedingMonthlyTileBatch({required int dayIndex,List<TilerEvent>? tiles, Key? key})
      : super(dayIndex: dayIndex,tiles: tiles, key: key);

  @override
  TileBatchState createState() => _PrecedingMonthlyTileBatchState();
}

class _PrecedingMonthlyTileBatchState extends TileBatchState {
  Widget? retValue;
  TimelineSummary? dayData = TimelineSummary();
  List<Widget> childrenColumnWidgets = [];
  @override
  void initState() {
    super.initState();
    if (this.widget.dayIndex != null) {
      dayData!.dayIndex = this.widget.dayIndex;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=  theme.extension<TileThemeExtension>();
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = (screenWidth-10)/7-4;
    return BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          childrenColumnWidgets.clear();
          childrenColumnWidgets.add(
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: EdgeInsets.only(left: 2, top: 2),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: tileThemeExtension!.surfaceContainerGreater,
                  borderRadius: BorderRadius.circular(6),
                ),
                child:Text(Utility.getDayOfMonthFromIndex(widget.dayIndex!).toString().padLeft(2, '0')),
              ),
            ),
          );
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
            for (int i = 0; i < allEvents.length && i < 7; i++) {
              childrenColumnWidgets.add(MonthlyTileWidget(subEvent: allEvents[i]));
            }
            if (allEvents.length > 7) {
              childrenColumnWidgets.add(
                  Padding(
                      padding: const EdgeInsets.only(left:2.0),
                      child: Align(
                          alignment:Alignment.topLeft,
                          child: Text(
                              '•••',
                              style: TextStyle(fontSize: 12)
                          ),
                      ),
                  ),
              );
            }
          }
          retValue =  GestureDetector(
            onTap: () {
              if (allEvents.length>0) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(TileDimensions.borderRadius)),
                  ),
                  builder: (BuildContext context) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 20),
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.6,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery
                              .of(context)
                              .viewInsets
                              .bottom),
                          child: Column(
                            children: [
                              FractionallySizedBox(
                                widthFactor: TileDimensions.tileWidthRatio,
                                child: Text(
                                  DateFormat('d MMM yyyy')
                                      .format(Utility.getTimeFromIndex(widget.dayIndex!)),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...allEvents.toList().map((event) {
                              return MonthlyDailyTile(event);
                            }).toList(),]
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
            child: Container(
                width:calculatedWidth,
                height:195,
                padding: EdgeInsets.symmetric(vertical: 4,horizontal: 2),
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TileColors.completedGreen,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: childrenColumnWidgets
                ),
            ),
          );
          return retValue!;
        }
    );
  }
}
