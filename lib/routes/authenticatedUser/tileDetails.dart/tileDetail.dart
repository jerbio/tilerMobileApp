import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/location/location_bloc.dart';
import 'package:tiler_app/bloc/location/location_state.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/routes/authenticatedUser/tileCarousel.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

class TileDetail extends StatefulWidget {
  final String tileId;
  TileDetail({required this.tileId});

  @override
  State<StatefulWidget> createState() => _TileDetailState();
}

class _TileDetailState extends State<TileDetail> {
  CalendarEvent? calEvent;
  List<SubCalendarEvent>? subEvents;
  EditCalendarEvent? editTilerEvent;
  int? splitCount;
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  TextEditingController? splitCountController;
  EditTileName? _editTileName;
  EditTileNote? _editTileNote;
  Duration? _tileDuration;
  Location? _location;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;
  Function? onProceed;
  String requestId = Utility.getUuid;
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();

  @override
  void initState() {
    super.initState();
    this
        .context
        .read<CalendarTileBloc>()
        .add(GetCalendarTileEvent(calEventId: this.widget.tileId));
    this.context.read<LocationBloc>().add(GetLocationEvent.byCalEventId(
        calEventId: this.widget.tileId, blocSessionId: requestId));
    this.context.read<SubCalendarTileBloc>().add(
        GetListOfCalendarTilesSubTilesBlocEvent(
            calEventId: this.widget.tileId, requestId: requestId));
  }

  void onInputCountChange() {
    dataChange();
  }

  void updateProceed() {
    if (editTilerEvent != null) {
      if (isProcrastinateTile) {
        bool timeIsTheSame =
            editTilerEvent!.startTime!.toLocal().millisecondsSinceEpoch ==
                    calEvent!.startTime.toLocal().millisecondsSinceEpoch &&
                editTilerEvent!.endTime!.toLocal().millisecondsSinceEpoch ==
                    calEvent!.endTime.toLocal().millisecondsSinceEpoch;

        bool isValidTimeFrame = Utility.utcEpochMillisecondsFromDateTime(
                editTilerEvent!.startTime!) <
            Utility.utcEpochMillisecondsFromDateTime(editTilerEvent!.endTime!);
        if (!timeIsTheSame && isValidTimeFrame) {
          setState(() {
            onProceed = calEventUpdate;
          });
          return;
        }
      }
      if (editTilerEvent!.isValid) {
        if (!Utility.isEditTileEventEquivalentToCalendarEvent(
            editTilerEvent!, this.calEvent!)) {
          setState(() {
            onProceed = calEventUpdate;
          });
          return;
        }
      }
    }
    setState(() {
      onProceed = null;
    });
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      lookupTimeline =
          lookupTimeline == null ? Utility.todayTimeline() : lookupTimeline;
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  Future<CalendarEvent> calEventUpdate() {
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    bool isLocationCleared = false;
    if (_location == null) {
      isLocationCleared = true;
    }
    if ((this.editTilerEvent!.address == null ||
            this.editTilerEvent!.address!.isEmpty) &&
        ((this.editTilerEvent!.addressDescription == null ||
            this.editTilerEvent!.addressDescription!.isEmpty))) {
      isLocationCleared = true;
    }

    if (this.calEvent!.address == editTilerEvent!.address &&
        this.calEvent!.addressDescription ==
            editTilerEvent!.addressDescription) {
      // this is a hack so there isn't a database refresh or check
      editTilerEvent!.address = null;
      editTilerEvent!.addressDescription = null;
      isLocationCleared = false;
      editTilerEvent!.isAddressVerified = null;
    }

    return this
        .calendarEventApi
        .updateCalEvent(this.editTilerEvent!, clearLocation: isLocationCleared)
        .then((value) {
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
      }
      return value;
    });
  }

