import 'package:flutter/material.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
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
          tilerError = TilerError(message: "failed to load tile share cluster");
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
          tilerError = TilerError(message: "failed to load tile cluster list");
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
    if (this.tileShareCluster == null) {
      this.tilerError = TilerError(message: "Unknown Error");
      return renderError();
    }
    return TileShareWidget(tileShareCluster: this.tileShareCluster!);
  }

  Widget renderLoading() {
    return CircularProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    if (this.tilerError != null) {
      return renderError();
    }
    if (this.isLoading == true || this.isTileListLoading == true) {
      return renderLoading();
    }

    return Scaffold(
      body: Container(
        height: 500,
        child: Column(
          children: [
            renderTileShareCluster(),
            Divider(),
            if (this.isTileListLoading == true)
              CircularProgressIndicator()
            else
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: 300.0,
                child: DesignatedTileList(
                  designatedTiles:
                      this.designatedTileList ?? <DesignatedTile>[],
                ),
              )
          ],
        ),
      ),
    );
  }
}
