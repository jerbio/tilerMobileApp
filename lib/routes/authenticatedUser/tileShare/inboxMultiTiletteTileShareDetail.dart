import 'package:flutter/material.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme.dart';
import 'package:tiler_app/util.dart';

class InboxMultiTiletteTileShareDetailWidget extends StatefulWidget {
  late final TileShareClusterData tileShareClusterData;
  bool isReadOnly;
  InboxMultiTiletteTileShareDetailWidget(
      {required this.tileShareClusterData, this.isReadOnly = true});
  @override
  _InboxMultiTiletteTileShareDetailWidget createState() =>
      _InboxMultiTiletteTileShareDetailWidget();
}

class _InboxMultiTiletteTileShareDetailWidget
    extends State<InboxMultiTiletteTileShareDetailWidget> {
  late final TileShareClusterApi clusterApi;
  TileShareClusterData? tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;

  List<DesignatedTile>? designatedTileList = null;
  final rowSpacer = SizedBox.square(
    dimension: 4,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 4);
  ScrollController _contactControllerfinal = ScrollController();
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    clusterApi = TileShareClusterApi(getContextCallBack: () => this.context);
    isTileListLoading = false;
    if (this.widget.tileShareClusterData != null) {
      tileShareCluster = this.widget.tileShareClusterData;
      isLoading = true;
      getTileShareCluster();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  Future getTileShareCluster() async {
    bool tileLoadingState = false;
    if (this.widget.tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareClusters(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        setState(() {
          tilerError = null;
          tileShareCluster = value.firstOrNull;
          isLoading = false;
        });
      }).catchError((onError) {
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
          .getDesignatedTiles(clusterId: this.widget.tileShareClusterData.id)
          .then((value) {
        setState(() {
          tilerError = null;
          designatedTileList = value;
          isTileListLoading = false;
        });
      }).catchError((onError) {
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
    return Text(this.tilerError?.Message ?? "Error loading tilelist");
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
        color: colorScheme.onPrimary,
      ),
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: null,
      side: BorderSide.none,
      backgroundColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onPrimary),
    );
  }

  Widget renderTileShareCluster() {
    const double fontSize = 16;
    if (this.tileShareCluster == null) {
      this.tilerError = TilerError(
          Message: AppLocalizations.of(context)!.missingTileShareCluster);
      return renderError();
    }

    TileShareClusterData cluster = this.tileShareCluster!;
    String creatorInfo =
        cluster.creator?.username ?? cluster.creator?.email ?? "";
    return Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cluster.endTimeInMs != null && cluster.endTimeInMs! > 0)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colorScheme.onSurface,
                    size: fontSize,
                  ),
                  rowSpacer,
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(
                        DateTime.fromMillisecondsSinceEpoch(
                            cluster.endTimeInMs!)),
                    style: TileTextStyles.defaultText,
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
                    size: fontSize,
                    color: colorScheme.onSurface,
                  ),
                  rowSpacer,
                  Text(
                    (creatorInfo.contains('@') ? '' : '@') + '${creatorInfo}',
                    style: TileTextStyles.defaultText,
                  )
                ],
              ),
            verticalSpacer,
            Container(
              height: 50,
              child: ListView(
                controller: _contactControllerfinal,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...(cluster.contacts ?? [])
                          .map((contact) => _buildContactPill(contact))
                          .toList(),
                    ],
                  ),
                  // ContactListView(
                  //   contacts: cluster.contacts,
                  // )
                ],
              ),
            ),
            verticalSpacer,
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator(color: colorScheme.tertiary);
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
                    imageAsset: TileThemeNew.evaluatingScheduleAsset,
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

  //ey: not used
  Widget addTileShare() {
    return ElevatedButton.icon(
        style: TileButtonStyles.enabled(borderColor: colorScheme.primary),
        onPressed: () {
          renderModal();
        },
        icon: Icon(
          Icons.add,
          color: colorScheme.onSurface,
        ),
        label: Text(AppLocalizations.of(context)!.addTilette));
  }

  @override
  Widget build(BuildContext context) {
    const double heightOfTileClusterDetails = 319;
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
              CircularProgressIndicator(color: colorScheme.tertiary)
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
                    child: DesignatedTileList(
                      designatedTiles:
                          this.designatedTileList ?? <DesignatedTile>[],
                    )),
              )
          ],
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.onPrimary),
            onPressed: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.close,
            ),
          ),
          title: this.tileShareCluster?.name != null
              ? Text(
                  this.tileShareCluster?.name ??
                      AppLocalizations.of(context)!.tileShare,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (this.tileShareCluster?.name == null)
                      Icon(
                        Icons.share,
                      )
                    else
                      SizedBox.shrink(),
                    SizedBox.square(
                      dimension: 5,
                    ),
                    Text(
                      this.tileShareCluster?.name ??
                          AppLocalizations.of(context)!.tileShare,
                    )
                  ],
                ),
        ),
        body: widgetContent);
  }
}
