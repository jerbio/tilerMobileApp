import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/tileDetail.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
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
  final TileShareClusterApi tileClusterApi = TileShareClusterApi();
  final ScheduleApi scheduleApi = ScheduleApi();
  String _responseMessage = '';
  late DesignatedTile designatedTile;
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
        // padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
        padding: EdgeInsets.all(0),
        foregroundColor: defaultColor);
    if (isSelected) {
      retValue = ElevatedButton.styleFrom(
          // padding: EdgeInsets.fromLTRB(lrPadding, 5, lrPadding, 5),
          padding: EdgeInsets.all(0),
          backgroundColor: defaultColor,
          foregroundColor: Colors.white);
    }
    return retValue;
  }

  Widget renderButtons() {
    const double iconSize = 10;
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

  Widget designatedTileDetails() {
    const double fontSize = 10;
    const spaceDivider = SizedBox(height: 5);
    const supplementalTextStyle =
        TextStyle(fontSize: 8, fontFamily: TileStyles.rubikFontName);
    String? designatedUsename = designatedTile.user?.username;
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
          if (designatedTile.invitationStatus ==
              InvitationStatus.accepted.name.toString())
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: FaIcon(
                        FontAwesomeIcons.binoculars,
                        color: TileStyles.primaryColor,
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
                if (this.designatedTile.id.isNot_NullEmptyOrWhiteSpace())
                  ElevatedButton.icon(
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
                          : SizedBox.shrink())
              ],
            )
          else
            SizedBox.shrink()
        ],
      ),
    );
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
