import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareTemplateListWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class MultiTiletteTileShareDetailWidget extends StatefulWidget {
  late final TileShareClusterData tileShareClusterData;
  bool isReadOnly;
  MultiTiletteTileShareDetailWidget(
      {required this.tileShareClusterData, this.isReadOnly = true});
  @override
  _MultiTiletteTileShareDetailWidget createState() =>
      _MultiTiletteTileShareDetailWidget();
}

class _MultiTiletteTileShareDetailWidget
    extends State<MultiTiletteTileShareDetailWidget> {
  final TileShareClusterApi clusterApi = TileShareClusterApi();
  TileShareClusterData? tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  List<TileShareTemplate>? tileShareTemplateList = null;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 8);
  ScrollController _contactControllerfinal = ScrollController();

  @override
  void initState() {
    super.initState();
    isTileListLoading = false;
    if (this.widget.tileShareClusterData != null) {
      tileShareCluster = this.widget.tileShareClusterData;
      isLoading = true;
      getTileShareCluster();
    }
  }

  Future getTileShareCluster() async {
    bool tileLoadingState = false;
    if (this.widget.tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareClusters(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        Utility.debugPrint("Success getting tile cluster");
        setState(() {
          tilerError = null;
          tileShareCluster = value.firstOrNull;
          isLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Failed to get tile cluster");
        setState(() {
          tilerError = TilerError(
              message:
                  AppLocalizations.of(context)!.failedToLoadTileShareCluster);
          if (onError is TilerError) {
            tilerError = onError;
          }

          isLoading = false;
        });
      });

      clusterApi
          .getTileShareTemplates(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        setState(() {
          Utility.debugPrint("Success getting tileShareTemplate list ");
          tilerError = null;
          tileShareTemplateList = value;
          Utility.debugPrint("Success getting tileShareTemplate list " +
              tileShareTemplateList.toString());
          isTileListLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Error getting tileShare list ");
        setState(() {
          if (onError is TilerError) {
            tilerError = onError;
          }
          tilerError = TilerError(
              message: AppLocalizations.of(context)!.errorLoadingTilelist);
          isTileListLoading = false;
        });
      });
    }
    isTileListLoading = tileLoadingState;
    setState(() {
      isLoading = true;
      tilerError = null;
      isTileListLoading = tileLoadingState;
    });
  }

  Future updateDeadline(DateTime deadline) {
    if (tileShareCluster == null) {
      return Future.value(null);
    }
    TileShareClusterModel dateUpdated = TileShareClusterModel();
    dateUpdated.Id = tileShareCluster!.id;
    dateUpdated.EndTime = deadline.millisecondsSinceEpoch;
    return this.clusterApi.updateTileShareCluster(dateUpdated).then((value) {
      return getTileShareCluster();
    });
  }

  Widget renderAuthorization() {
    throw UnimplementedError();
  }

  Widget renderError() {
    return Text(this.tilerError?.message ?? "Error loading tilelist");
  }

  Widget renderNotFound() {
    return Text("Resource not found");
  }

  Widget _buildContactPill(Contact contact) {
    return Chip(
      avatar: Icon(
        (contact.phoneNumber.isNot_NullEmptyOrWhiteSpace()
            ? Icons.messenger_outline
            : Icons.email_outlined),
        color: TileStyles.primaryContrastColor,
      ),
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: null,
      side: BorderSide.none,
      backgroundColor: TileStyles.primaryColor,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  Widget renderTileShareCluster() {
    if (this.tileShareCluster == null) {
      this.tilerError = TilerError(
          message: AppLocalizations.of(context)!.missingTileShareCluster);
      return renderError();
    }

    TileShareClusterData cluster = this.tileShareCluster!;
    String creatorInfo =
        cluster.creator?.username ?? cluster.creator?.email ?? "";
    return Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cluster.endTimeInMs != null && cluster.endTimeInMs! > 0)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),
                  rowSpacer,
                  GestureDetector(
                    onTap: () async {
                      final DateTime? revisedEndDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.fromMillisecondsSinceEpoch(
                            cluster.endTimeInMs ?? Utility.msCurrentTime),
                        firstDate: DateTime.fromMillisecondsSinceEpoch(
                            cluster.startTimeInMs ?? 0),
                        lastDate:
                            Utility.currentTime().add(Duration(days: 1000)),
                        helpText: AppLocalizations.of(context)!.selectADeadline,
                      );
                      if (revisedEndDate != null) {
                        if (revisedEndDate.millisecondsSinceEpoch !=
                            cluster.endTimeInMs) {
                          updateDeadline(revisedEndDate).then((value) {
                            cluster.endTimeInMs =
                                revisedEndDate.millisecondsSinceEpoch;
                          });
                        }
                      }
                    },
                    child: Text(
                      MaterialLocalizations.of(context).formatFullDate(
                          DateTime.fromMillisecondsSinceEpoch(
                              cluster.endTimeInMs!)),
                      style: TileStyles.defaultTextStyle,
                    ),
                  )
                ],
              )
            else
              SizedBox.shrink(),
            verticalSpacer,
            if (creatorInfo.isNot_NullEmptyOrWhiteSpace())
              Row(
                children: [
                  Icon(
                    Icons.person_2_outlined,
                    size: 16,
                  ),
                  rowSpacer,
                  Text(
                      (creatorInfo.contains('@') ? '' : '@') + '${creatorInfo}',
                      style: TileStyles.defaultTextStyle)
                ],
              )
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator();
  }

  void renderModal(
      // {NewTile? currentTile}
      ) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        print("is pending " + isAddingTiletteLoading.toString());
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            height: 515,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Stack(
              children: <Widget>[
                NewTileSheetWidget(
                  onAddTile: (NewTile? newTile) {
                    if (newTile != null && tileShareCluster != null) {
                      setState(() {
                        isAddingTiletteLoading = true;
                      });
                      ClusterTemplateTileModel clusterTemplate =
                          newTile.toClusterTemplateTileModel();
                      clusterTemplate.ClusterId = tileShareCluster?.id;
                      clusterApi
                          .createDesignatedTileTemplate(clusterTemplate)
                          .then((value) {
                        getTileShareCluster();
                        setState(() {
                          isAddingTiletteLoading = false;
                        });
                        Navigator.pop(context);
                      }).catchError((onError) {
                        setState(() {
                          isAddingTiletteLoading = false;
                        });
                      });
                      setState(() {
                        isAddingTiletteLoading = true;
                      });
                    }
                  },
                  onCancel: () => {Navigator.pop(context)},
                ),
                if (isAddingTiletteLoading)
                  PendingWidget(
                    backgroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10))),
                    imageAsset: TileStyles.evaluatingScheduleAsset,
                  )
                else
                  SizedBox.shrink()
              ],
            ),
          ),
        );
      },
    );
  }

  Widget addTileShare() {
    return ElevatedButton.icon(
        style: TileStyles.enabledButtonStyle,
        onPressed: () {
          renderModal();
        },
        icon: Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addTilette));
  }

  @override
  Widget build(BuildContext context) {
    const double heightOfTileClusterDetails = 400;
    Widget? widgetContent = SizedBox.shrink();
    if (this.tilerError != null) {
      widgetContent = Center(child: renderError());
    } else if (this.isLoading == true || this.isTileListLoading == true) {
      widgetContent = Center(
        child: renderLoading(),
      );
    } else {
      widgetContent = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderTileShareCluster(),
            Divider(),
            if (this.isTileListLoading == true)
              CircularProgressIndicator()
            else
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height <
                            heightOfTileClusterDetails
                        ? heightOfTileClusterDetails
                        : MediaQuery.sizeOf(context).height -
                            heightOfTileClusterDetails,
                    child: TileShareTemplateListWidget(
                      isReadOnly: this.widget.isReadOnly,
                      tileShareTemplates:
                          this.tileShareTemplateList ?? <TileShareTemplate>[],
                    )),
              ),
            Divider(),
            Center(
              child: addTileShare(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: TileStyles.appBarColor,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.close,
              color: TileStyles.appBarTextColor,
            ),
          ),
          title: this.tileShareCluster?.name != null
              ? Text(
                  this.tileShareCluster?.name ??
                      AppLocalizations.of(context)!.tileShare,
                  style: TileStyles.titleBarStyle,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (this.tileShareCluster?.name == null)
                      Icon(
                        Icons.share,
                        color: TileStyles.appBarTextColor,
                      )
                    else
                      SizedBox.shrink(),
                    SizedBox.square(
                      dimension: 5,
                    ),
                    Text(
                      this.tileShareCluster?.name ??
                          AppLocalizations.of(context)!.tileShare,
                      style: TileStyles.titleBarStyle,
                    )
                  ],
                ),
        ),
        body: widgetContent);
  }
}
