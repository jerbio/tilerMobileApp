import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

class DesignatedTileWidget extends StatefulWidget {
  final DesignatedTile designatedTile;
  DesignatedTileWidget(this.designatedTile);

  @override
  State<StatefulWidget> createState() => _DesignatedWidgetState();
}

class _DesignatedWidgetState extends State<DesignatedTileWidget> {
  bool _isLoading = false;
  late final TileShareClusterApi tileClusterApi;
  late final ScheduleApi scheduleApi;
  late final WhatIfApi whatIfApi;
  bool _isForeCastLoading = false;
  bool _isForeCastError = false;
  bool showNotes = false;
  bool showForecasts = false;
  String _responseMessage = '';
  late DesignatedTile designatedTile;
  ForecastResponse? forecastResponse = null;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    super.initState();
    tileClusterApi = TileShareClusterApi(getContextCallBack: () {
      return this.context;
    });
    scheduleApi = ScheduleApi(getContextCallBack: () {
      return this.context;
    });
    whatIfApi = WhatIfApi(getContextCallBack: () {
      return this.context;
    });
    this.designatedTile = this.widget.designatedTile;
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  // Function to handle API calls with status updates
  Future<void> _statusUpdate(InvitationStatus status) async {
    if (_isLoading) {
      return;
    }
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
          foregroundColor: colorScheme.onPrimary);
    }
    return retValue;
  }

  Widget renderButtons() {
    const double iconSize = 14;
    const buttonTextStyle =
        TextStyle(
          fontSize: 12,
          fontFamily: TileTextStyles.rubikFontName,
        );
    if (_isLoading)
      return CircularProgressIndicator(color: colorScheme.tertiary);
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
                    TileColors.acceptedTileShare)),
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
                    colorScheme.primary)),
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
        color: tileThemeExtension.surfaceContainerGreater,
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
    const double fontSize = 14;
    const double iconSize = 14;
    const spaceDivider = SizedBox(height: 5);
    const supplementalTextStyle =
        TextStyle(
            fontSize: 11.6,
            fontFamily: TileTextStyles.rubikFontName
        );
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
                fontFamily: TileTextStyles.rubikFontName
            ),
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
                                  TileDimensions.borderRadius),
                            ),
                            child: Text(
                              designatedTile.invitationStatus!.capitalize(),
                              style: TextStyle(
                                  fontSize: 8,
                                  fontFamily: TileTextStyles.rubikFontName,
                                  color: designatedTile.invitationStatus!
                                              .toLowerCase() ==
                                          InvitationStatus.accepted.name
                                              .toString()
                                              .toLowerCase()
                                      ? TileColors.acceptedTileShare
                                      : colorScheme.error),
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
                  color: TileColors.responseTileShare,
                  fontWeight: FontWeight.bold,
                  fontFamily: TileTextStyles.rubikFontName
              ),
            ),
          spaceDivider,
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: ElevatedButton(
                    child: FaIcon(
                      FontAwesomeIcons.noteSticky,
                      color: colorScheme.primary,
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
                        color: colorScheme.primary,
                        size: iconSize,
                      ),
                      label: this.designatedTile.completionPercentage != null
                          ? Text(
                              "${this.designatedTile.completionPercentage!.round()}%",
                              style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 10,
                                  color: this
                                              .designatedTile
                                              .completionPercentage! >
                                          66.66
                                      ? TileColors.acceptedTileShare
                                      : this
                                                  .designatedTile
                                                  .completionPercentage! >
                                              33.33
                                          ? TileColors.progressMedium
                                          : colorScheme.primary),
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
        this.designatedTile.tileTemplate?.end != null &&
        this.designatedTile.tileTemplate!.end! > Utility.msCurrentTime)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
        child: _isForeCastLoading
            ? CircularProgressIndicator(color: colorScheme.tertiary)
            : ElevatedButton(
                child: FaIcon(
                  FontAwesomeIcons.binoculars,
                  color: colorScheme.primary,
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
