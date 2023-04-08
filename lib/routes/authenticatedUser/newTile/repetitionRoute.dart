import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:weekday_selector/weekday_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RepetitionRoute extends StatefulWidget {
  static final String routeName = '/repetitionRoute';
  @override
  _RepetitionRouteState createState() => _RepetitionRouteState();
}

class _RepetitionRouteState extends State<RepetitionRoute>
    with SingleTickerProviderStateMixin {
  Map? repetitionParams;
  RepetitionData? repetitionData;
  EditDateAndTime? _repetitionDeadline;
  late List<Tuple2<RepetitionFrequency, Duration>> descriptionAndDuration;
  late List<Tuple2<RepetitionFrequency, Duration>> applicableRepetitions;
  late Map<RepetitionFrequency, bool> applicableRepetitionsSelectedMap = {};
  late DateTime _monthDeadline;
  late DateTime _yearDeadline;
  late AnimationController _transparencyController;
  late Animation<double> _animation;
  bool isLoadedFromInitializer = false;
  Timeline? tileTimeline;

  @override
  void initState() {
    DateTime currentTime = Utility.currentTime();
    DateTime monthStart =
        DateTime(currentTime.year, currentTime.month, 1).toLocal();
    DateTime lastDayMonthEnd =
        DateTime(currentTime.year, (currentTime.month + 1) % 12, 0, 11);
    DateTime monthEnd = DateTime(currentTime.year, lastDayMonthEnd.month,
            lastDayMonthEnd.day, 23, 59)
        .toLocal();
    _monthDeadline = monthEnd;
    Duration monthDuration = Utility.durationDifference(monthEnd, monthStart);

    DateTime yearStart = DateTime(currentTime.year, 1, 1).toLocal();
    DateTime yearEnd = DateTime(currentTime.year, 12, 31, 23, 59).toLocal();
    _yearDeadline = yearEnd;
    Duration yearDuration = Utility.durationDifference(yearEnd, yearStart);
    descriptionAndDuration = [
      new Tuple2<RepetitionFrequency, Duration>(
          RepetitionFrequency.daily, Utility.oneDay),
      new Tuple2<RepetitionFrequency, Duration>(
          RepetitionFrequency.weekly, Utility.sevenDays),
      new Tuple2<RepetitionFrequency, Duration>(
          RepetitionFrequency.monthly, monthDuration),
      new Tuple2<RepetitionFrequency, Duration>(
          RepetitionFrequency.yearly, yearDuration),
    ];

    super.initState();
    _transparencyController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation =
        Tween<double>(begin: 0, end: 1).animate(_transparencyController);
  }

  Widget frequencyWidget(RepetitionFrequency frequency, bool isSelected) {
    late String frequencyText;
    switch (frequency) {
      case RepetitionFrequency.daily:
        {
          frequencyText = AppLocalizations.of(context)!.daily;
        }
        break;
      case RepetitionFrequency.weekly:
        {
          frequencyText = AppLocalizations.of(context)!.weekly;
        }
        break;
      case RepetitionFrequency.monthly:
        {
          frequencyText = AppLocalizations.of(context)!.monthly;
        }
        break;
      case RepetitionFrequency.yearly:
        {
          frequencyText = AppLocalizations.of(context)!.yearly;
        }
        break;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: Text(
        frequencyText,
        style: TextStyle(
          fontSize: 20,
          color: isSelected ? Colors.blue : Colors.grey,
          fontFamily: TileStyles.rubikFontName,
        ),
      ),
    );
  }

  Widget getWeekDayWidget(String weekDay, isSelected) {
    return Text(weekDay);
  }

  void onDeadlineDateTap() async {
    DateTime _endDate = this.repetitionData?.repetitionEnd == null
        ? Utility.todayTimeline().endTime.add(Utility.oneDay)
        : this.repetitionData!.repetitionEnd!;
    DateTime firstDate = _endDate.add(Duration(days: -100000));
    DateTime lastDate = _endDate.add(Duration(days: 100000));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectADeadline,
    );
    if (revisedEndDate != null) {
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endDate.hour,
          _endDate.minute);
      RepetitionData updatedRepetitionData = repetitionData!;
      if (updatedRepetitionData.weeklyRepetition != null) {
        updatedRepetitionData.repetitionEnd = updatedEndTime;
      }
      setState(() => repetitionData = updatedRepetitionData);
    }
  }

  Widget generateDeadline(DateTime? deadline) {
    String textButtonString = deadline == null
        ? AppLocalizations.of(context)!.deadline_anytime
        : DateFormat.yMMMd().format(deadline);
    Widget deadlineContainer = new GestureDetector(
        onTap: this.onDeadlineDateTap,
        child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: TileStyles.textBackgroundColor,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: this.isDeadlineValid()
                          ? TileStyles.textBorderColor
                          : Colors.redAccent,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_month, color: TileStyles.iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: TextStyle(
                                fontSize: 20,
                                color: this.isDeadlineValid()
                                    ? null
                                    : Colors.redAccent),
                          ),
                          onPressed: onDeadlineDateTap,
                          child: Text(
                            textButtonString,
                            style: TextStyle(
                                fontFamily: TileStyles.rubikFontName,
                                color: this.isDeadlineValid()
                                    ? null
                                    : Colors.grey),
                          ),
                        ))
                  ],
                ))));
    return deadlineContainer;
  }

  void onProceed() {
    var repetitionParams = ModalRoute.of(context)?.settings.arguments as Map?;
    if (repetitionParams != null) {
      repetitionParams['updatedRepetition'] = this.repetitionData;
      repetitionParams['isRepetitionEndValid'] = this.isDeadlineValid();
    }
  }

  void onCancel() {
    var repetitionParams = ModalRoute.of(context)?.settings.arguments as Map?;
    if (repetitionParams != null) {
      repetitionParams['isRepetitionEndValid'] = this.isDeadlineValid();
    }
  }

  Widget renderWeekDayButtons() {
    List<bool> weeklyRepetitionBool = [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ];
    List<int> weeklyRepetition = [];
    if (this.repetitionData != null &&
        this.repetitionData!.weeklyRepetition != null) {
      weeklyRepetition = this.repetitionData!.weeklyRepetition!.toList();
      weeklyRepetition.sort();
      for (int weekDayIndex in weeklyRepetition) {
        weeklyRepetitionBool[weekDayIndex % 7] = true;
      }
    }

    return Opacity(
        opacity: _animation.value,
        child: WeekdaySelector(
          onChanged: (int index) {
            RepetitionData updatedRepetitionData = repetitionData!;
            if (updatedRepetitionData.weeklyRepetition != null) {
              if (updatedRepetitionData.weeklyRepetition!.contains(index)) {
                updatedRepetitionData.weeklyRepetition!.remove(index);
              } else {
                updatedRepetitionData.weeklyRepetition!.add(index);
              }
            }
            setState(() {
              repetitionData = updatedRepetitionData;
            });
          },
          values: weeklyRepetitionBool,
        ));
  }

  bool isWeeklyRepetitionSelected() {
    if (this
        .applicableRepetitionsSelectedMap
        .containsKey(RepetitionFrequency.weekly)) {
      return this.applicableRepetitionsSelectedMap[RepetitionFrequency.weekly]!;
    }
    return false;
  }

  bool isDeadlineValid() {
    if (tileTimeline != null &&
        this.repetitionData != null &&
        this.repetitionData!.repetitionEnd != null) {
      return tileTimeline!.end! <
          Utility.utcEpochMillisecondsFromDateTime(
              this.repetitionData!.repetitionEnd!);
    }

    return false;
  }

  bool isRepetitionReadyForSubmit() {
    return isDeadlineValid() && this.repetitionData != null;
  }

  @override
  Widget build(BuildContext context) {
    repetitionParams = ModalRoute.of(context)?.settings.arguments as Map;
    if (repetitionParams != null && !isLoadedFromInitializer) {
      if (repetitionParams!.containsKey('repetitionData') &&
          repetitionParams!['repetitionData'] != null) {
        repetitionData = repetitionParams!['repetitionData'] as RepetitionData;
      }
      applicableRepetitions = descriptionAndDuration;
      Timeline? tileTimelineParam;
      if (repetitionParams!.containsKey('tileTimeline') &&
          repetitionParams!['tileTimeline'] != null) {
        tileTimelineParam = repetitionParams!['tileTimeline'] as Timeline;
        applicableRepetitions = descriptionAndDuration
            .where((eachTuple) =>
                eachTuple.item2.inMilliseconds >
                tileTimelineParam!.duration.inMilliseconds)
            .toList();
      }
      for (Tuple2<RepetitionFrequency, Duration> applicableRepetition
          in applicableRepetitions) {
        applicableRepetitionsSelectedMap[applicableRepetition.item1] = false;
        if (repetitionData != null &&
            repetitionData!.frequency == applicableRepetition.item1) {
          applicableRepetitionsSelectedMap[applicableRepetition.item1] = true;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isLoadedFromInitializer = true;
          tileTimeline = tileTimelineParam;
        });
      });
    }

    List<bool> isSelected =
        applicableRepetitions.map((eachApplicableRepetition) {
      return applicableRepetitionsSelectedMap[eachApplicableRepetition.item1]!;
    }).toList();
    return CancelAndProceedTemplateWidget(
      child: Container(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                  padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: ToggleButtons(
                    children: applicableRepetitions
                        .map((frequencyTuple) => frequencyWidget(
                            frequencyTuple.item1,
                            this.applicableRepetitionsSelectedMap[
                                frequencyTuple.item1]!))
                        .toList(),
                    isSelected: isSelected,
                    onPressed: (int index) {
                      Map<RepetitionFrequency, bool>
                          applicableRepetitionsSelectedCpy =
                          Map.from(applicableRepetitionsSelectedMap);
                      for (int i = 0; i < applicableRepetitions.length; i++) {
                        applicableRepetitionsSelectedCpy[
                            applicableRepetitions[i].item1] = false;
                      }
                      applicableRepetitionsSelectedCpy[
                          applicableRepetitions[index].item1] = true;
                      RepetitionData updatedRepetitionData = repetitionData ??
                          RepetitionData(
                              frequency: applicableRepetitions[index].item1);
                      updatedRepetitionData.frequency =
                          applicableRepetitions[index].item1;
                      setState(() {
                        applicableRepetitionsSelectedMap =
                            applicableRepetitionsSelectedCpy;
                        repetitionData = updatedRepetitionData;
                      });
                      if (_transparencyController.isDismissed &&
                          applicableRepetitions[index].item1 ==
                              RepetitionFrequency.weekly) {
                        _transparencyController.forward();
                      } else {
                        _transparencyController.reset();
                      }
                    },
                  )),
              Container(
                  padding: EdgeInsets.fromLTRB(35, 20, 35, 40),
                  child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return renderWeekDayButtons();
                      })),
              this.repetitionData != null
                  ? generateDeadline(this.repetitionData!.repetitionEnd)
                  : SizedBox.shrink(),
            ],
          )),
      onProceed: isRepetitionReadyForSubmit() ? this.onProceed : null,
      onCancel: this.onCancel,
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.repetition,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
    );
  }

  @override
  void dispose() {
    _transparencyController.dispose();
    super.dispose();
  }
}
