import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show CameraPosition, GoogleMap, LatLng, MapType;
import 'package:lottie/lottie.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/animatedLine.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/components/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/executionEnums.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/styles.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart' as Constants;
import 'timeScrub.dart';

///
/// Class creates tile widget that handles rendering the tile UI for a given
/// user tile.
///
class TileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  TileWidgetState? _state;
  TileWidget(subEvent) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }
  @override
  TileWidgetState createState() {
    _state = TileWidgetState();
    return _state!;
  }
}

class TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  bool isMoreDetailEnabled = false;
  StreamSubscription? pendingScheduleRefresh;
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  Map<String, IconData> transitIconMap = {
    'driving': Icons.directions_car,
    'bicycling': Icons.directions_bike,
    'walking': Icons.directions_walk,
    'transit': Icons.directions_transit,
  };

  final ExpansionTileController expansionTravelController =
      ExpansionTileController();

  @override
  void initState() {
    if (this.widget.subEvent.isCurrentTimeWithin) {
      // this auto refreshes when tiles are getting close to the end time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (this.mounted) {
          int timeLeft = this.widget.subEvent.end! - Utility.msCurrentTime;

          Future onTileExpiredCallBack = Future.delayed(
              Duration(milliseconds: timeLeft.toInt()), callScheduleRefresh);
          // ignore: cancel_subscriptions
          StreamSubscription pendingSchedule =
              onTileExpiredCallBack.asStream().listen((_) {});
          setState(() {
            pendingScheduleRefresh = pendingSchedule;
          });
        }
      });
    }
    controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: Constants.animationDuration));
    fadeAnimation = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(controller);
    super.initState();
  }

  void updateSubEvent(SubCalendarEvent subEvent) async {
    this.widget.subEvent = subEvent;
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
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

  void callScheduleRefresh() {
    if (this.mounted) {
      this.context.read<ScheduleBloc>().add(GetScheduleEvent());
      refreshScheduleSummary();
    }
  }

  bool get isEditable {
    return !(this.widget.subEvent.isReadOnly ?? true);
  }

  bool get isTardy {
    return this.widget.subEvent.isTardy ?? false;
  }

  String longLatString(Location location) {
    return location.latitude.toString() + ',' + location.longitude.toString();
  }

  Future<void> _launchGoogleMaps(Location originLocation,
      Location destinationLocation, String travelMode) async {
    if (originLocation.isNotNullAndNotDefault &&
        destinationLocation.isNotNullAndNotDefault) {
      String origin = longLatString(originLocation);
      String destination = longLatString(destinationLocation);
      if (originLocation.address.isNot_NullEmptyOrWhiteSpace()) {
        origin = Uri.encodeComponent(originLocation.address!);
      }
      if (destinationLocation.address.isNot_NullEmptyOrWhiteSpace()) {
        destination = Uri.encodeComponent(destinationLocation.address!);
      }

      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=$travelMode');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  Widget travelLegToWidget(TravelLeg travelLeg) {
    String durationText = travelLeg.durationText ?? "";
    Widget retValue = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(transitIconMap[travelLeg.travelMedium] ?? Icons.directions_walk,
            color: TileStyles.primaryColor, size: 20),
        Flexible(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(
              travelLeg.description ?? "",
              style: TextStyle(
                  fontSize: 15,
                  fontFamily: TileStyles.rubikFontName,
                  fontWeight: FontWeight.normal,
                  color: TileStyles.defaultTextColor),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            durationText.isNot_NullEmptyOrWhiteSpace() ? "($durationText)" : "",
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.normal,
                color: TileStyles.defaultTextColor),
          ),
        )
      ],
    );
    return retValue;
  }

  Widget renderGoogleMaps(List<LatitudeAndLongitude> latLongList) {
    if (latLongList.isEmpty) {
      return SizedBox.shrink();
    }

    var travelAvgLocation = LatitudeAndLongitude.averageLatLong(latLongList);
    if (travelAvgLocation == null) {
      return SizedBox.shrink();
    }
    double mapHeight = 190;
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
          height: mapHeight,
          width: MediaQuery.sizeOf(context).width,
          child: GoogleMap(
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: false,
            myLocationEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  travelAvgLocation.latitude, travelAvgLocation.longitude),
              zoom: 14.0,
            ),
            mapType: MapType.normal,
          ),
        ),
        Container(
            height: mapHeight,
            width: MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TileStyles.defaultBackgroundColor
                    .withAlpha(0)
                    .withLightness(0.5),
                TileStyles.defaultBackgroundColor,
                TileStyles.defaultBackgroundColor,
                TileStyles.defaultBackgroundColor,
              ],
            )))
      ],
    );
  }

  Widget renderTravelTime(Timeline travelTimeLine) {
    double fontSize = 20;
    double iconSize = 20;
    double lottieHeight = 85;
    String lottieAsset =
        isTardy ? 'assets/lottie/redCars.json' : 'assets/lottie/blackCars.json';

    Color? textColor =
        isTardy ? TileStyles.lateTextColor : TileStyles.defaultTextColor;

    List<LatitudeAndLongitude> latLongList = [];
    Widget transitUIWidget = Lottie.asset(lottieAsset, height: lottieHeight);
    if (this.widget.subEvent.travelDetail != null) {
      TravelDetail travelDetail = this.widget.subEvent.travelDetail!;
      int walkCount = 0;
      int stopCount = 0;
      transitUIWidget = Lottie.asset(lottieAsset, height: lottieHeight);

      if (travelDetail.before != null) {
        if (travelDetail.before!.startLocation != null) {
          var longLat =
              travelDetail.before!.startLocation!.toLatitudeAndLongitude;
          if (longLat != null) {
            latLongList.add(longLat);
          }
        }
        if (travelDetail.before!.endLocation != null) {
          var longLat =
              travelDetail.before!.endLocation!.toLatitudeAndLongitude;
          if (longLat != null) {
            latLongList.add(longLat);
          }
        }
        if (travelDetail.before!.start != null &&
            travelDetail.before!.end != null) {
          travelTimeLine = Timeline.fromDateTimeAndDuration(
              DateTime.fromMillisecondsSinceEpoch(
                  travelDetail.before!.start!.toInt()),
              Duration(
                  milliseconds: travelDetail.before!.end!.toInt() -
                      travelDetail.before!.start!.toInt()));
        }
        if (travelDetail.before!.travelMedium ==
            TravelMedium.bicycling.name.toString().toLowerCase()) {
          String bicycleLottieAsset = isTardy
              ? 'assets/lottie/red-bicycle.json'
              : 'assets/lottie/black-bicycle.json';
          transitUIWidget =
              Lottie.asset(bicycleLottieAsset, height: lottieHeight);
        }
      }

      travelDetail.before?.travelLegs?.forEach((leg) {
        if (leg.travelMedium ==
            TravelMedium.transit.name.toString().toLowerCase()) {
          ++stopCount;
        } else if (leg.travelMedium ==
            TravelMedium.walking.name.toString().toLowerCase()) {
          ++walkCount;
        }
      });
      EdgeInsets trainsitUIPadding = EdgeInsets.all(5);
      if (walkCount > 0 || stopCount > 0) {
        fontSize = 15;
        iconSize = 15;
        List<Widget> travelWidgets = [];
        if (walkCount > 0) {
          travelWidgets.add(
            Container(
              padding: trainsitUIPadding,
              child: Row(
                children: [
                  Icon(Icons.directions_walk,
                      color: TileStyles.primaryContrastColor, size: iconSize),
                  Text(walkCount.toString(),
                      style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: TileStyles.rubikFontName,
                          fontWeight: FontWeight.normal,
                          color: TileStyles.primaryContrastColor))
                ],
              ),
            ),
          );
        }
        if (stopCount > 0) {
          travelWidgets.add(
            Container(
              padding: trainsitUIPadding,
              child: Row(
                children: [
                  Icon(Icons.directions_transit,
                      color: TileStyles.primaryContrastColor, size: iconSize),
                  Text(stopCount.toString(),
                      style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: TileStyles.rubikFontName,
                          fontWeight: FontWeight.normal,
                          color: TileStyles.primaryContrastColor))
                ],
              ),
            ),
          );
        }

        transitUIWidget = Container(
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: TileStyles.primaryColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: travelWidgets,
          ),
        );
        if (stopCount > 0 && travelDetail.before!.travelLegs != null) {
          transitUIWidget = Container(
            width: MediaQuery.sizeOf(context).width * 0.6,
            child: ExpansionTile(
              title: transitUIWidget,
              children: travelDetail.before!.travelLegs!
                  .map((leg) => travelLegToWidget(leg))
                  .toList(),
              controller: expansionTravelController,
            ),
          );
        }
      }
    }

    String startString = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(
            travelTimeLine.start!.toInt())));
    String endString = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(travelTimeLine.end!.toInt())));

    Widget retValue = InkWell(
      onTap: () {
        AnalysticsSignal.send('TRAVEL_TIME_TAP');
        if (this.widget.subEvent.travelDetail != null) {
          //this opens a redirect to google maps for directions to the location
          TravelDetail travelDetail = this.widget.subEvent.travelDetail!;
          Location originLocation =
              travelDetail.before?.startLocation ?? Location.fromDefault();
          Location destinationLocation =
              travelDetail.before?.endLocation ?? Location.fromDefault();
          _launchGoogleMaps(
              originLocation,
              destinationLocation,
              travelDetail.before?.travelMedium ??
                  TravelMedium.driving.name.toLowerCase());
        }
      },
      child: Stack(
        children: [
          renderGoogleMaps(latLongList),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: EdgeInsets.fromLTRB(2, 0, 0, 0),
                height: 50,
                width: 5,
                child: AnimatedLine(
                  Duration(milliseconds: 0),
                  textColor,
                  reverse: true,
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Text(startString,
                        style: TextStyle(
                            fontSize: fontSize,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.normal,
                            color: textColor))),
                transitUIWidget,
                Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(endString,
                        style: TextStyle(
                            fontSize: fontSize,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.normal,
                            color: textColor)))
              ],
            ),
            Container(
                padding: EdgeInsets.fromLTRB(2, 0, 0, 0),
                height: 50,
                width: 5,
                child: AnimatedLine(
                  Duration(milliseconds: 0),
                  textColor,
                  reverse: true,
                ))
          ])
        ],
      ),
    );

    return retValue;
  }

  Widget renderTileElement() {
    var subEvent = widget.subEvent;
    int redColor = subEvent.colorRed == null ? 127 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 127 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 127 : subEvent.colorGreen!;
    var tileBackGroundColor =
        Color.fromRGBO(redColor, greenColor, blueColor, 1);
    bool isEditable = (!(this.widget.subEvent.isReadOnly ?? true));

    Widget editButton = IconButton(
        icon: Icon(
          Icons.edit_outlined,
          color: TileStyles.defaultTextColor,
          size: 20.0,
        ),
        onPressed: () {
          if (isEditable) {
            AnalysticsSignal.send('SUB_TILE_EDIT');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EditTile(
                          tileId: (this.widget.subEvent.isFromTiler
                                  ? this.widget.subEvent.id
                                  : this.widget.subEvent.thirdpartyId) ??
                              "",
                          tileSource: this.widget.subEvent.thirdpartyType,
                          thirdPartyUserId:
                              this.widget.subEvent.thirdPartyUserId,
                        )));
          }
        });

    List<Widget> allElements = [
      Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        child: Stack(
          children: [
            TileName(widget.subEvent),
            Positioned(
              top: -10,
              right: -10,
              child: isEditable ? editButton : SizedBox.shrink(),
            )
          ],
        ),
      )
    ];

    if (this.widget.subEvent.travelTimeBefore != null &&
        this.widget.subEvent.travelTimeBefore! > 0 &&
        this.widget.subEvent.isToday) {
      Duration duration = Duration();
      if (this.widget.subEvent.isCurrent) {
        int durationTillTravel = (this.widget.subEvent.end! -
                this.widget.subEvent.travelTimeBefore!.toInt()) -
            Utility.msCurrentTime;
        duration = Duration(milliseconds: durationTillTravel);
      }
      if (duration.inMilliseconds > 0) {
        allElements.add(Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: TravelTimeBefore(duration, subEvent)));
      }
    }

    if (widget.subEvent.address != null &&
            widget.subEvent.address!.isNotEmpty ||
        subEvent.searchdDescription != null &&
            subEvent.searchdDescription!.isNotEmpty) {
      var addressWidget = Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TileAddress(widget.subEvent));
      allElements.insert(1, addressWidget);
    }

    Widget tileTimeFrame = Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          // Icon container
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
            width: 25,
            height: 25,
            decoration: TileStyles.tileIconContainerBoxDecoration,
            child: Icon(
              (this.widget.subEvent.isRigid ?? false)
                  ? Icons.lock_outline
                  : Icons.access_time_sharp,
              color: isTardy
                  ? TileStyles.lateTextColor
                  : TileStyles.defaultTextColor,
              size: TileStyles.tileIconSize,
            ),
          ),

          // Text
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: TimeFrameWidget(
              timeRange: widget.subEvent,
              textColor: isTardy
                  ? TileStyles.lateTextColor
                  : TileStyles.defaultTextColor,
            ),
          ),
        ],
      ),
    );
    allElements.add(tileTimeFrame);
    if (widget.subEvent.tileShareDesignatedId.isNot_NullEmptyOrWhiteSpace()) {
      allElements.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TileShareDetailWidget.byDesignatedTileShareId(
                  designatedTileShareId: widget.subEvent.tileShareDesignatedId,
                ),
              ),
            );
          },
          child: Icon(
            Icons.share,
            size: 20,
          ),
        ),
      );
    }

    if (isEditable) {
      if (isMoreDetailEnabled || (this.widget.subEvent.isCurrent)) {
        // Timescrub to show that it is elapsed
        allElements.add(
          FractionallySizedBox(
            widthFactor: TileStyles.tileWidthRatio,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 15, 0, 10),
              child: TimeScrubWidget(
                timeline: widget.subEvent,
                isTardy: widget.subEvent.isTardy ?? false,
              ),
            ),
          ),
        );

        // Actions Pane for widgets
        allElements.add(
          Container(
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
            child: PlayBack(
              widget.subEvent,
              forcedOption: (widget.subEvent.isRigid == true
                  ? [PlaybackOptions.Delete]
                  : null),
            ),
          ),
        );

        allElements.add(GestureDetector(
            onTap: () {
              setState(() {
                isMoreDetailEnabled = false;
              });
            },
            child: Icon(
              Icons.arrow_drop_up,
              size: 30,
            )));
      } else {
        allElements.add(
          GestureDetector(
            onTap: () {
              setState(() {
                isMoreDetailEnabled = true;
              });
            },
            child: Icon(
              Icons.arrow_drop_down,
              size: 30,
            ),
          ),
        );
      }
    }

    return AnimatedSize(
      duration: Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      child: Container(
        margin: (this.widget.subEvent.isCurrentTimeWithin ||
                this.isMoreDetailEnabled)
            ? EdgeInsets.fromLTRB(0, 20, 0, 20)
            : EdgeInsets.fromLTRB(0, 5, 0, 5),
        child: Material(
          type: MaterialType.transparency,
          child: FractionallySizedBox(
            widthFactor: TileStyles.tileWidthRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: this.widget.subEvent.isViable!
                      ? Colors.white
                      : Colors.black,
                  width: this.widget.subEvent.isViable! ? 0 : 5,
                ),
                borderRadius: BorderRadius.circular(TileStyles.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: tileBackGroundColor.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.5,
                    center: Alignment.bottomRight,
                    colors: <Color>[
                      tileBackGroundColor.withLightness(0.65),
                      tileBackGroundColor.withLightness(0.675),
                      tileBackGroundColor.withLightness(0.70),
                      tileBackGroundColor.withLightness(0.75),
                      tileBackGroundColor.withLightness(0.75),
                      tileBackGroundColor.withLightness(0.75),
                      tileBackGroundColor.withLightness(0.75),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(TileStyles.borderRadius),
                ),
                child: Column(
                  mainAxisAlignment: allElements.length < 4
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
                  children: allElements,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [renderTileElement()];

    if (this.widget.subEvent.travelTimeBefore != null &&
        this.widget.subEvent.travelTimeBefore! > 0.0) {
      Duration travelDuration = Duration(
          milliseconds: this.widget.subEvent.travelTimeBefore!.toInt());
      Timeline travelTimeLine = Timeline.fromDateTimeAndDuration(
          this.widget.subEvent.startTime.add(-travelDuration), travelDuration);
      Widget travelTimeWidget = renderTravelTime(travelTimeLine);
      columnChildren.insert(0, travelTimeWidget);
    }
    return Column(
      children: columnChildren,
    );
  }

  @override
  void dispose() {
    if (this.pendingScheduleRefresh != null) {
      this.pendingScheduleRefresh!.cancel();
    }
    super.dispose();
  }
}
