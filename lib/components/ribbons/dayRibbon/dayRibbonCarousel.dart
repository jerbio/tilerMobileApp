import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayButton.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  bool selected = false;
  Curve curve = Curves.linear;
  final CarouselSliderController dayRibbonCarouselController =
      CarouselSliderController();
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=Theme.of(context).extension<TileThemeExtension>()!;
  }
  updateSelectedDate(DateTime date) {
    setState(() {
      this.selectedDate = date.dayDate;
    });
  }

  onDateButtonTapped(DateTime date) {
    AnalysticsSignal.send('DAY_RIBBON_TAPPED');

    DateTime previousDate = this.selectedDate;
    DateTime currentDate = date;
    updateSelectedDate(date);
    final currentState = this.context.read<UiDateManagerBloc>().state;

    if (currentState is UiDateManagerUpdated) {
      previousDate = currentState.currentDate;
    }

    if (currentDate.millisecondsSinceEpoch !=
        previousDate.millisecondsSinceEpoch) {
      this.context.read<UiDateManagerBloc>().add(DateChangeEvent(
          previousSelectedDate: previousDate,
          selectedDate: date,
          dateChangeTrigger: DateChangeTrigger.buttonPress));
    }
  }

  Widget renderDayButton(DateTime dateTime) {
    return Container(
      decoration: dateTime.isToday
          ? BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: colorScheme.primaryContainer,
                  width: 2,
                ),
              ),
            )
          : null,
      child: DayButton(
        dateTime: dateTime,
        showMonth: dateTime.day == 1,
        onTapped: onDateButtonTapped,
        isSelected: this.selectedDate.universalDayIndex == dateTime.universalDayIndex,
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

  double sliderWidth = 50;
  double slideLeft = -30;
  Duration uiRoll = Duration(seconds: 3);
  double slideTop = 0;
  late Color loaderColor;

  Tuple2<Future, StreamSubscription?>? setTimeOutUpdate;
  ValueKey animatedSliderKey = ValueKey(Utility.getUuid);
  bool showLoader = false;

  double get resetSlideLeft {
    return (-sliderWidth) + 1;
  }

  double get finalSlideLeft {
    return MediaQuery.of(context).size.width;
  }

  void infiniteCaller() {
    setState(() {
      slideLeft = finalSlideLeft;
      slideTop = 0;
    });
    setTimeOutUpdate = Utility.setTimeOut(
        duration: uiRoll,
        callBack: () {
          setState(() {
            animatedSliderKey = ValueKey(Utility.getUuid);
            slideTop = 0;
            slideLeft = resetSlideLeft;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            infiniteCaller();
          });
        });
  }

  void startSlider() {
    sliderWidth = MediaQuery.of(context).size.width / 3;
    slideLeft = (-sliderWidth) + 5;
    setState(() {
      showLoader = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      infiniteCaller();
    });
  }

  void stopSlider() {
    if (setTimeOutUpdate != null) {
      if (setTimeOutUpdate!.item2 != null) {
        setTimeOutUpdate!.item2!.cancel();
      }
    }
    setState(() {
      showLoader = false;
    });
  }

  Widget renderHorizontalLoader() {
    if (!showLoader) {
      return SizedBox.shrink();
    }
    return AnimatedPositioned(
      key: animatedSliderKey,
      bottom: slideTop,
      left: slideLeft,
      duration: uiRoll,
      curve: curve,
      child: Container(
        width: sliderWidth,
        height: 2.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              loaderColor.withLightness(1),
              loaderColor.withLightness(0.95),
              loaderColor.withLightness(0.75),
              loaderColor.withLightness(0.75),
              loaderColor.withLightness(0.55),
              loaderColor.withLightness(0.35),
            ],
          ),
          border: Border.all(
            color: colorScheme.onInverseSurface,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
        ),
      ),
    );
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
        BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            if (state is ScheduleLoadingState) {
              loaderColor = colorScheme.tertiaryContainer;
              startSlider();
            }

            if (state is ScheduleLoadedState) {
              if (state is FailedScheduleLoadedState) {
                setState(() {
                  loaderColor = colorScheme.onError;
                });
                startSlider();
              } else {
                stopSlider();
              }
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
            margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: tileThemeExtension.shadowSecondary.withValues(alpha: 0.08),
                  blurRadius: 7,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width,
            height: 130,
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: CarouselSlider(
                    carouselController: dayRibbonCarouselController,
                    items: carouselDayRibbonBatch,
                    options: CarouselOptions(
                      viewportFraction: 1,
                      initialPage: initialCarouselIndex,
                      enableInfiniteScroll: false,
                      reverse: false,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                ),
                renderHorizontalLoader()
              ],
            ),
          );
        }),
      ),
    );
  }
}
