import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/weeklyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';


class PrecedingWeeklyTileBatch extends TileBatch {
  PrecedingWeeklyTileBatch({required int dayIndex, Key? key})
      : super(dayIndex: dayIndex, key: key);

  @override
  TileBatchState createState() => _PrecedingWeeklyTileBatchState();
}

class _PrecedingWeeklyTileBatchState extends TileBatchState {
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
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth =( screenWidth * 0.136).floorToDouble();
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
          allEvents.sort((a, b) => a.start!.compareTo(b.start!));
          if (allEvents.isNotEmpty) {
            allEvents.forEach((tile) {
              childrenColumnWidgets.add(WeeklyTileWidget(subEvent: tile,isPreceding: true,));
            });

            retValue = Column(children: childrenColumnWidgets);
          } else {
            retValue = Container(width: calculatedWidth);
          }

          return retValue!;
        }
    );
  }
}
