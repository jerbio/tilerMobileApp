import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileForecast.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/tileDetail.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DesignatedTileWidget extends StatefulWidget {
  final DesignatedTile designatedTile;
  DesignatedTileWidget(this.designatedTile);

  @override
  State<StatefulWidget> createState() => _DesignatedWidgetState();
}

class _DesignatedWidgetState extends State<DesignatedTileWidget> {
  bool _isLoading = false;
  bool _isForeCastLoading = false;
  bool _isForeCastError = false;
  bool showNotes = false;
  bool showForecasts = false;
  final TileShareClusterApi tileClusterApi = TileShareClusterApi();
  final ScheduleApi scheduleApi = ScheduleApi();
  final WhatIfApi whatIfApi = WhatIfApi();
  String _responseMessage = '';
  late DesignatedTile designatedTile;
  ForecastResponse? forecastResponse = null;
  @override
  void initState() {
    super.initState();
    this.designatedTile = this.widget.designatedTile;
  }

  // Function to handle API calls with status updates
  Future<void> _statusUpdate(InvitationStatus status) async {
    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    try {
      if (this.designatedTile.id != null) {
        DesignatedTile? updatedDesignatedTile =
            await tileClusterApi.statusUpdate(this.designatedTile.id!, status);
        if (updatedDesignatedTile != null) {
          setState(() {
            this.designatedTile = updatedDesignatedTile;
          });
        }
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handlers for each button
  Future<void> _handleAccept() async {
    await _statusUpdate(InvitationStatus.accepted);
    tileClusterApi.analyzeSchedule().then((value) {
      return scheduleApi.buzzSchedule();
    });
  }

  Future<void> _handleDecline() async =>
      _statusUpdate(InvitationStatus.declined);
  Future<void> _handlePreview() async {
    setState(() {});
  }

  final double lrPadding = 12;
  ButtonStyle generateButtonStyle(bool isSelected, Color defaultColor) {
    ButtonStyle retValue = ElevatedButton.styleFrom(
        padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
        foregroundColor: defaultColor);
    if (isSelected) {
      retValue = ElevatedButton.styleFrom(
          padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
          backgroundColor: defaultColor,
          foregroundColor: Colors.white);
    }
    return retValue;
  }

  Widget renderButtons() {
    const double iconSize = 14;
    const buttonTextStyle =
        TextStyle(fontSize: 12, fontFamily: TileStyles.rubikFontName);
    if (_isLoading)
      return CircularProgressIndicator();
    else
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
                onPressed: _handleAccept,
                icon: Icon(
                  Icons.check,
                  size: iconSize,
                ),
                label: Text(AppLocalizations.of(context)!.accept,
                    style: buttonTextStyle),
                style: generateButtonStyle(
                    this.designatedTile.invitationStatus ==
                        InvitationStatus.accepted.name.toString(),
                    Colors.green)),
            ElevatedButton.icon(
                onPressed: _handleDecline,
                icon: Icon(Icons.close, size: iconSize),
                label: Text(
                  AppLocalizations.of(context)!.decline,
                  style: buttonTextStyle,
                ),
                style: generateButtonStyle(
                    this.designatedTile.invitationStatus ==
                        InvitationStatus.declined.name.toString(),
                    TileStyles.primaryColor)),
          ],
        ),
      );
  }

  Widget bottomNotes() {
    String noteText = "";
    if (this.designatedTile.tileTemplate?.miscData?.userNote != null) {
      noteText = this.designatedTile.tileTemplate!.miscData!.userNote!;
    }
    if (!noteText.isNot_NullEmptyOrWhiteSpace()) {
      return Text(AppLocalizations.of(context)!.ellipsisEmprtNotes);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(5)),
      ),
      padding: EdgeInsets.all(10),
      width: double.infinity,
      child: Text(noteText),
    );
  }

  Widget renderTileForeCast() {
    if (this.forecastResponse != null &&
        this.forecastResponse!.peekDays != null) {
      return TileForecast(forecastDays: this.forecastResponse!.peekDays!);
    }
    return SizedBox.shrink();
  }

  Widget bottomPanel() {
    if (this.showNotes) {
      return bottomNotes();
    }

    if (this.showForecasts) {
      return renderTileForeCast();
    }

    return SizedBox.shrink();
  }

  Widget designatedTileDetails() {
    const double fontSize = 10;
    const double iconSize = 14;
    const spaceDivider = SizedBox(height: 5);
    const supplementalTextStyle =
        TextStyle(fontSize: 8, fontFamily: TileStyles.rubikFontName);
    String? designatedUsename = designatedTile.user?.username;
    print(designatedTile.invitationStatus.toString());
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            designatedTile.name ?? "",
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: TileStyles.rubikFontName),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          spaceDivider,
          designatedTile.endTime != null
              ? Text(
                  AppLocalizations.of(context)!.deadlineTime(
                      DateFormat('d MMM').format(designatedTile.endTime!)),
                  style: supplementalTextStyle,
                )
              : SizedBox.shrink(),
          spaceDivider,
          designatedUsename.isNot_NullEmptyOrWhiteSpace()
              ? Row(
                  children: [
                    Text(
                      (designatedUsename!.contains('@') ? '' : '@') +
                          "$designatedUsename",
                      style: supplementalTextStyle,
                    ),
                    designatedTile.invitationStatus
                                .isNot_NullEmptyOrWhiteSpace() &&
                            designatedTile.invitationStatus!.toLowerCase() !=
                                InvitationStatus.none.name
                                    .toString()
                                    .toLowerCase() &&
                            designatedTile.isTilable == false
                        ? Container(
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  TileStyles.borderRadius),
                            ),
                            child: Text(
                              designatedTile.invitationStatus!.capitalize(),
                              style: TextStyle(
                                  fontSize: 8,
                                  fontFamily: TileStyles.rubikFontName,
                                  color: designatedTile.invitationStatus!
                                              .toLowerCase() ==
                                          InvitationStatus.accepted.name
                                              .toString()
                                              .toLowerCase()
                                      ? Colors.green
                                      : Colors.red),
                            ),
                          )
                        : SizedBox.shrink()
                  ],
                )
              : SizedBox.shrink(),
          spaceDivider,
          if (_responseMessage.isEmpty)
            SizedBox.shrink()
          else
            Text(
              _responseMessage,
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: TileStyles.rubikFontName),
            ),
          spaceDivider,
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: ElevatedButton(
                    child: FaIcon(
                      FontAwesomeIcons.noteSticky,
                      color: TileStyles.primaryColor,
                      size: iconSize,
                    ),
                    onPressed: () {
                      setState(() {
                        showNotes = !showNotes;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
              ),
              if (designatedTile.invitationStatus !=
                  InvitationStatus.accepted.name.toString())
                renderForeCastButton(iconSize),
              if (designatedTile.invitationStatus ==
                  InvitationStatus.accepted.name.toString()) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TileDetail.byDesignatedTileId(
                                      designatedTileTemplateId:
                                          this.designatedTile.id!,
                                      loadSubEvents: true,
                                    )));
                      },
                      icon: Icon(
                        Icons.style_outlined,
                        color: TileStyles.primaryColor,
                        size: iconSize,
                      ),
                      label: this.designatedTile.completionPercentage != null
                          ? Text(
                              "${this.designatedTile.completionPercentage!.round()}%",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: TileStyles.rubikFontName,
                                  color: this
                                              .designatedTile
                                              .completionPercentage! >
                                          66.66
                                      ? Colors.green
                                      : this
                                                  .designatedTile
                                                  .completionPercentage! >
                                              33.33
                                          ? Colors.orange
                                          : TileStyles.primaryColor),
                            )
                          : SizedBox.shrink()),
                ),
              ] else
                SizedBox.shrink(),
            ],
          ),
          spaceDivider,
          bottomPanel()
        ],
      ),
    );
  }

  onForeCastButtonPress() {
    setState(() {
      showForecasts = !showForecasts;
    });
    if (!_isForeCastLoading && showForecasts) {
      if (this.designatedTile.tileTemplate?.durationInMs != null &&
          this.designatedTile.tileTemplate?.end != null) {
        DateTime now = Utility.currentTime();
        int currentMinute = now.minute;
        int currentHour = now.hour;
        int currentDay = now.day;
        int currentMonth = now.month;
        int currentYear = now.year;
        Duration duration = Duration(
            milliseconds: this.designatedTile.tileTemplate!.durationInMs!);
        DateTime endTime = DateTime.fromMillisecondsSinceEpoch(
            this.designatedTile.tileTemplate!.end!);
        int endDay = endTime.day;
        int endMonth = endTime.month;
        int endYear = endTime.year;
        var durInHours = duration.inHours;
        var durrInMilliseconds = duration.inMilliseconds;
        // var durInUtc = durationToUtcString(duration);

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
          // "Duration": durInUtc.toString(),
        };

        setState(() {
          _isForeCastLoading = true;
          _isForeCastError = false;
        });
        whatIfApi.forecastNewTile(queryParams).then((value) {
          forecastResponse = value;
          setState(() {
            _isForeCastLoading = false;
            _isForeCastError = false;
          });
        }).catchError((error) {
          setState(() {
            _isForeCastError = true;
            _isForeCastLoading = false;
          });
        });
      }
    }
  }

  Widget renderForeCastButton(double iconSize) {
    if ((this.designatedTile.tileTemplate?.durationInMs != null &&
        this.designatedTile.tileTemplate?.end != null)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
        child: _isForeCastLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                child: FaIcon(
                  FontAwesomeIcons.binoculars,
                  color: TileStyles.primaryColor,
                  size: iconSize,
                ),
                onPressed: onForeCastButtonPress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            designatedTileDetails(),
            SizedBox.square(
              dimension: 8,
            ),
            if (this.designatedTile.isTilable == false)
              SizedBox.shrink()
            else
              renderButtons()
          ],
        ),
      ),
    );
  }
}
