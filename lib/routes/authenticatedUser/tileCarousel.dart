import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileSummary.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class TileCarousel extends StatefulWidget {
  List<String>? subEventIds;
  List<SubCalendarEvent>? subEvents;
  TileCarousel({this.subEventIds, this.subEvents});
  @override
  _TileCarouselState createState() => _TileCarouselState();
}

class _TileCarouselState extends State<TileCarousel> {
  bool isAutoScrolled = false;
  final ItemScrollController dayScrollController = ItemScrollController();
  final ItemPositionsListener dayPositionsListener =
      ItemPositionsListener.create();

  SubCalendarEventApi subEventApi = new SubCalendarEventApi();
  List<SubCalendarEvent>? subEvents;
  Map<
      int,
      Tuple3<ItemScrollController, ItemPositionsListener,
          List<SubCalendarEvent>>>? dayIndexToScrollItems;
  @override
  void initState() {
    super.initState();
    this
        .context
        .read<SubCalendarTileBloc>()
        .emit(SubCalendarTilesInitialState());
    subEvents = this.widget.subEvents;
    if (this.widget.subEvents == null &&
        this.widget.subEventIds != null &&
        this.widget.subEventIds!.length > 0) {
      this.context.read<SubCalendarTileBloc>().add(
          GetListOfSubCalendarTilesBlocEvent(
              subEventIds: this.widget.subEventIds!));
      return;
    }
    if (this.widget.subEvents != null) {
      this.context.read<SubCalendarTileBloc>().emit(
          ListOfSubCalendarTileLoadedState(subEvents: this.widget.subEvents!));
      return;
    }
  }

  Widget renderHorizontalSubEvents(int dayIndex) {
    Tuple3<ItemScrollController, ItemPositionsListener, List<SubCalendarEvent>>
        dayInfo = dayIndexToScrollItems![dayIndex]!;
    List<SubCalendarEvent> orderedSubEvents = dayInfo.item3
        .map<SubCalendarEvent>((e) => e as SubCalendarEvent)
        .toList();

    return Expanded(
        child: Row(
      children: orderedSubEvents
          .map((e) => Container(height: 200, width: 300, child: TileSummary(e)))
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
      listener: (context, state) {
        if (state is ListOfSubCalendarTileLoadedState) {
          Map<
              int,
              Tuple3<ItemScrollController, ItemPositionsListener,
                  List<SubCalendarEvent>>> dayIndexToSubEvents = {};
          state.subEvents.forEach((eachSubEvent) {
            int dayIndex = Utility.getDayIndex(eachSubEvent.startTime!);
            List<SubCalendarEvent> daySubEvents = [];
            if (dayIndexToSubEvents.containsKey(dayIndex)) {
              daySubEvents = dayIndexToSubEvents[dayIndex]!.item3;
            } else {
              Tuple3<ItemScrollController, ItemPositionsListener,
                      List<SubCalendarEvent>> dayTupleData =
                  Tuple3(ItemScrollController(), ItemPositionsListener.create(),
                      daySubEvents);
              dayIndexToSubEvents[dayIndex] = dayTupleData;
            }
            daySubEvents.add(eachSubEvent);
          });

          return setState(() {
            subEvents = state.subEvents;
            dayIndexToScrollItems = dayIndexToSubEvents;
          });
        }
      },
      child: BlocBuilder<SubCalendarTileBloc, SubCalendarTileState>(
        builder: (context, state) {
          if (state is ListOfSubCalendarTilesLoadingState) {
            return PendingWidget();
          }

          if (state is ListOfSubCalendarTileLoadedState) {
            Map<int, List<SubCalendarEvent>> dayIndexToSubEvents = {};

            state.subEvents.forEach((eachSubEvent) {
              int dayIndex = Utility.getDayIndex(eachSubEvent.startTime!);
              List<SubCalendarEvent> daySubEvents = [];
              if (dayIndexToSubEvents.containsKey(dayIndex)) {
                daySubEvents = dayIndexToSubEvents[dayIndex]!;
              }
              daySubEvents.add(eachSubEvent);
              dayIndexToSubEvents[dayIndex] = daySubEvents;
            });

            List<int> dayIndexes = dayIndexToSubEvents.keys.toList();
            dayIndexes.sort();
            int todayIndex = Utility.getDayIndex(Utility.currentTime());
            int foundIndex = dayIndexes.length - 1;
            for (int i = 0; i < dayIndexes.length; i++) {
              int dayIndex = dayIndexes[i];
              int dayDiff = dayIndex - todayIndex;
              if (dayDiff >= 0) {
                foundIndex = i;
                break;
              }
            }
            Widget retValue = Container(
                height: 300,
                child: ScrollablePositionedList.builder(
                    itemScrollController: dayScrollController,
                    itemPositionsListener: dayPositionsListener,
                    itemCount: dayIndexes.length,
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Container(
                        height: 250,
                        width: 300,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Text(
                                    Utility.getTimeFromIndex(dayIndexes[index])
                                        .humanDate,
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontFamily: TileStyles.rubikFontName,
                                        fontWeight: FontWeight.w400,
                                        color: const Color.fromRGBO(
                                            31, 31, 31, 1))),
                              ),
                              renderHorizontalSubEvents(dayIndexes[index])
                            ]),
                      );
                    }));
            if (!isAutoScrolled && foundIndex >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  isAutoScrolled = true;
                });
                if (foundIndex >= 0) {
                  dayScrollController.scrollTo(
                      index: foundIndex, duration: Duration(milliseconds: 500));
                }
              });
            }

            return retValue;
          }
          return SizedBox();
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
