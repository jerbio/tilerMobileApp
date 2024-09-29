import 'package:flutter/material.dart';
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
  List<Contact> contacts = <Contact>[];
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
    return Padding(
      padding: TileStyles.inpuPadding,
      child: TextInputWidget(
        onTextChange: onClusterNameChange,
        value: tileClusterData.name,
        placeHolder: AppLocalizations.of(context)!.tileShareName,
      ),
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
      deleteIcon: Icon(
        Icons.close,
        color: TileStyles.primaryContrastColor,
      ),
      side: BorderSide.none,
      onDeleted: () => _removeTIle(newTile),
      backgroundColor: TileStyles.primaryColor,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  void renderModal({NewTile? currentTile}) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NewTileSheetWidget(
                  newTile: currentTile,
                  onAddTile: (newTile) {
                    if (currentTile == null) {
                      _tileTemplates.add(newTile);
                    } else {
                      int swapIndex = _tileTemplates.indexOf(currentTile);
                      if (swapIndex >= 0) {
                        _tileTemplates[swapIndex] = newTile;
                      }
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
    return ListView(
      children: [
        ContactInputFieldWidget(
          contentHeight: this.contacts.isEmpty
              ? 0
              : this.contacts.length < 3
                  ? 50
                  : 100,
          onContactUpdate: (List<Contact> updatedContacts) {
            // contacts.clear();
            // for (var eachContact in updatedContacts) {
            //   contacts.add(eachContact);
            // }
            setState(() {
              this.contacts = updatedContacts;
            });
          },
        )
      ],
    );
  }

  onDurationChange(Duration? duration) {
    setState(() {
      _duration = duration;
    });
  }

  Widget duration() {
    return Padding(
      padding: TileStyles.inpuPadding,
      child: DurationInputWidget(
        onDurationChange: onDurationChange,
        duration: _duration,
      ),
    );
  }

  Widget deadline() {
    Widget deadlineContainer = Padding(
      padding: TileStyles.inpuPadding,
      child: DateInputWidget(
        placeHolder: AppLocalizations.of(context)!.deadline_anytime,
        time: this._endTime,
        onDateChange: (DateTime? updatedTime) {
          if (updatedTime != null) {
            setState(() {
              this._endTime = updatedTime;
            });
          }
        },
      ),
    );
    return deadlineContainer;
  }

  @override
  Widget build(BuildContext context) {
    Container tileShareWidgets = Container(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Column(
          children: [
            clusterName(),
            duration(),
            deadline(),
            Divider(),
            Container(
              height: 180,
              child: addContacts(),
            ),
            Divider(),
            designatedTiles()
          ],
        ));
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TileStyles.appBarColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share,
              color: TileStyles.appBarTextColor,
            ),
            SizedBox.square(
              dimension: 5,
            ),
            Text(
              AppLocalizations.of(context)!.tileShare,
              style: TileStyles.titleBarStyle,
            )
          ],
        ),
      ),
      child: tileShareWidgets,
      onProceed: onProceedResponse,
    );
  }
}
