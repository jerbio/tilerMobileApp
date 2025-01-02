import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareSimpleWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileShareList extends StatefulWidget {
  final List<TileShareClusterData>? clusters;
  final bool? isOutBox;
  TileShareList({this.clusters, this.isOutBox, Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _TileShareListState();
}

class _TileShareListState extends State<TileShareList>
    with SingleTickerProviderStateMixin {
  TileShareClusterApi tileClusterApi = TileShareClusterApi();
  ScrollController? _scrollController;
  int index = 0;
  final int pageSize = 10;
  bool hasMore = true;
  bool isLoading = false;
  List<TileShareClusterData> tileShareClusters = [];
  Set deletedTileShareIds = Set();
  late bool isOubox;

  late final controller = SlidableController(this);

  @override
  void initState() {
    super.initState();
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
    }
  }

  Future getTileShareCluster() async {
    tileClusterApi
        .getTileShareClusters(
            index: index, pageSize: pageSize, isOutbox: this.isOubox)
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
    if (_scrollController == null) {
      while (_scrollController!.offset >=
              _scrollController!.position.maxScrollExtent &&
          !isLoading) {
        if (!isLoading) {
          getTileShareCluster();
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
        tileShareClusters = [];
        for (var tileShare
            in tileShareClusters.followedBy(nonNullTileShareClusters)) {
          if (tileShare.id.isNot_NullEmptyOrWhiteSpace() &&
              !deletedTileShareIds.contains(tileShare.id!)) {
            tileShareClusters.add(tileShare);
          }
        }
        if (nonNullTileShareClusters.length < pageSize) {
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
    return Slidable(
        // Specify a key if the Slidable is dismissible.
        key: ValueKey<String>(tileShareClusterData.id ?? Utility.getUuid),

        // The end action pane is the one at the right or the bottom side.
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible: DismissiblePane(onDismissed: () {}),
          children: [
            SlidableAction(
              onPressed: deleteTileShare,
              backgroundColor: TileStyles.deletedBackgroundColor,
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
          color: TileStyles.deletedBackgroundColor,
          child: Icon(
            Icons.delete,
            color: TileStyles.primaryContrastColor,
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
        key: ValueKey(Utility.getUuid),
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
                  // ? renderDismissibleTileShare(tileShareClusters[index])
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
}
