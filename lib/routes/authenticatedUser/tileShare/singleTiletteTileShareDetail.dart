import 'package:flutter/material.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/contactListView.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class SingleTiletteTileShareDetailWidget extends StatefulWidget {
  late final TileShareClusterData tileShareClusterData;
  bool isReadOnly;
  SingleTiletteTileShareDetailWidget(
      {required this.tileShareClusterData, this.isReadOnly = true});

  @override
  _SingleTiletteTileShareDetailWidget createState() =>
      _SingleTiletteTileShareDetailWidget();
}

class _SingleTiletteTileShareDetailWidget
    extends State<SingleTiletteTileShareDetailWidget> {
  late final TileShareClusterApi clusterApi;
  late final DesignatedTileApi designatedTileApi;
  late TileShareClusterData tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  List<DesignatedTile>? designatedTileList = null;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 8);
  late List<Contact> contacts;

  @override
  void initState() {
    super.initState();
    clusterApi = TileShareClusterApi(getContextCallBack: () => this.context);
    designatedTileApi =
        DesignatedTileApi(getContextCallBack: () => this.context);

    isTileListLoading = false;
    isLoading = false;
    tileShareCluster = this.widget.tileShareClusterData;
    isLoading = true;
    getTileShareCluster();
    contacts = this.tileShareCluster.contacts ?? [];
  }

  Future getTileShareCluster() async {
    bool tileLoadingState = false;
    if (this.widget.tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareClusters(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        if (value.isNotEmpty) {
          Utility.debugPrint("Success getting tile cluster");
          setState(() {
            tilerError = null;
            tileShareCluster = value.firstOrNull!;
            isLoading = false;
            contacts = value.first.contacts ?? [];
          });
        } else {
          setState(() {
            tilerError = TilerError(
                message:
                    AppLocalizations.of(context)!.failedToLoadTileShareCluster);
          });
        }
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
          .getDesignatedTiles(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        setState(() {
          Utility.debugPrint(
              "Success getting tileShare list - Single tilette  ");
          tilerError = null;
          designatedTileList = value;
          isTileListLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Error getting tileShare list - Single tilette ");
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
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(
                        DateTime.fromMillisecondsSinceEpoch(
                            cluster.endTimeInMs!)),
                    style: TileStyles.defaultTextStyle,
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
              ),
            verticalSpacer,
            Expanded(
              child: addContacts(),
            )
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator();
  }

  void renderModal() {
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
                NewTileShareSheetWidget(
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

  Widget addContacts() {
    return ContactListView(
      isReadOnly: this.widget.isReadOnly,
      contacts: (contacts).toList(),
      onContactListUpdate: (List<Contact> updatedContacts) {
        Set<Contact> newContacts = Set();
        Set<Contact> removedContacts = Set();
        updatedContacts.forEach((eachContact) {
          if (!contacts
                  .where((element) =>
                      element.phoneNumber.isNot_NullEmptyOrWhiteSpace())
                  .any((element) =>
                      element.phoneNumber == eachContact.phoneNumber) &&
              !contacts
                  .where(
                      (element) => element.email.isNot_NullEmptyOrWhiteSpace())
                  .any((element) => element.email == eachContact.email)) {
            newContacts.add(eachContact);
          }
        });

        contacts.forEach((eachContact) {
          if (!updatedContacts
                  .where((element) =>
                      element.phoneNumber.isNot_NullEmptyOrWhiteSpace())
                  .any((element) =>
                      element.phoneNumber == eachContact.phoneNumber) &&
              !updatedContacts
                  .where(
                      (element) => element.email.isNot_NullEmptyOrWhiteSpace())
                  .any((element) => element.email == eachContact.email)) {
            removedContacts.add(eachContact);
          }
        });

        if (this.designatedTileList?.firstOrNull != null &&
            this.designatedTileList!.first.tileTemplate != null) {
          for (var newContact in newContacts) {
            if (this
                .designatedTileList!
                .first
                .tileTemplate!
                .id
                .isNot_NullEmptyOrWhiteSpace()) {
              designatedTileApi.addContact(
                  this.designatedTileList!.first.tileTemplate!.id!,
                  newContact.toContactModel());
            }
          }
          for (var deletedContact in removedContacts) {
            designatedTileApi.deleteContact(this.designatedTileList!.first.id!,
                deletedContact.toContactModel());
          }
        }

        setState(() {
          contacts = updatedContacts.toList();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          height: MediaQuery.sizeOf(context).height,
          child: renderTileShareCluster(),
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
          title: this.tileShareCluster.name != null
              ? Text(
                  this.tileShareCluster.name ??
                      AppLocalizations.of(context)!.tileShare,
                  style: TileStyles.titleBarStyle,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (this.tileShareCluster.name == null)
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
                      this.tileShareCluster.name ??
                          AppLocalizations.of(context)!.tileShare,
                      style: TileStyles.titleBarStyle,
                    )
                  ],
                ),
        ),
        body: widgetContent);
  }
}
