import 'package:flutter/material.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';

import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RepetitionRoute extends StatefulWidget {
  static final String routeName = '/RepetitionRoute';
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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;


  static final String repetitionCancelAndProceedRouteName =
      "repetitionCancelAndProceedRouteName";

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
    Duration noneDuration = Duration(minutes: -1);
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
      new Tuple2<RepetitionFrequency, Duration>(
          RepetitionFrequency.none, noneDuration),
    ];

    super.initState();
    _transparencyController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation =
        Tween<double>(begin: 0, end: 1).animate(_transparencyController);
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
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
      case RepetitionFrequency.none:
        {
          frequencyText = AppLocalizations.of(context)!.none;
        }
        break;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: Text(
        frequencyText,
        style: TextStyle(
          fontSize: 20,
          fontFamily: TileTextStyles.rubikFontName,
          color: isSelected ? colorScheme.primary :tileThemeExtension.onSurfaceVariantSecondary,
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
    if (this.repetitionData != null &&
        this.repetitionData!.frequency == RepetitionFrequency.none) {
      firstDate =
          Utility.todayTimeline().startTime.subtract(Duration(days: 365 * 10));
      lastDate =
          Utility.todayTimeline().startTime.add(Duration(days: 365 * 10));
      _endDate = Utility.todayTimeline().endTime.add(Utility.oneDay);
    }
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
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: this.isDeadlineValid()
                          ? colorScheme.onInverseSurface
                          : colorScheme.error,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_month, color: tileThemeExtension.onSurfaceSecondary),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          onPressed: onDeadlineDateTap,
                          child: Text(
                            textButtonString,
                            style: TextStyle(
                                fontFamily: TileTextStyles.rubikFontName,
                                color: this.isDeadlineValid()
                                    ? colorScheme.tertiary
                                    : colorScheme.onInverseSurface
                            ),
                          ),
                        ))
                  ],
                )
            )
        )
    );
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
    return SizedBox.shrink();
    // return Opacity(
    //     opacity: _animation.value,
    //     child: WeekdaySelector(
    //       onChanged: (int index) {
    //         RepetitionData updatedRepetitionData = repetitionData!;
    //         if (updatedRepetitionData.weeklyRepetition != null) {
    //           if (updatedRepetitionData.weeklyRepetition!.contains(index)) {
    //             updatedRepetitionData.weeklyRepetition!.remove(index);
    //           } else {
    //             updatedRepetitionData.weeklyRepetition!.add(index);
    //           }
    //         }
    //         setState(() {
    //           repetitionData = updatedRepetitionData;
    //         });
    //       },
    //       values: weeklyRepetitionBool,
    //     ));
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
    return isDeadlineValid();
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
            // .where((eachTuple) =>
            //     eachTuple.item2.inMilliseconds >
            //     tileTimelineParam!.duration.inMilliseconds)//disabled filtering by deadline because users were confused by the random hiding of repetition.
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
      routeName: repetitionCancelAndProceedRouteName,
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
                      RepetitionData? updatedRepetitionData = repetitionData ??
                          RepetitionData(
                              frequency: applicableRepetitions[index].item1,
                              isEnabled: true);
                      updatedRepetitionData.frequency =
                          applicableRepetitions[index].item1;
                      if (applicableRepetitions[index].item1 ==
                          RepetitionFrequency.none) {
                        updatedRepetitionData.isEnabled = false;
                      } else {
                        updatedRepetitionData.isEnabled = true;
                      }

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
      onProceed: this.onProceed,
      onCancel: this.onCancel,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.repetition,),
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
