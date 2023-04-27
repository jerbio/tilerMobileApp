import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/dayRibbon/dayButton.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class DayRibbonCarousel extends StatefulWidget {
  int numberOfDays = 6;
  DateTime _initialDate = Utility.currentTime().dayDate;
  Function? onDateChange;
  DayRibbonCarousel(DateTime? initialDate, {this.onDateChange}) {
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

  onDateButtonTapped(DateTime date) {
    setState(() {
      this.selectedDate = date;
    });
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
      dayRibbonWidgets.add(DayButton(
        dateTime: Utility.getTimeFromIndex(zeroDayIndex),
        showMonth: dateTime.day == 1,
        onTapped: onDateButtonTapped,
        isSelected:
            this.selectedDate.universalDayIndex == dateTime.universalDayIndex,
      ));
      batchDayIndexes.add(zeroDayIndex);
      int currentDayIndex = zeroDayIndex + 1;
      for (int i = 0;
          i < subEventAfterCount && dayRibbonWidgets.length < this.numberOfDays;
          i++, ++currentDayIndex) {
        DateTime dayButtonDateTime = Utility.getTimeFromIndex(currentDayIndex);
        dayRibbonWidgets.add(DayButton(
          dateTime: dayButtonDateTime,
          showMonth: dayButtonDateTime.day == 1,
          onTapped: onDateButtonTapped,
          isSelected: this.selectedDate.universalDayIndex ==
              dayButtonDateTime.universalDayIndex,
        ));
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
        dayRibbonWidgets.insert(
            0,
            DayButton(
              dateTime: dayButtonDateTime,
              showMonth: dayButtonDateTime.day == 1,
              onTapped: onDateButtonTapped,
              isSelected: this.selectedDate.universalDayIndex ==
                  dayButtonDateTime.universalDayIndex,
            ));
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

  @override
  Widget build(BuildContext context) {
    int beginDelta = this.batchCount - (this.batchCount ~/ 2);
    if (beginDelta < 0) {
      beginDelta = 0;
    }

    int currentDateDayIndex = this.anchorDate.universalDayIndex;
    int beginDayIndex = currentDateDayIndex - (beginDelta * this.numberOfDays);
    if (beginDayIndex < 0) {
      beginDayIndex = 0;
    }

    int intialCarouselIndex = -1;
    List<Widget> carouselDayRibbonBatch = [];
    for (int i = 0, j = 0; j < batchCount; j++) {
      int batchDayIndex = beginDayIndex + i;
      if (intialCarouselIndex < 0 && batchDayIndex > currentDateDayIndex) {
        intialCarouselIndex = j - 1;
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

    if (intialCarouselIndex < 0) {
      intialCarouselIndex = 0;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CarouselSlider(
          carouselController: dayRibbonCarouselController,
          items: carouselDayRibbonBatch,
          options: CarouselOptions(
            viewportFraction: 1,
            initialPage: intialCarouselIndex,
            enableInfiniteScroll: false,
            reverse: false,
            onPageChanged: (pageNumber, carouselData) {
              if (carouselData == CarouselPageChangedReason.manual) {
                // if (pageNumber == 0) {
                //   setAsTile();
                // } else {
                //   setAsAppointment();
                // }
              }
            },
            scrollDirection: Axis.horizontal,
          )),
    );
  }
}
