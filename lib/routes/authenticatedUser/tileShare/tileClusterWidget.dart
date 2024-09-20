import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/components/textInputWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/tileClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileClusterWidget extends StatefulWidget {
  final Function? onAddTileCluster;
  final Function? onAddingATileCluster;
  static final String routeName = '/TileCluster';
  TileClusterWidget({this.onAddTileCluster, this.onAddingATileCluster});
  @override
  TileClusterWidgetState createState() => TileClusterWidgetState();
}

class TileClusterWidgetState extends State<TileClusterWidget> {
  final TileClusterData tileClusterData = TileClusterData();
  final List<Contact> contacts = <Contact>[];
  final List<NewTile> _newTiles = <NewTile>[];
  DateTime? _endTime;
  Duration? _duration;
  Function? onProceedResponse;

  Widget clusterName() {
    var onClusterNameChange = (updatedValue) {
      tileClusterData.name = updatedValue;
    };
    return TextInputWidget(
      onTextChange: onClusterNameChange,
      value: tileClusterData.name,
    );
  }

  void _removeContact(NewTile newTile) {
    setState(() {
      _newTiles.remove(newTile);
    });
  }

  Widget _buildNewTilePill(NewTile newTile) {
    return Chip(
      label: GestureDetector(
        onTap: () {
          renderModal(currentTile: newTile);
        },
        child: Text(newTile.Name ?? ""),
      ),
      deleteIcon: Icon(Icons.close),
      onDeleted: () => _removeContact(newTile),
      backgroundColor: Colors.blueAccent.shade100,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  void renderModal({NewTile? currentTile}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.amber,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NewTileSheetWidget(
                  newTile: currentTile,
                  onAddTile: (newTile) {
                    if (currentTile == null) {
                      _newTiles.add(newTile);
                    }
                    setState(() {});
                    Navigator.pop(context);
                  },
                  onCancel: () => {Navigator.pop(context)},
                ),
                // ElevatedButton(
                //   child: const Text('Close BottomSheet'),
                //   onPressed: () => Navigator.pop(context),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget designatedTiles() {
    return Container(
      width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
      child: Column(
        children: [
          ElevatedButton.icon(
              onPressed: () {
                renderModal();
              },
              icon: Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addTile)),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ..._newTiles
                  .map((newTile) => _buildNewTilePill(newTile))
                  .toList(),
            ],
          )
        ],
      ),
    );
  }

  Widget addContacts() {
    return ContactInputField(
      onContactUpdate: (List<Contact> updatedContacts) {
        contacts.clear();
        for (var eachContact in updatedContacts) {
          contacts.add(eachContact);
        }
      },
    );
  }

  onDurationChange(Duration? duration) {
    setState(() {
      _duration = duration;
      Utility.debugPrint("duration val" + _duration.toString());
    });
  }

  Widget duration() {
    return DurationInputWidget(
      onDurationChange: onDurationChange,
      duration: _duration,
    );
  }

  void onEndDateTap() async {
    DateTime _endDate =
        this._endTime ?? Utility.todayTimeline().endTime.add(Utility.oneDay);
    if (this._endTime == null) {
      _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);
    }
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
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endDate.hour,
          _endDate.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  Widget deadline() {
    final Color textBackgroundColor = TileStyles.textBackgroundColor;
    final Color textBorderColor = TileStyles.textBorderColor;
    final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();
    String textButtonString = this._endTime == null
        ? AppLocalizations.of(context)!.deadline_anytime
        : DateFormat.yMMMd().format(this._endTime!);
    Widget deadlineContainer = new GestureDetector(
        onTap: this.onEndDateTap,
        child: FractionallySizedBox(
            widthFactor: TileStyles.widthRatio,
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
                    Icon(Icons.calendar_month, color: inputFieldIconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: onEndDateTap,
                          child: Text(
                            textButtonString,
                            style: TextStyle(
                              fontFamily: TileStyles.rubikFontName,
                            ),
                          ),
                        ))
                  ],
                ))));
    return deadlineContainer;
  }

  @override
  Widget build(BuildContext context) {
    Column response = Column(
      children: [clusterName(), designatedTiles(), duration(), deadline()],
    );
    return CancelAndProceedTemplateWidget(
      child: response,
      onProceed: onProceedResponse,
    );
  }
}
