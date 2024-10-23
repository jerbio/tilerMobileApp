import 'package:flutter/material.dart';
import 'package:tiler_app/components/dateInput.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/components/textInputWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class CreateTileShareClusterWidget extends StatefulWidget {
  final bool? isMultiTilette;
  final Function? onAddTileCluster;
  final Function? onAddingTilette;
  static final String routeName = '/TileCluster';
  CreateTileShareClusterWidget(
      {this.onAddTileCluster, this.onAddingTilette, this.isMultiTilette});
  @override
  _CreateTileShareClusterWidgetState createState() =>
      _CreateTileShareClusterWidgetState();
}

class _CreateTileShareClusterWidgetState
    extends State<CreateTileShareClusterWidget> {
  final TileShareClusterData tileClusterData = TileShareClusterData();
  List<Contact> contacts = <Contact>[];
  final List<NewTile> _tileTemplates = <NewTile>[];
  final TileShareClusterApi tileClusterApi = TileShareClusterApi();
  DateTime? _endTime;
  Duration? _duration;
  Function? onProceedResponse;
  bool isMultiTilette = false;
  @override
  void initState() {
    super.initState();
    if (this.widget.isMultiTilette != null) {
      isMultiTilette = this.widget.isMultiTilette!;
    }
  }

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
    tileClusterData.isMultiTilette = this.isMultiTilette;
    return tileClusterApi.createCluster(tileClusterData);
  }

  void updateProceed() {
    Function? updatedProceed = null;
    if (tileClusterData.name.isNot_NullEmptyOrWhiteSpace(minLength: 3)) {
      if (!isMultiTilette) {
        if (this.contacts.isNotEmpty &&
            this._duration != null &&
            this._duration!.inMinutes > 0) {
          updatedProceed = proceedRequest;
        }
      } else {
        if (this._tileTemplates.isNotEmpty) {
          updatedProceed = proceedRequest;
        }
      }
    }
    setState(() {
      onProceedResponse = updatedProceed;
    });
  }

  void _removeTile(NewTile newTile) {
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
      onDeleted: () => _removeTile(newTile),
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
            updateProceed();
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
    updateProceed();
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

  Widget generatedTopRightButton() {
    if (this.isMultiTilette) {
      // if (onProceedResponse != null) {
      //   return ElevatedButton.icon(
      //       style: TileStyles.enabledButtonStyle,
      //       onPressed: () {
      //         if (onProceedResponse != null) {
      //           onProceedResponse!();
      //         }
      //         Navigator.of(context).pop(false);
      //       },
      //       icon: Icon(
      //         Icons.save,
      //         color: TileStyles.primaryContrastColor,
      //       ),
      //       label: SizedBox.shrink());
      // }
      return SizedBox.shrink();
    } else {
      return ElevatedButton.icon(
          style: TileStyles.enabledButtonStyle,
          onPressed: () {
            Navigator.of(context).pop(false);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateTileShareClusterWidget(
                          isMultiTilette: true,
                          onAddTileCluster: this.widget.onAddTileCluster,
                          onAddingTilette: this.widget.onAddingTilette,
                        )));
          },
          icon: TileStyles.multiShareWidget,
          label: SizedBox.shrink());
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> clusterInputWidgets = <Widget>[clusterName(), deadline()];
    Widget selectionButtonWidgets = generatedTopRightButton();

    if (!isMultiTilette) {
      var durationWidget = duration();
      clusterInputWidgets.insert((1), durationWidget);
      clusterInputWidgets.add(Divider());
      clusterInputWidgets.add(Container(
        height: 180,
        child: addContacts(),
      ));
    } else {
      clusterInputWidgets.add(Divider());
      clusterInputWidgets.add(designatedTiles());
    }

    Container tileShareWidgets = Container(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Column(
          children: clusterInputWidgets,
        ));
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
          // centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [selectionButtonWidgets],
          backgroundColor: TileStyles.appBarColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.share,
                color: TileStyles.appBarTextColor,
              ),
              Text(
                this.isMultiTilette
                    ? AppLocalizations.of(context)!.multiShare
                    : AppLocalizations.of(context)!.tileShare,
                style: TileStyles.titleBarStyle,
              )
            ],
          )),
      child: tileShareWidgets,
      onProceed: onProceedResponse,
    );
  }
}