  void dataChange() {
    if (editTilerEvent != null) {
      EditCalendarEvent revisedEditTilerEvent = editTilerEvent!;
      if (_editTileName != null && !isProcrastinateTile) {
        revisedEditTilerEvent.name = _editTileName!.name;
      }
      if (_editTileNote != null) {
        revisedEditTilerEvent.note = _editTileNote!.tileNote;
      }
      if (_editStartDateAndTime != null &&
          _editStartDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.startTime =
            _editStartDateAndTime!.dateAndTime!.toUtc();
      }

      if (_editEndDateAndTime != null &&
          _editEndDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.endTime =
            _editEndDateAndTime!.dateAndTime!.toUtc();
      }

      if (_tileDuration != null) {
        revisedEditTilerEvent.tileDuration = _tileDuration;
      }

      if (splitCountController != null && splitCountController != null) {
        revisedEditTilerEvent.splitCount =
            int.tryParse(splitCountController!.text);
      }

      if (_location != null && _location!.isNotNullAndNotDefault) {
        revisedEditTilerEvent.address = _location!.address;
        revisedEditTilerEvent.addressDescription = _location!.description;
        revisedEditTilerEvent.isAddressVerified = _location!.isVerified;
      } else {
        revisedEditTilerEvent.address = '';
        revisedEditTilerEvent.addressDescription = '';
      }
      updateProceed();
      setState(() {
        editTilerEvent = revisedEditTilerEvent;
      });
    }
  }

  bool get isProcrastinateTile {
    return (this.calEvent!.isProcrastinate ?? false);
  }

  bool get isRigidTile {
    return (this.calEvent!.isProcrastinate ?? false);
  }

  loadLocationRoute() {
    Location locationHolder = _location ?? Location.fromDefault();
    Map<String, dynamic> locationParams = {
      'location': locationHolder,
    };
    List<Location> defaultLocations = [];
    if (defaultLocations.isNotEmpty) {
      locationParams['defaults'] = defaultLocations;
    }

    Navigator.pushNamed(context, '/LocationRoute', arguments: locationParams)
        .whenComplete(() {
      Location? populatedLocation = locationParams['location'] as Location?;
      setState(() {
        if (populatedLocation != null &&
            populatedLocation.isNotNullAndNotDefault != null) {
          _location = populatedLocation;
          dataChange();
        }
      });
    });
  }

