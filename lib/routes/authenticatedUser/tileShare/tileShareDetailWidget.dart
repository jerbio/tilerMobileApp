import 'package:flutter/material.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareSimpleWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileShareDetailWidget extends StatefulWidget {
  late final String? clusterId;
  late final TileShareClusterData? tileShareClusterData;
  TileShareDetailWidget.byId(String clusterId) {
    this.clusterId = clusterId;
    this.tileShareClusterData = null;
  }
  TileShareDetailWidget.byTileShareData(
      {required final TileShareClusterData tileShareClusterData}) {
    this.tileShareClusterData = tileShareClusterData;
    this.clusterId = null;
  }
  @override
  _TileShareDetailWidget createState() => _TileShareDetailWidget();
}

class _TileShareDetailWidget extends State<TileShareDetailWidget> {
  final TileShareClusterApi clusterApi = TileShareClusterApi();
  TileShareClusterData? tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  List<DesignatedTile>? designatedTileList = null;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );

  @override
  void initState() {
    super.initState();
    isTileListLoading = false;
    if (this.widget.tileShareClusterData != null) {
      isLoading = false;
      tileShareCluster = this.widget.tileShareClusterData;
    } else {
      isLoading = true;
      getTileShareCluster();
    }
  }

  Future getTileShareCluster() async {
    bool tileLoadingState = false;
    if (this.widget.clusterId.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareClusters(clusterId: this.widget.clusterId)
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
          .getDesignatedTiles(clusterId: this.widget.clusterId)
          .then((value) {
        setState(() {
          Utility.debugPrint("Success getting tileShare list ");
          tilerError = null;
          designatedTileList = value;
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
            SizedBox(height: 8),
            if (creatorInfo.isNot_NullEmptyOrWhiteSpace())
              Row(
                children: [
                  Icon(
                    Icons.person_2_outlined,
                    size: 16,
                  ),
                  rowSpacer,
                  Text('@${creatorInfo}', style: TileStyles.defaultTextStyle)
                ],
              ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              runSpacing: 8.0,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              children: [
                ...(cluster.contacts ?? [])
                    .map((contact) => _buildContactPill(contact))
                    .toList(),
              ],
            )
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator();
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
      widgetContent = Container(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderTileShareCluster(),
            Divider(),
            if (this.isTileListLoading == true)
              CircularProgressIndicator()
            else
              Padding(
                padding: EdgeInsets.all(15),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: 300.0,
                  child: DesignatedTileList(
                    designatedTiles:
                        this.designatedTileList ?? <DesignatedTile>[],
                  ),
                ),
              )
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
