import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/monthlyDailyTile.dart';
import 'package:tiler_app/components/tileUI/monthlyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class PrecedingMonthlyTileBatch extends TileBatch {
  PrecedingMonthlyTileBatch({required int dayIndex, Key? key})
      : super(dayIndex: dayIndex, key: key);

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
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth =( screenWidth * 0.136).floorToDouble();
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
                  color: Color.fromRGBO(220, 220, 220, 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(Utility.getDayOfMonthFromIndex(widget.dayIndex!).toString()),
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
          allEvents.sort((a, b) => a.start!.compareTo(b.start!));
          if (allEvents.isNotEmpty) {
            for (int i = 0; i < allEvents.length && i < 7; i++) {
              childrenColumnWidgets.add(MonthlyTileWidget(subEvent: allEvents[i]));
            }
            if (allEvents.length > 7) {
              childrenColumnWidgets.add( Padding(
                  padding: const EdgeInsets.only(left:2.0),child: Align(alignment:Alignment.topLeft,child: Text('•••', style: TextStyle(fontSize: 12)))));
            }
          }
          retValue =  GestureDetector(
            onTap: () {
              if (allEvents.length>0) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(TileStyles.borderRadius)),
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
                            children: allEvents.toList().map((event) {
                              return MonthlyDailyTile(event);
                            }).toList(),
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
                decoration: BoxDecoration(
                  color: Color.fromRGBO(220, 220, 220, 1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Color.fromRGBO(220, 220, 220,0.7) ,
                    BlendMode.srcATop
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: childrenColumnWidgets
                  ),
                ),
            ),
          );
          return retValue!;
        }
    );
  }
}
