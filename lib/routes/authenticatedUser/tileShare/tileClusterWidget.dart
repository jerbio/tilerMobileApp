import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/dateInput.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/components/textInputWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/tileClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/tileClusterApi.dart';
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
  final List<NewTile> _tileTemplates = <NewTile>[];
  final TileClusterApi tileClusterApi = TileClusterApi();
  DateTime? _endTime;
  Duration? _duration;
  Function? onProceedResponse;

  Widget clusterName() {
    var onClusterNameChange = (updatedValue) {
      tileClusterData.name = updatedValue;
      updateProceed();
    };
    return TextInputWidget(
      onTextChange: onClusterNameChange,
      value: tileClusterData.name,
    );
  }

  Future proceedRequest() {
    tileClusterData.contacts = contacts;
    tileClusterData.tileTemplates = _tileTemplates;
    tileClusterData.endTimeInMs = this._endTime?.millisecondsSinceEpoch;
    tileClusterData.startTimeInMs = Utility.msCurrentTime;
    return tileClusterApi.createCluster(tileClusterData);
  }

  void updateProceed() {
    if (_tileTemplates.length > 0 &&
        tileClusterData.name.isNot_NullEmptyOrWhiteSpace() &&
        tileClusterData.name!.trim().isNot_NullEmptyOrWhiteSpace()) {
      setState(() {
        onProceedResponse = proceedRequest;
      });
      return;
    }
    setState(() {
      onProceedResponse = null;
    });
  }

  void _removeTIle(NewTile newTile) {
    _tileTemplates.remove(newTile);
    updateProceed();
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
      onDeleted: () => _removeTIle(newTile),
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
          color: TileStyles.primaryContrastColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NewTileSheetWidget(
                  newTile: currentTile,
                  onAddTile: (newTile) {
                    if (currentTile == null) {
                      _tileTemplates.add(newTile);
                    }
                    updateProceed();
                    Navigator.pop(context);
                  },
                  onCancel: () => {Navigator.pop(context)},
                ),
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
              style: TileStyles.enabledButtonStyle,
              onPressed: () {
                renderModal();
              },
              icon: Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addTilette)),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ..._tileTemplates
                  .map((newTile) => _buildNewTilePill(newTile))
                  .toList(),
            ],
          )
        ],
      ),
    );
  }

  Widget addContacts() {
    return ContactInputFieldWidget(
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
    Widget deadlineContainer = DateInputWidget(
      placeHolder: AppLocalizations.of(context)!.deadline_anytime,
      time: this._endTime,
      onDateChange: (DateTime? updatedTime) {
        if (updatedTime != null) {
          setState(() {
            this._endTime = updatedTime;
          });
        }
      },
    );
    return deadlineContainer;
  }

  @override
  Widget build(BuildContext context) {
    Column response = Column(
      children: [
        clusterName(),
        duration(),
        deadline(),
        Divider(),
        Container(
          height: 200,
          child: addContacts(),
        ),
        Divider(),
        designatedTiles()
      ],
    );
    return CancelAndProceedTemplateWidget(
      child: response,
      onProceed: onProceedResponse,
    );
  }
}