  Widget generateDurationPicker() {
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {
        'duration': _tileDuration,
        'initialDuration': _tileDuration
      };
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        print(durationParams['duration']);
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _tileDuration = populatedDuration;
          }
        });
        dataChange();
      });
    };
    String textButtonString = AppLocalizations.of(context)!.durationStar;
    if (_tileDuration != null && _tileDuration!.inMinutes > 1) {
      textButtonString = "";
      int hour = _tileDuration!.inHours.floor();
      int minute = _tileDuration!.inMinutes.remainder(60);
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
    Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
                border: Border.all(
                  color: textBorderColor,
                  width: 1.5,
                )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.timelapse_outlined, color: inputFieldIconColor),
                Container(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onPressed: setDuration,
                      child: Text(
                        textButtonString,
                        style: TextStyle(
                          fontFamily: TileStyles.rubikFontName,
                        ),
                      ),
                    ))
              ],
            )));
    return retValue;
  }

  Widget renderLocationTapable() {
    Function locationButton = (String locationString) {
      return Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        decoration: BoxDecoration(
            color: textBackgroundColor,
            borderRadius: const BorderRadius.all(
              const Radius.circular(8.0),
            ),
            border: Border.all(
              color: textBorderColor,
              width: 1.5,
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.location_pin, color: inputFieldIconColor),
            Container(
                padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  onPressed: loadLocationRoute,
                  child: Text(
                    locationString,
                    style: TextStyle(
                      fontFamily: TileStyles.rubikFontName,
                    ),
                  ),
                ))
          ],
        ),
      );
    };

    var locBlocState = this.context.read<LocationBloc>().state;
    return locBlocState.join((initial) {
      return locationButton(AppLocalizations.of(context)!.dashEmptyString);
    }, (locationLoading) {
      return locationButton(AppLocalizations.of(context)!.dashEmptyString);
    }, (locationLoaded) {
      String? locationString = _location?.description;
      if (locationString == null || locationString.isEmpty) {
        locationString = AppLocalizations.of(context)!.noLocation;
      }
      return locationButton(locationString);
    }, (locationLoadedError) {
      return locationButton(AppLocalizations.of(context)!.dashEmptyString);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<CalendarTileBloc, CalendarTileState>(
            listener: (context, state) {
              if (state is CalendarTileLoaded) {
                setState(() {
                  if (calEvent == null) {
                    calEvent = state.calEvent;
                    editTilerEvent = new EditCalendarEvent();
                    editTilerEvent!.endTime = calEvent!.endTime;
                    editTilerEvent!.startTime = calEvent!.startTime;
                    editTilerEvent!.splitCount = calEvent!.split;
                    editTilerEvent!.name = calEvent!.name ?? '';
                    editTilerEvent!.thirdPartyId = calEvent!.thirdpartyId;
                    editTilerEvent!.thirdPartyType = calEvent!.thirdpartyType;
                    editTilerEvent!.thirdPartyUserId =
                        calEvent!.thirdPartyUserId;
                    editTilerEvent!.id = calEvent!.id;
                    editTilerEvent!.calStartTime = Utility.currentTime();
                    editTilerEvent!.calEndTime = Utility.currentTime();
                    editTilerEvent!.isAutoReviseDeadline =
                        calEvent!.isAutoReviseDeadline;
                    editTilerEvent!.isAutoDeadline = calEvent!.isAutoDeadline;
                    editTilerEvent!.note = '';
                    editTilerEvent!.tileDuration = calEvent!.tileDuration;
                    _tileDuration = calEvent!.tileDuration;
                    if (calEvent!.noteData != null) {
                      editTilerEvent!.note = calEvent!.noteData!.note;
                    }
                    if (calEvent!.split != null) {
                      splitCount = calEvent!.split;
                      splitCountController =
                          TextEditingController(text: splitCount!.toString());
                      splitCountController!.addListener(onInputCountChange);
                      editTilerEvent!.splitCount = splitCount;
                    }
                    if (_location != null) {
                      calEvent!.address = _location!.address;
                      calEvent!.addressDescription = _location!.description;
                    }
                  }
                });
              }
            },
          ),
          BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
              listener: (context, state) {
            if (state is ListOfSubCalendarTileLoadedState) {
              if (state.requestId == requestId) {
                setState(() {
                  subEvents = state.subEvents;
                });
              }
            }
          }),
          BlocListener<LocationBloc, LocationState>(listener: (context, state) {
            if (state.blocSessionId != requestId) {
              return;
            }
            state.join((locationLoadingState) {
              setState(() {
                _location = null;
              });
            }, (locationLoading) {
              return;
            }, (locationLoaded) {
              setState(() {
                if (locationLoaded.locations != null &&
                    locationLoaded.locations!.isNotEmpty) {
                  _location = locationLoaded.locations!.first;
                  if (_location != null &&
                      _location!.isNotNullAndNotDefault &&
                      calEvent != null) {
                    calEvent!.address = _location!.address;
                    calEvent!.addressDescription = _location!.description;
                  }
                  return;
                }
                return;
              });
            }, (locationLoadError) {
              setState(() {
                _location = null;
              });
            });
          })
        ],
        child: CancelAndProceedTemplateWidget(
          onProceed: this.onProceed,
          appBar: AppBar(
            backgroundColor: TileStyles.primaryColor,
            title: Text(
              AppLocalizations.of(context)!.edit,
              style: TextStyle(
                  color: TileStyles.appBarTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 22),
            ),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          child: BlocBuilder<CalendarTileBloc, CalendarTileState>(
            builder: (context, state) {
              if (state is CalendarTileInitial ||
                  state is CalendarTileLoading ||
                  this.calEvent == null) {
                return PendingWidget();
              }
              String tileName =
                  this.editTilerEvent?.name ?? this.calEvent!.name ?? '';
              _editTileName = EditTileName(
                tileName: tileName,
                isProcrastinate: isProcrastinateTile,
                onInputChange: dataChange,
              );

              DateTime startTime =
                  this.editTilerEvent?.startTime ?? this.calEvent!.startTime;
              _editStartDateAndTime = EditDateAndTime(
                time: startTime,
                onInputChange: dataChange,
              );
              DateTime endTime =
                  this.editTilerEvent?.endTime ?? this.calEvent!.endTime;
              _editEndDateAndTime = EditDateAndTime(
                time: endTime,
                onInputChange: dataChange,
              );

              Widget? tileStartWidget;
              Widget? tileEndWidget;
              Widget? splitWidget;
              Widget? softDeadlineWidget;

              var inputChildWidgets = <Widget>[
                FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: _editTileName!),
              ];

              String tileNote = this.editTilerEvent?.note ??
                  this.calEvent!.noteData?.note ??
                  '';

              _editTileNote = EditTileNote(
                tileNote: tileNote,
                onInputChange: dataChange,
              );

              Widget durationWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: generateDurationPicker(),
                  ));

              Widget? locationWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: renderLocationTapable(),
                  ));
              if (!isRigidTile && !isProcrastinateTile) {
                if (this.editTilerEvent!.isAutoReviseDeadline != null) {
                  softDeadlineWidget = FractionallySizedBox(
                      widthFactor: TileStyles.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Text(
                                  AppLocalizations.of(context)!.softDeadline,
                                  style: TextStyle(
                                      color: Color.fromRGBO(31, 31, 31, 1),
                                      fontSize: 15,
                                      fontFamily: TileStyles.rubikFontName,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                              width: 50,
                              child: Switch(
                                value:
                                    this.editTilerEvent!.isAutoReviseDeadline!,
                                activeColor: TileStyles.primaryColor,
                                onChanged: (bool value) {
                                  setState(() {
                                    this.editTilerEvent!.isAutoReviseDeadline =
                                        value;
                                    dataChange();
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      ));
                }

                if (!this.calEvent!.isRecurring!) {
                  splitWidget = FractionallySizedBox(
                      widthFactor: TileStyles.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.split,
                                  style: TextStyle(
                                      color: Color.fromRGBO(31, 31, 31, 1),
                                      fontSize: 15,
                                      fontFamily: TileStyles.rubikFontName,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                              width: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                controller: splitCountController,
                              ),
                            )
                          ],
                        ),
                      ));

                  tileStartWidget = FractionallySizedBox(
                      widthFactor: TileStyles.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.start,
                                  style: TextStyle(
                                      color: Color.fromRGBO(31, 31, 31, 1),
                                      fontSize: 15,
                                      fontFamily: TileStyles.rubikFontName,
                                      fontWeight: FontWeight.w500)),
                            ),
                            _editStartDateAndTime!
                          ],
                        ),
                      ));
                  tileEndWidget = FractionallySizedBox(
                      widthFactor: TileStyles.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(AppLocalizations.of(context)!.end,
                                  style: TextStyle(
                                      color: Color.fromRGBO(31, 31, 31, 1),
                                      fontSize: 15,
                                      fontFamily: TileStyles.rubikFontName,
                                      fontWeight: FontWeight.w500)),
                            ),
                            _editEndDateAndTime!
                          ],
                        ),
                      ));
                }
              }

              if (_editTileNote != null) {
                inputChildWidgets.add(Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: _editTileNote!));
              }

              if (durationWidget != null) {
                inputChildWidgets.add(durationWidget);
              }

              if (locationWidget != null) {
                inputChildWidgets.add(locationWidget);
              }
              if (splitWidget != null) {
                inputChildWidgets.add(splitWidget);
              }
              if (softDeadlineWidget != null) {
                inputChildWidgets.add(softDeadlineWidget);
              }
              if (tileStartWidget != null) {
                inputChildWidgets.add(tileStartWidget);
              }
              if (tileEndWidget != null) {
                inputChildWidgets.add(tileEndWidget);
              }

              if (subEvents != null && subEvents!.length > 0) {
                inputChildWidgets.add(FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: TileCarousel(
                        subEvents: subEvents,
                      ),
                    )));
              }

              return Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
                margin: TileStyles.topMargin,
                alignment: Alignment.topCenter,
                child: ListView(
                  children: inputChildWidgets,
                ),
              );
            },
          ),
        ));
  }

  @override
  void dispose() {
    if (splitCountController != null) {
      splitCountController!.dispose();
    }
    super.dispose();
  }
}
