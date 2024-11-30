import 'package:flutter/material.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/contactListView.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileShareTemplateDetailWidget extends StatefulWidget {
  final TileShareTemplate tileShareTemplate;
  bool isReadOnly;
  TileShareTemplateDetailWidget(
      {required this.tileShareTemplate, this.isReadOnly = true});

  @override
  _TileShareTemplateDetailState createState() =>
      _TileShareTemplateDetailState();
}

class _TileShareTemplateDetailState
    extends State<TileShareTemplateDetailWidget> {
  final TileShareClusterApi clusterApi = TileShareClusterApi();
  final DesignatedTileApi designatedTileApi = DesignatedTileApi();
  late TileShareTemplate tileShareTemplate;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 8);
  late List<DesignatedUser> designatedUsers;
  Map<Contact, DesignatedUser> designatedUsersToContact = {};

  @override
  void initState() {
    super.initState();
    isTileListLoading = false;
    isLoading = false;
    tileShareTemplate = this.widget.tileShareTemplate;
    isLoading = true;
    getTileShareTemplates();
    designatedUsers = this.tileShareTemplate.designatedUsers ?? [];
    designatedUsersToContact = {};
    designatedUsers.forEach((element) {
      Contact? eachContact = element.toContact();
      if (eachContact != null) {
        designatedUsersToContact[eachContact] = element;
      }
    });
  }

  Future getTileShareTemplates() async {
    bool tileLoadingState = false;
    if (this.widget.tileShareTemplate.id.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareTemplates(
              tileShareTemplateId: this.widget.tileShareTemplate.id!)
          .then((value) {
        if (value.isNotEmpty) {
          Utility.debugPrint("Success getting tile cluster");
          setState(() {
            tilerError = null;
            tileShareTemplate = value.firstOrNull!;
            isLoading = false;
            designatedUsers = value.first.designatedUsers ?? [];
            designatedUsersToContact = {};
            designatedUsers.forEach((element) {
              Contact? eachContact = element.toContact();
              if (eachContact != null) {
                designatedUsersToContact[eachContact] = element;
              }
            });
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
          .getDesignatedTiles(clusterId: this.widget.tileShareTemplate.id)
          .then((value) {
        setState(() {
          Utility.debugPrint("Success getting tileShare list ");
          tilerError = null;
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

  Widget renderAuthorization() {
    throw UnimplementedError();
  }

  Widget renderError() {
    return Text(this.tilerError?.message ?? "Error loading tilelist");
  }

  Widget renderNotFound() {
    return Text("Resource not found");
  }

  Widget renderTileShareCluster() {
    if (this.tileShareTemplate == null) {
      this.tilerError = TilerError(
          message: AppLocalizations.of(context)!.missingTileShareCluster);
      return renderError();
    }

    String creatorInfo = tileShareTemplate.creator?.username ??
        tileShareTemplate.creator?.email ??
        "";
    return Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tileShareTemplate.end != null && tileShareTemplate.end! > 0)
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
                            tileShareTemplate.end!)),
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
                NewTileSheetWidget(
                  onAddTile: (NewTile? newTile) {
                    if (newTile != null && tileShareTemplate != null) {
                      setState(() {
                        isAddingTiletteLoading = true;
                      });
                      ClusterTemplateTileModel clusterTemplate =
                          newTile.toClusterTemplateTileModel();
                      clusterTemplate.ClusterId = tileShareTemplate?.id;
                      clusterApi
                          .createDesignatedTileTemplate(clusterTemplate)
                          .then((value) {
                        getTileShareTemplates();
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
      contacts: designatedUsersToContact.keys.toList(),
      onContactListUpdate: (List<Contact> updatedContacts) {
        Set<Contact> newContacts = Set();
        Set<Contact> removedContacts = Set();
        for (int i = 0; i < updatedContacts.length; i++) {
          Contact eachContact = updatedContacts[i];
          if (!designatedUsersToContact.keys
                  .toList()
                  .where((element) =>
                      element.phoneNumber.isNot_NullEmptyOrWhiteSpace())
                  .any((element) =>
                      element.phoneNumber == eachContact.phoneNumber) &&
              !designatedUsersToContact.keys
                  .toList()
                  .where(
                      (element) => element.email.isNot_NullEmptyOrWhiteSpace())
                  .any((element) => element.email == eachContact.email) &&
              !designatedUsersToContact.keys
                  .toList()
                  .where((element) =>
                      element.username.isNot_NullEmptyOrWhiteSpace())
                  .any((element) => element.username == eachContact.username)) {
            newContacts.add(eachContact);
          }
        }

        if (updatedContacts.length > 0) {
          List currentContacts = designatedUsersToContact.keys.toList();
          for (int i = 0; i < currentContacts.length; i++) {
            Contact eachContact = currentContacts[i];
            if (!updatedContacts
                    .where((element) =>
                        element.phoneNumber.isNot_NullEmptyOrWhiteSpace())
                    .any((element) =>
                        element.phoneNumber == eachContact.phoneNumber) &&
                !updatedContacts
                    .where((element) =>
                        element.email.isNot_NullEmptyOrWhiteSpace())
                    .any((element) => element.email == eachContact.email) &&
                !updatedContacts
                    .where((element) =>
                        element.username.isNot_NullEmptyOrWhiteSpace())
                    .any((element) =>
                        element.username == eachContact.username)) {
              removedContacts.add(eachContact);
            }
          }
        } else {
          removedContacts.addAll(designatedUsersToContact.keys);
        }

        if (this.tileShareTemplate.id != null) {
          for (var newContact in newContacts) {
            designatedTileApi
                .addContact(
                    this.tileShareTemplate.id!, newContact.toContactModel())
                .then((value) {
              getTileShareTemplates();
            });
            ;
          }
          for (var deletedContact in removedContacts) {
            if (designatedUsersToContact.containsKey(deletedContact) &&
                designatedUsersToContact[deletedContact] != null &&
                designatedUsersToContact[deletedContact]!
                    .designatedTileTemplateId
                    .isNot_NullEmptyOrWhiteSpace()) {
              designatedTileApi
                  .deleteContact(
                      designatedUsersToContact[deletedContact]!
                          .designatedTileTemplateId!,
                      deletedContact.toContactModel())
                  .then((value) {
                getTileShareTemplates();
              });
            }
          }
        }
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
          title: this.tileShareTemplate.name != null
              ? Text(
                  this.tileShareTemplate.name ??
                      AppLocalizations.of(context)!.tileShare,
                  style: TileStyles.titleBarStyle,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (this.tileShareTemplate.name == null)
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
                      this.tileShareTemplate.name ??
                          AppLocalizations.of(context)!.tileShare,
                      style: TileStyles.titleBarStyle,
                    )
                  ],
                ),
        ),
        body: widgetContent);
  }
}
