import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/contactListView.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/designatedTileApi.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileShareTemplateDetailWidget extends StatefulWidget {
  final TileShareTemplate tileShareTemplate;
  final bool isReadOnly;
  TileShareTemplateDetailWidget(
      {required this.tileShareTemplate, this.isReadOnly = true});

  @override
  _TileShareTemplateDetailState createState() =>
      _TileShareTemplateDetailState();
}

class _TileShareTemplateDetailState
    extends State<TileShareTemplateDetailWidget> {
  late final TileShareClusterApi clusterApi;
  late final DesignatedTileApi designatedTileApi;
  late TileShareTemplate tileShareTemplate;
  late TileShareClusterData tileShareCluster;
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

  bool hasTextChanged = false;
  String? noteResult = null;
  String? focusedText = null;
  TextEditingController noteFieldController = TextEditingController();
  FocusNode notesFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    clusterApi = TileShareClusterApi(getContextCallBack: () => this.context);
    designatedTileApi =
        DesignatedTileApi(getContextCallBack: () => this.context);

    isTileListLoading = false;
    isLoading = false;
    tileShareTemplate = this.widget.tileShareTemplate;
    isLoading = true;
    getTileShareTemplate();
    designatedUsers = this.tileShareTemplate.designatedUsers ?? [];
    designatedUsersToContact = {};
    designatedUsers.forEach((element) {
      Contact? eachContact = element.toContact();
      if (eachContact != null) {
        designatedUsersToContact[eachContact] = element;
      }
    });
    noteFieldController.addListener(() {
      onNoteFieldChange();
    });
    notesFieldFocusNode.addListener(() {
      onNoteFieldOutOfFocus();
    });
  }

  void onNoteFieldChange() {
    if (noteFieldController.text != noteResult) {
      setState(() {
        noteResult = noteFieldController.text;
        hasTextChanged = true;
      });
    }
  }

  void onNoteFieldOutOfFocus() {
    Utility.debugPrint("Focus detected");
    String? priorFocusText = focusedText;
    focusedText = this.noteFieldController.text;
    if (hasTextChanged &&
        !notesFieldFocusNode.hasFocus &&
        priorFocusText != focusedText) {
      hasTextChanged = false;
      ClusterTemplateTileModel dateUpdated = ClusterTemplateTileModel();
      dateUpdated.Id = tileShareTemplate.id;
      dateUpdated.NoteMiscData = noteResult;
      this.clusterApi.updateTileShareTemplate(dateUpdated).then((value) {
        return getTileShareTemplate(silentRefresh: true);
      });
    }
  }

  Future updateDeadline(DateTime deadline) {
    ClusterTemplateTileModel dateUpdated = ClusterTemplateTileModel();
    dateUpdated.Id = tileShareTemplate.id;
    dateUpdated.EndTime = deadline.millisecondsSinceEpoch;
    return this.clusterApi.updateTileShareTemplate(dateUpdated).then((value) {
      return getTileShareTemplate(silentRefresh: false);
    });
  }

  Future getTileShareTemplate({bool silentRefresh = false}) async {
    bool tileLoadingState = false;
    var updateAllData = (value) {
      tilerError = null;
      tileShareTemplate = value[0];
      noteResult = tileShareTemplate.miscData?.userNote;
      if (noteResult != null) {
        noteFieldController.value = TextEditingValue(text: noteResult!);
      }
      isLoading = false;
      designatedUsers = value.first.designatedUsers ?? [];
      designatedUsersToContact = {};
      designatedUsers.forEach((element) {
        Contact? eachContact = element.toContact();
        if (eachContact != null) {
          designatedUsersToContact[eachContact] = element;
        }
      });
    };
    var setToNonLoading = () {
      isLoading = false;
      tilerError = null;
      isTileListLoading = false;
      tileLoadingState = false;
    };

    var setToLoading = () {
      isLoading = true;
      tilerError = null;
      isTileListLoading = tileLoadingState;
    };
    if (this.widget.tileShareTemplate.id.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareTemplates(
              tileShareTemplateId: this.widget.tileShareTemplate.id!,
              Format: "full")
          .then((List<TileShareTemplate> value) {
        if (value.isNotEmpty) {
          Utility.debugPrint("Success getting tile cluster");
          if (silentRefresh == false) {
            setState(() {
              tileShareTemplate = value[0];
              tilerError = null;
              updateAllData(value);
            });
          } else {
            updateAllData(value);
          }
        } else {
          setState(() {
            tilerError = TilerError(
                Message:
                    AppLocalizations.of(context)!.failedToLoadTileShareCluster);
          });
        }
      }).catchError((onError) {
        Utility.debugPrint("Failed to get tile cluster");
        setState(() {
          tilerError = TilerError(
              Message:
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
        Utility.debugPrint("Success getting tileShare list ");
        if (silentRefresh) {
          setToNonLoading();
        } else {
          setState(() {
            setToNonLoading();
            isLoading = false;
          });
        }
      }).catchError((onError) {
        Utility.debugPrint("Error getting tileShare list ");
        setState(() {
          if (onError is TilerError) {
            tilerError = onError;
          }
          tilerError = TilerError(
              Message: AppLocalizations.of(context)!.errorLoadingTilelist);
          isTileListLoading = false;
        });
      });
    }
    isTileListLoading = tileLoadingState;
    if (silentRefresh) {
      setToLoading();
    } else {
      setState(() {
        setToLoading();
      });
    }
  }

  Widget renderAuthorization() {
    throw UnimplementedError();
  }

  Widget renderError() {
    return Text(this.tilerError?.Message ?? "Error loading tilelist");
  }

  Widget renderNotFound() {
    return Text("Resource not found");
  }

  Widget renderTileShareCluster() {
    if (this.tileShareTemplate == null) {
      this.tilerError = TilerError(
          Message: AppLocalizations.of(context)!.missingTileShareCluster);
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
                  GestureDetector(
                    onTap: () async {
                      final DateTime? revisedEndDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.fromMillisecondsSinceEpoch(
                            tileShareTemplate.end ?? Utility.msCurrentTime),
                        firstDate: DateTime.fromMillisecondsSinceEpoch(
                            tileShareTemplate.start ?? 0),
                        lastDate:
                            Utility.currentTime().add(Duration(days: 1000)),
                        helpText: AppLocalizations.of(context)!.selectADeadline,
                      );
                      if (revisedEndDate != null) {
                        if (revisedEndDate.millisecondsSinceEpoch !=
                            tileShareTemplate.end) {
                          updateDeadline(revisedEndDate).then((value) {
                            tileShareTemplate.end =
                                revisedEndDate.millisecondsSinceEpoch;
                          });
                        }
                      }
                    },
                    child: Text(
                      MaterialLocalizations.of(context).formatFullDate(
                          DateTime.fromMillisecondsSinceEpoch(
                              tileShareTemplate.end!)),
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
              ),
            verticalSpacer,
            Expanded(
              child: addContacts(),
            ),
            verticalSpacer,
            Expanded(
              child: addNotes(),
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
                        getTileShareTemplate();
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
              getTileShareTemplate();
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
                getTileShareTemplate();
              });
            }
          }
        }
      },
    );
  }

  Widget addNotes() {
    return TextFormField(
      minLines: 5,
      maxLines: 10,
      controller: noteFieldController,
      focusNode: notesFieldFocusNode,
      decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.tileShareNoteEllipsis),
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
