  import 'dart:async';

  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:tiler_app/components/forecastTemplate/analysisCheckState.dart';
  import 'package:flutter_gen/gen_l10n/app_localizations.dart';
  import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
  import 'package:tiler_app/data/subCalendarEvent.dart';
  import 'package:tiler_app/routes/authenticatedUser/tileSummary.dart';
  import 'package:tiler_app/services/api/whatIfApi.dart';
  import 'package:tiler_app/util.dart';

  import '../../../components/PendingWidget.dart';
  import '../../../components/forecastTemplate/customForecastField.dart';
  import '../../../styles.dart';

  class ForecastPreview extends StatefulWidget {
    ForecastPreview({Key? key}) : super(key: key);

    @override
    _ForecastPreviewState createState() => _ForecastPreviewState();
  }

  class _ForecastPreviewState extends State<ForecastPreview> {
    final _durationController = StreamController<Duration>();
    final _dateTimeController = StreamController<DateTime>();
    final _eventController = StreamController<void>();
    TextEditingController date = TextEditingController();
    Duration _duration = Duration(hours: 0, minutes: 0);
    DateTime? _endTime;
    String resp = '';
    bool? isViable;
    List<SubCalendarEvent> subCalEvents = [];
    bool isLoading = false;
    List<String> subEventIds = [];

    @override
    void initState() {
      super.initState();

      _durationController.stream.listen((duration) {
        _duration = duration;

        _checkAndTriggerEvent();
      });

      _dateTimeController.stream.listen((dateTime) {
        _endTime = dateTime;
        _checkAndTriggerEvent();
      });

      _eventController.stream.listen((_) {
        print('Both Duration and DateTime have values. Triggering event...');
        _fetchData();
      });
    }

    void _checkAndTriggerEvent() {
      if (_duration >= Duration(minutes: 1) && _endTime != null) {
        _eventController.add(null);
      }
    }

    Future<void> _fetchData() async {
      try {
        setState(() {
          isLoading = true;
        });
        await Future.delayed(Duration(milliseconds: 500));
        print('starting api call');
        DateTime now = DateTime.now();

        // Extract the current minute, hour, day, month, and year
        int currentMinute = now.minute;
        int currentHour = now.hour;
        int currentDay = now.day;
        int currentMonth = now.month;
        int currentYear = now.year;
        // int endMinute = _endTime!.minute;
        // int endHour = _endTime!.hour;
        int endDay = _endTime!.day;
        int endMonth = _endTime!.month;
        int endYear = _endTime!.year;
        var durInHours = _duration.inHours;
        var durrInMilliseconds = _duration.inMilliseconds;
        var durInUtc = durationToUtcString(_duration);

        Map<String, Object> queryParams = {
          "StartMinute": currentMinute.toString(),
          "StartHour": currentHour.toString(),
          "StartDay": currentDay.toString(),
          "StartMonth": currentMonth.toString(),
          "StartYear": currentYear.toString(),
          "EndDay": endDay.toString(),
          "EndMonth": endMonth.toString(),
          "EndYear": endYear.toString(),
          "DurationHours": durInHours.toString(),
          "DurationInMs": durrInMilliseconds.toString(),
          "Duration": durInUtc.toString(),
        };

        await WhatIfApi().forecastNewTile(queryParams).then((val) {
          setState(() {
            isLoading = false;
            isViable = val[0];
            subCalEvents = val[1];
            print('Current Val: ${val[0]}');
            resp = val.toString();
          });

          return val;
        });
      } catch (e) {
        print(e);
      }
    }

    void updateDuration(Duration duration) {
      _durationController.add(duration);
    }

    void updateDateTime(DateTime dateTime) {
      _dateTimeController.add(dateTime);
    }

    String durationToUtcString(Duration duration) {
      DateTime utcTime = DateTime.utc(0, 0, 0, duration.inHours,
          duration.inMinutes.remainder(60), duration.inSeconds.remainder(60));
      return utcTime
          .toIso8601String()
          .split('T')[1]
          .split('.')[0]; // Extract the time part in HH:mm:ss format
    }

    Widget generateDeadline(double width, double height) {
      void onEndDateTap() async {
        DateTime _endDate = this._endTime == null
            ? Utility.todayTimeline().endTime!.add(Utility.oneDay)
            : this._endTime!;
        DateTime firstDate = _endDate.add(Duration(days: -14));
        DateTime lastDate = _endDate.add(Duration(days: 90));
        final DateTime? revisedEndDate = await showDatePicker(
          context: context,
          initialDate: _endDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: AppLocalizations.of(context)!.whenQ,
        );
        if (revisedEndDate != null) {
          DateTime updatedEndTime = new DateTime(
              revisedEndDate.year,
              revisedEndDate.month,
              revisedEndDate.day,
              _endDate.hour,
              _endDate.minute);
          setState(() {
            _endTime = updatedEndTime;
            updateDateTime(_endTime!);
          });
        }
      }

      String textButtonString = this._endTime == null
          ? AppLocalizations.of(context)!.whenQ
          : DateFormat.yMMMd().format(this._endTime!);

      // Revised
      Widget deadlineContainer = new GestureDetector(
        onTap: onEndDateTap,
        child: CustomForcastField(
          leadingIconPath: 'assets/images/Calendar.svg',
          textButtonString: textButtonString,
          height: height,
          width: width,
        ),
      );
      return deadlineContainer;
    }

    Widget generateDurationPicker(double width, double height) {
      final void Function()? setDuration = () async {
        Map<String, dynamic> durationParams = {'duration': _duration};
        Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
            .whenComplete(() {
          Duration? populatedDuration = durationParams['duration'] as Duration?;
          setState(() {
            if (populatedDuration != null) {
              _duration = populatedDuration;
              updateDuration(_duration);
              print(_duration);
            }
          });
        });
      };
      String textButtonString = 'Duration';
      if (_duration.inMinutes > 1) {
        textButtonString = "";
        int hour = _duration.inHours.floor();
        int minute = _duration.inMinutes.remainder(60);
        if (hour > 0) {
          textButtonString = '${hour}h';
          if (minute > 0) {
            textButtonString = '${textButtonString} : ${minute}m';
          }
        } else {
          if (minute > 0) {
            textButtonString = '${minute}m';
          }
        }
      }

      // Revised
      Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: CustomForcastField(
          leadingIconPath: 'assets/images/timecircle.svg',
          textButtonString: textButtonString,
          height: height,
          width: width,
        ),
      );
      return retValue;
    }

    Widget resultComponent(double width, double height) {
      Widget loadedState = isViable != null
          ? Column(
              children: [
                SizedBox(
                  height: height / (height / 20),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis',
                      style: TextStyle(
                        fontFamily: TileStyles.rubikFontName,
                        fontSize: height / (height / 17),
                        fontWeight: FontWeight.w500,
                        color: TileStyles.defaultTextColor,
                      ),
                    )
                  ],
                ),

                // Sizedbox
                SizedBox(
                  height: height / (height / 10),
                ),

                // Main result components
                isViable == true
                    ? Column(
                        children: [
                          // Whether it fits into schedule or not
                          Row(
                            children: [
                              AnalysisCheckState(
                                height: height,
                                isPass: true,
                              ),

                              //Sizedbox
                              SizedBox(
                                width: height / (height / 10),
                              ),

                              Text(
                                'This fits in your schedule.',
                                style: TextStyle(
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w400,
                                  fontSize: height / (height / 15),
                                  color: TileStyles.defaultTextColor,
                                ),
                              )
                            ],
                          ),

                          //Sizedbox
                          SizedBox(
                            height: height / (height / 20),
                          ),

                          // Warning
                          subCalEvents != null && subCalEvents.isNotEmpty
                              ? Row(
                                  children: [
                                    AnalysisCheckState(
                                      height: height,
                                      isWarning: true,
                                    ),

                                    //Sizedbox
                                    SizedBox(
                                      width: height / (height / 10),
                                    ),

                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Warning: ',
                                            style: TextStyle(
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              fontWeight: FontWeight.w500,
                                              fontSize: height / (height / 15),
                                              color: TileStyles.defaultTextColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: subCalEvents.length == 1
                                                ? '${subCalEvents.length} event at risk'
                                                : '${subCalEvents.length} events at risk',
                                            style: TextStyle(
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              fontWeight: FontWeight.w400,
                                              fontSize: height / (height / 15),
                                              color: TileStyles.defaultTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),

                          //Sizedbox
                          SizedBox(
                            height: height / (height / 20),
                          ),

                          // Subevents List
                          subCalEvents != null && subCalEvents.isNotEmpty
                              ? Column(
                                  children: subCalEvents.map((subEvent) {
                                    return TileSummary(subEvent);
                                  }).toList(),
                                )
                              : SizedBox.shrink(),

                          SizedBox(
                            height: height / (height / 20),
                          ),

                          GestureDetector(
                            onTap: () {
                              Map<String, dynamic> newTileParams = {
                                'newTile': null
                              };
                              Navigator.pushNamed(context, '/AddTile',
                                  arguments: newTileParams);
                            },
                            child: Container(
                              width: width,
                              height: height / (height / 52),
                              decoration: BoxDecoration(
                                color: TileStyles.primaryColor,
                                borderRadius:
                                    BorderRadius.circular(height / (height / 6)),
                              ),
                              child: Center(
                                child: Text(
                                  'Create',
                                  style: TextStyle(
                                    fontFamily: TileStyles.rubikFontName,
                                    fontSize: height / (height / 15),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 100,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              AnalysisCheckState(
                                height: height,
                                isConflict: true,
                              ),

                              //Sizedbox
                              SizedBox(
                                width: height / (height / 10),
                              ),

                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'This event would cause ',
                                      style: TextStyle(
                                        fontFamily: TileStyles.rubikFontName,
                                        fontWeight: FontWeight.w400,
                                        fontSize: height / (height / 15),
                                        color: TileStyles.defaultTextColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: subCalEvents.length == 1
                                          ? '${subCalEvents.length} conflict'
                                          : '${subCalEvents.length} conflicts',
                                      style: TextStyle(
                                        fontFamily: TileStyles.rubikFontName,
                                        fontWeight: FontWeight.w500,
                                        fontSize: height / (height / 15),
                                        color: TileStyles.defaultTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          //Sizedbox
                          SizedBox(
                            height: height / (height / 20),
                          ),

                          // Subevents List
                          subCalEvents != null && subCalEvents.isNotEmpty
                              ? Column(
                                  children: subCalEvents.map((subEvent) {
                                    return TileSummary(subEvent);
                                  }).toList(),
                                )
                              : SizedBox.shrink(),

                          // Create Button
                          GestureDetector(
                            onTap: () {
                              Map<String, dynamic> newTileParams = {
                                'newTile': null
                              };
                              Navigator.pushNamed(context, '/AddTile',
                                  arguments: newTileParams);
                            },
                            child: Container(
                              width: width,
                              height: height / (height / 52),
                              decoration: BoxDecoration(
                                color: TileStyles.primaryColor,
                                borderRadius:
                                    BorderRadius.circular(height / (height / 6)),
                              ),
                              child: Center(
                                child: Text(
                                  'Create',
                                  style: TextStyle(
                                    fontFamily: TileStyles.rubikFontName,
                                    fontSize: height / (height / 15),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 100,
                          ),
                        ],
                      )
              ],
            )
          : SizedBox.shrink();

      Widget LoadingState = SizedBox(
          height: height / (height / 450),
          width: width,
          child: Center(
            child: PendingWidget(
              imageAsset: TileStyles.evaluatingScheduleAsset,
            ),
          ));
      return isLoading ? LoadingState : loadedState;
    }

    @override
    Widget build(BuildContext context) {
      double height = MediaQuery.of(context).size.height;
      double width = MediaQuery.of(context).size.width;

      return CancelAndProceedTemplateWidget(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.forecast,
            style: TextStyle(
                color: TileStyles.appBarTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: height / (height / 25),
            ),
            // margin: TileStyles.topMargin,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                SizedBox(
                  height: height / (height / 40),
                ),

                // Custom Fields
                generateDeadline(width, height),
                generateDurationPicker(width, height),
                resultComponent(width, height),
                // End
              ],
            ),
          ),
        ),
      );
    }

    @override
    void dispose() {
      date.dispose();
      _durationController.close();
      _dateTimeController.close();
      _eventController.close();
      super.dispose();
    }
  }
