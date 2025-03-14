import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDate.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class NameAndDateSheetWidget extends StatefulWidget {
  final Function? onAddTileShare;
  final Function? onCancel;
  final String? name;
  final DateTime? endTime;
  final PreferredSizeWidget? appBar;
  NameAndDateSheetWidget(
      {this.onAddTileShare,
      this.onCancel,
      this.name,
      this.endTime,
      this.appBar});
  @override
  TileShareClusterSheetState createState() => TileShareClusterSheetState();
}

class TileShareClusterSheetState extends State<NameAndDateSheetWidget> {
  late List<Contact> contacts = [];
  String? tileName;
  DateTime? endTime;
  final double modalHeight = 216;
  @override
  void initState() {
    super.initState();
    tileName = this.widget.name;
    endTime = this.widget.endTime;
  }

  void onNameChange(String? name) {
    setState(() {
      tileName = name;
    });
  }

  void onTimeUpdate(DateTime? updatedEndTime) {
    setState(() {
      endTime = updatedEndTime;
    });
  }

  Widget renderEndtime() {
    if (endTime != null) {
      return EditTileDate(
        time: endTime!,
        onInputChange: onTimeUpdate,
        textStyle: const TextStyle(
            // fontSize: 20,
            fontFamily: TileStyles.rubikFontName),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_month,
            color: TileStyles.iconColor,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                    fontSize: 20, fontFamily: TileStyles.rubikFontName),
              ),
              onPressed: () async {
                DateTime _endDate = this.endTime ?? Utility.currentTime();

                DateTime firstDate = _endDate.add(Duration(days: -180));
                DateTime lastDate = _endDate.add(Duration(days: 180));
                final DateTime? revisedEndDate = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  helpText: AppLocalizations.of(context)!.selectADeadline,
                );
                if (revisedEndDate != null) {
                  setState(() => endTime = revisedEndDate);
                }
              },
              child: Text(
                AppLocalizations.of(context)!.deadline,
                style: endTime == null
                    ? TextStyle(
                        fontFamily: TileStyles.rubikFontName,
                        color: TileStyles.inactiveTextColor)
                    : TextStyle(
                        fontFamily: TileStyles.rubikFontName,
                        color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Container heightSpacer = Container(
      color: Colors.white,
      child: const ColoredBox(
        color: Colors.white,
      ),
    );
    return Container(
      alignment: Alignment.bottomCenter,
      width: MediaQuery.sizeOf(context).width,
      // height: modalHeight,
      color: Colors.transparent,
      margin: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          this.widget.appBar ?? SizedBox.shrink(),
          Container(
            color: Colors.white,
            child: EditTileName(
              tileName: tileName ?? "",
              onInputChange: onNameChange,
              width: MediaQuery.sizeOf(context).width,
              textStyle: TextStyle(
                  fontSize: 15,
                  fontFamily: TileStyles.rubikFontName,
                  color: Color.fromRGBO(31, 31, 31, 1)),
            ),
          ),
          heightSpacer,
          Container(color: Colors.white, child: renderEndtime()),
          heightSpacer,
          tileName != this.widget.name || endTime != this.widget.endTime
              ? Container(
                  width: MediaQuery.sizeOf(context).width,
                  color: Colors.white,
                  child: ElevatedButton.icon(
                      onPressed: () {
                        if ((tileName.isNot_NullEmptyOrWhiteSpace() &&
                                tileName != this.widget.name) ||
                            endTime != this.widget.endTime) {
                          if (this.widget.onAddTileShare != null) {
                            NameAndEndTimeUpdate nameAndEndTimeUpdate =
                                NameAndEndTimeUpdate();
                            nameAndEndTimeUpdate.Name = tileName;
                            nameAndEndTimeUpdate.EndTime = endTime;
                            this.widget.onAddTileShare!(nameAndEndTimeUpdate);
                          }
                        }
                      },
                      style: TileStyles.enabledButtonStyle,
                      icon: Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)!.update)),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}

class NameAndEndTimeUpdate {
  String? Name;
  DateTime? EndTime;
}
