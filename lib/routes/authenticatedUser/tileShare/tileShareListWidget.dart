import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tiler_app/components/nameAndDateSheetWidget.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDate.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareSimpleWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

class TileShareListWidget extends StatefulWidget {
  final List<TileShareClusterData>? clusters;
  final bool? isOutBox;
  TileShareListWidget({this.clusters, this.isOutBox, Key? key})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => _TileShareListWidgetState();
}

class _TileShareListWidgetState extends State<TileShareListWidget>
    with SingleTickerProviderStateMixin {
  late TileShareClusterApi tileClusterApi;

  ScrollController? _scrollController;
  int index = 0;
  final int requestPageSize = 10;
  bool hasMore = true;
  bool isLoading = false;
  List<TileShareClusterData> tileShareClusters = [];
  Set deletedTileShareIds = Set();
  late bool isOubox;

  late final controller = SlidableController(this);

  @override
  void initState() {
    super.initState();
    tileClusterApi =
        TileShareClusterApi(getContextCallBack: () => this.context);
    if (this.widget.isOutBox != null) {
      isOubox = this.widget.isOutBox!;
    } else {
      isOubox = false;
    }
    if (this.widget.clusters != null) {
      tileShareClusters = this.widget.clusters!;
      _scrollController = null;
    } else {
      _scrollController = ScrollController();
      this.getTileShareCluster();
      _scrollController!.addListener(handleScrollToEnd);
    }
    // handleScrollToEnd();
  }

  Future getTileShareCluster({int? pageIndex, int? pageSize}) async {
    tileClusterApi
        .getTileShareClusters(
            index: pageIndex ?? index,
            pageSize: pageSize ?? requestPageSize,
            isOutbox: this.isOubox)
        .then((value) {
      updateTileShareClusters(updatedTileShareClusters: value);
    }).whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
    setState(() {
      isLoading = true;
    });
  }

  void handleScrollToEnd() {
    if (_scrollController != null) {
      if (_scrollController!.offset >=
          _scrollController!.position.maxScrollExtent) {
        if (!isLoading) {
          getTileShareCluster(pageIndex: tileShareClusters.length);
        }
      }
    }
  }

  void updateTileShareClusters(
      {Iterable<TileShareClusterData?>? updatedTileShareClusters}) {
    if (updatedTileShareClusters != null) {
      List<TileShareClusterData> nonNullTileShareClusters = [];
      (updatedTileShareClusters).forEach((eachTileShareCluster) {
        if (eachTileShareCluster != null) {
          nonNullTileShareClusters.add(eachTileShareCluster);
        }
      });
      setState(() {
        Set<String> alreadyAddedId = Set.from(tileShareClusters
            .where((e) => e.id.isNot_NullEmptyOrWhiteSpace())
            .map((e) => e.id));
        for (var tileShare
            in tileShareClusters.followedBy(nonNullTileShareClusters)) {
          if (tileShare.id.isNot_NullEmptyOrWhiteSpace() &&
              !alreadyAddedId.contains(tileShare.id!) &&
              !deletedTileShareIds.contains(tileShare.id!)) {
            tileShareClusters.add(tileShare);
          }
        }
        if (nonNullTileShareClusters.length < requestPageSize) {
          hasMore = false;
        }
      });
    }
  }

  Widget renderPending() {
    return Container(
      height: 40,
      alignment: AlignmentDirectional.center,
      child: CircularProgressIndicator(),
    );
  }

  Widget renderEmptyPending() {
    return Center(
      child: Container(
        height: 40,
        alignment: AlignmentDirectional.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget renderEmpty() {
    if (this.isOubox == true) {
      return Center(
        child: Container(
            height: 40,
            alignment: AlignmentDirectional.topCenter,
            child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateTileShareClusterWidget())).whenComplete(() {
                    getTileShareCluster();
                  });
                },
                style: TileStyles.enabledButtonStyle,
                icon: Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.tileShare))),
      );
    }
    return Center(
      child: Container(
          height: 40,
          alignment: AlignmentDirectional.topCenter,
          child: Text(AppLocalizations.of(context)!.noDesignatedTiles)),
    );
  }

  Future updateShareCluster(TileShareClusterData tileShareCluster,
      {String? clusterName, DateTime? deadline}) {
    if (tileShareCluster == null) {
      return Future.value(null);
    }
    TileShareClusterModel dateUpdated = TileShareClusterModel();
    dateUpdated.Id = tileShareCluster.id;
    dateUpdated.EndTime = deadline?.millisecondsSinceEpoch;
    dateUpdated.Name = clusterName;
    return tileClusterApi.updateTileShareCluster(dateUpdated).then((value) {
      return getTileShareCluster();
    });
  }

  void displayDialog(TileShareClusterData cluster) {
    showModalBottomSheet<void>(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.transparent,
              child: NameAndDateSheetWidget(
                appBar: AppBar(
                  centerTitle: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  backgroundColor: TileColors.appBarColor,
                  title: Text(
                    AppLocalizations.of(context)!.edit,
                    style: TextStyle(
                        color: TileColors.appBarTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22),
                  ),
                ),
                endTime: cluster.endTimeInMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(cluster.endTimeInMs!)
                    : null,
                name: cluster.name,
                onAddTileShare: (NameAndEndTimeUpdate? update) {
                  Navigator.pop(context);
                  if (update != null) {
                    setState(() {
                      isLoading = true;
                    });
                    updateShareCluster(cluster,
                            clusterName: update.Name, deadline: update.EndTime)
                        .then((value) {
                      return this
                          .tileClusterApi
                          .getTileShareClusters(clusterId: cluster.id!)
                          .then((value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            for (int i = 0; i < tileShareClusters.length; i++) {
                              if (tileShareClusters[i]
                                      .id
                                      .isNot_NullEmptyOrWhiteSpace() &&
                                  tileShareClusters[i].id == cluster.id) {
                                setState(() {
                                  tileShareClusters[i] = value.first;
                                });
                                break;
                              }
                            }
                          });
                        }
                      });
                    }).whenComplete(() {
                      setState(() {
                        isLoading = false;
                      });
                    });
                  }
                },
              ));
        });
  }

  Widget renderSlidableTileShare(TileShareClusterData tileShareClusterData) {
    var deleteTileShare = (BuildContext context) {
      if (tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
        this
            .tileClusterApi
            .deleteCluster(tileShareClusterData.id!)
            .then((value) {
          getTileShareCluster().then((value) {
            setState(() {
              if (tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
                deletedTileShareIds.add(tileShareClusterData.id);
              }
              tileShareClusters.removeWhere((eachTileShareCluster) =>
                  eachTileShareCluster.id == tileShareClusterData.id);
            });
          });
        });
      }
    };

    var editTileShare = (BuildContext context) {
      if (tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
        displayDialog(tileShareClusterData);
      }
    };
    return Slidable(
        // Specify a key if the Slidable is dismissible.
        key: ValueKey<String>(tileShareClusterData.id ?? Utility.getUuid),

        // The end action pane is the one at the right or the bottom side.
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible: DismissiblePane(onDismissed: () {
            deleteTileShare(this.context);
          }),
          children: [
            SlidableAction(
              onPressed: editTileShare,
              backgroundColor: TileColors.accentColor,
              foregroundColor: TileColors.primaryContrastColor,
              icon: Icons.edit,
              label: AppLocalizations.of(context)!.edit,
            ),
            SlidableAction(
              onPressed: deleteTileShare,
              backgroundColor: TileColors.deletedBackgroundColor,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: AppLocalizations.of(context)!.tileShareDelete,
            ),
          ],
        ),
        child: TileShareSimpleWidget(
          tileShareCluster: tileShareClusterData,
          isReadOnly: true,
        ));
  }

  Widget renderDismissibleTileShare(TileShareClusterData tileShareClusterData) {
    Widget dismissibleSimpleTileShareWidget = Dismissible(
        direction: DismissDirection.endToStart,
        background: Container(
          padding: EdgeInsets.all(10),
          alignment: Alignment.centerRight,
          color: TileColors.deletedBackgroundColor,
          child: Icon(
            Icons.delete,
            color: TileColors.primaryContrastColor,
            size: 40,
          ),
        ),
        key: ValueKey<String>(tileShareClusterData.id ?? Utility.getUuid),
        onDismissed: (DismissDirection direction) {
          {
            if (tileShareClusterData.id.isNot_NullEmptyOrWhiteSpace()) {
              this
                  .tileClusterApi
                  .deleteCluster(tileShareClusterData.id!)
                  .then((value) {
                getTileShareCluster().then((value) {
                  setState(() {
                    tileShareClusters.removeWhere((eachTileShareCluster) =>
                        eachTileShareCluster.id == tileShareClusterData.id);
                  });
                });
              });
            }
          }
        },
        child: TileShareSimpleWidget(
          tileShareCluster: tileShareClusterData,
          isReadOnly: true,
        ));
    return dismissibleSimpleTileShareWidget;
  }

  Widget renderBody() {
    int toBeRenderedElementCount = tileShareClusters.length;
    if (isLoading) {
      if (toBeRenderedElementCount == 0) {
        return renderEmptyPending();
      }
      toBeRenderedElementCount += 1;
    }
    if (toBeRenderedElementCount == 0) {
      return renderEmpty();
    }

    return ListView.builder(
        controller: _scrollController,
        itemCount: toBeRenderedElementCount,
        itemBuilder: (context, index) {
          if (index < tileShareClusters.length) {
            Widget simpleTileShareWidget = TileShareSimpleWidget(
              tileShareCluster: tileShareClusters[index],
              isReadOnly: true,
            );

            return InkWell(
              key: ValueKey(Utility.getUuid),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TileShareDetailWidget.byId(
                              tileShareId: tileShareClusters[index].id!,
                              isOutBox: this.widget.isOutBox != false,
                            )));
              },
              child: isOubox
                  ? renderSlidableTileShare(tileShareClusters[index])
                  : simpleTileShareWidget,
            );
          }
          return renderPending();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: renderBody(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (this._scrollController != null) {
      this._scrollController!.dispose();
    }
  }
}
