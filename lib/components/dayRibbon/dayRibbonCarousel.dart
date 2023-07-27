import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayRibbon/dayButton.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class DayRibbonCarousel extends StatefulWidget {
  int numberOfDays = 5;
  bool autoUpdateAnchorDate = false;
  DateTime _initialDate = Utility.currentTime().dayDate;
  Function? onDateChange;
  DayRibbonCarousel(DateTime? initialDate,
      {this.onDateChange,
      this.autoUpdateAnchorDate = false,
      this.numberOfDays = 5}) {
    if (initialDate == null) {
      initialDate = Utility.currentTime().dayDate;
    }
    this._initialDate = initialDate;
  }
  @override
  State<StatefulWidget> createState() => _DayRibbonCarouselState();
}

class _DayRibbonCarouselState extends State<DayRibbonCarousel> {
  late DateTime anchorDate;
  late DateTime selectedDate;
  late int batchCount;
  late int numberOfDays;
  final CarouselController dayRibbonCarouselController = CarouselController();
  Map<int, Tuple2<int, Timeline>> universalIndexToBatch = {};
  Map<int, Tuple2<int, Timeline>> dayBatchIndexToBatch = {};
  @override
  void initState() {
    super.initState();
    anchorDate = this.widget._initialDate;
    selectedDate = anchorDate;
    batchCount = 28 * this.widget.numberOfDays;
    numberOfDays = this.widget.numberOfDays;
  }

  updateSelectedDate(DateTime date) {
    setState(() {
      this.selectedDate = date.dayDate;
    });
  }

  onDateButtonTapped(DateTime date) {
    DateTime previousDate = this.selectedDate;
    DateTime currentDate = date;
    updateSelectedDate(date);
    final currentState = this.context.read<UiDateManagerBloc>().state;

    if (currentState is UiDateManagerUpdated) {
      previousDate = currentState.currentDate;
    }

    if (currentState is UiDateManagerInitial) {
      previousDate = currentState.currentDate;
    }

    if (currentDate.millisecondsSinceEpoch !=
        previousDate.millisecondsSinceEpoch) {
      this.context.read<UiDateManagerBloc>().add(DateChangeEvent(
          previousSelectedDate: previousDate, selectedDate: date));
    }
  }

  Widget renderDayButton(DateTime dateTime) {
    return Container(
      decoration: dateTime.isToday
          ? BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: TileStyles.primaryColorLightHSL.toColor(),
                  width: 2,
                ),
              ),
            )
          : null,
      child: DayButton(
        dateTime: dateTime,
        showMonth: dateTime.day == 1,
        onTapped: onDateButtonTapped,
        isSelected:
            this.selectedDate.universalDayIndex == dateTime.universalDayIndex,
      ),
    );
  }

  Tuple3<Widget, Timeline?, Set<int>?> generateWidgetBatch(DateTime dateTime) {
    int zeroDayIndex = Utility.getDayIndex(dateTime);
    List<Widget> dayRibbonWidgets = <Widget>[];
    int subEventAfterCount = this.numberOfDays ~/ 2;

    Timeline? batchTimeline;
    Set<int>? batchDayIndexes;

    if (this.numberOfDays > 0) {
      DateTime timelineStart = Utility.getTimeFromIndex(zeroDayIndex);
      DateTime timelineEnd = Utility.getTimeFromIndex(zeroDayIndex);
      batchDayIndexes = Set();
      dayRibbonWidgets
          .add(renderDayButton(Utility.getTimeFromIndex(zeroDayIndex)));
      batchDayIndexes.add(zeroDayIndex);
      int currentDayIndex = zeroDayIndex + 1;
      for (int i = 0;
          i < subEventAfterCount && dayRibbonWidgets.length < this.numberOfDays;
          i++, ++currentDayIndex) {
        DateTime dayButtonDateTime = Utility.getTimeFromIndex(currentDayIndex);
        dayRibbonWidgets.add(renderDayButton(dayButtonDateTime));
        if (dayButtonDateTime.millisecondsSinceEpoch <
            timelineStart.millisecondsSinceEpoch) {
          timelineStart = dayButtonDateTime;
        }
        if (dayButtonDateTime.millisecondsSinceEpoch >
            timelineEnd.millisecondsSinceEpoch) {
          timelineEnd = dayButtonDateTime;
        }
        batchDayIndexes.add(dayButtonDateTime.universalDayIndex);
      }
      currentDayIndex = zeroDayIndex - 1;
      for (int i = 0;
          i < subEventAfterCount && dayRibbonWidgets.length < this.numberOfDays;
          ++i, --currentDayIndex) {
        DateTime dayButtonDateTime = Utility.getTimeFromIndex(currentDayIndex);
        dayRibbonWidgets.insert(0, renderDayButton(dayButtonDateTime));
        batchDayIndexes.add(dayButtonDateTime.universalDayIndex);

        if (dayButtonDateTime.millisecondsSinceEpoch <
            timelineStart.millisecondsSinceEpoch) {
          timelineStart = dayButtonDateTime;
        }
        if (dayButtonDateTime.millisecondsSinceEpoch >
            timelineEnd.millisecondsSinceEpoch) {
          timelineEnd = dayButtonDateTime;
        }
      }
      batchTimeline = Timeline.fromDateTime(timelineStart, timelineEnd);
    }

    return Tuple3<Widget, Timeline?, Set<int>?>(
        Container(
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayRibbonWidgets,
          ),
        ),
        batchTimeline,
        batchDayIndexes);
  }

  handleDateChange(UiDateManagerUpdated state) {
    if (universalIndexToBatch
        .containsKey(state.currentDate.universalDayIndex)) {
      dayRibbonCarouselController.animateToPage(
          universalIndexToBatch[state.currentDate.universalDayIndex]!.item1);
      if (state.currentDate.dayDate.millisecondsSinceEpoch !=
          this.selectedDate.dayDate.millisecondsSinceEpoch) {
        updateSelectedDate(state.currentDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (this.widget.autoUpdateAnchorDate) {
      if (this.anchorDate.universalDayIndex !=
          Utility.currentTime().universalDayIndex) {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              this.anchorDate = Utility.currentTime().dayDate;
            });
          }
        });
      }
    }
    return MultiBlocListener(
        listeners: [
          BlocListener<UiDateManagerBloc, UiDateManagerState>(
            listener: (context, state) {
              if (state is UiDateManagerUpdated) {
                handleDateChange(state);
              }
            },
          ),
        ],
        child: BlocBuilder<UiDateManagerBloc, UiDateManagerState>(
            builder: ((context, state) {
          int beginDelta = this.batchCount - (this.batchCount ~/ 2);
          if (beginDelta < 0) {
            beginDelta = 0;
          }

          int currentDateDayIndex = this.anchorDate.universalDayIndex;
          int beginDayIndex =
              currentDateDayIndex - (beginDelta * this.numberOfDays);
          if (beginDayIndex < 0) {
            beginDayIndex = 0;
          }

          int initialCarouselIndex = -1;
          List<Widget> carouselDayRibbonBatch = [];
          for (int i = 0, j = 0; j < batchCount; j++) {
            int batchDayIndex = beginDayIndex + i;
            if (initialCarouselIndex < 0 &&
                batchDayIndex > currentDateDayIndex) {
              initialCarouselIndex = j - 1;
            }
            var tileBatchInfo =
                generateWidgetBatch(Utility.getTimeFromIndex(batchDayIndex));
            carouselDayRibbonBatch.add(tileBatchInfo.item1);
            if (tileBatchInfo.item2 != null) {
              Tuple2<int, Timeline> batchInfo = Tuple2(j, tileBatchInfo.item2!);
              if (tileBatchInfo.item3 != null) {
                for (var dayIndex in tileBatchInfo.item3!) {
                  universalIndexToBatch[dayIndex] = batchInfo;
                }
              }
              dayBatchIndexToBatch[j] = batchInfo;
            }
            i += this.numberOfDays;
          }

          if (initialCarouselIndex < 0) {
            initialCarouselIndex = 0;
          }
          return Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width,
            height: 130,
            child: CarouselSlider(
                carouselController: dayRibbonCarouselController,
                items: carouselDayRibbonBatch,
                options: CarouselOptions(
                  viewportFraction: 1,
                  initialPage: initialCarouselIndex,
                  enableInfiniteScroll: false,
                  reverse: false,
                  scrollDirection: Axis.horizontal,
                )),
          );
        })));
  }
}
