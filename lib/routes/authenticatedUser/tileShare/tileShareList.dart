import 'package:flutter/material.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareSimpleWidget.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

class TileShareList extends StatefulWidget {
  final List<TileShareClusterData>? clusters;
  final bool? isOutBox;
  TileShareList({this.clusters, this.isOutBox});
  @override
  State<StatefulWidget> createState() => _TileShareListState();
}

class _TileShareListState extends State<TileShareList> {
  TileShareClusterApi tileClusterApi = TileShareClusterApi();
  ScrollController? _scrollController;
  int index = 0;
  final int pageSize = 10;
  bool hasMore = true;
  bool isLoading = false;
  List<TileShareClusterData> tileShareClusters = [];
  late bool isOubox;

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
        tileShareClusters =
            tileShareClusters.followedBy(nonNullTileShareClusters).toList();
        index = tileShareClusters.length;
        if (nonNullTileShareClusters.length < pageSize) {
          hasMore = false;
        }
      });
    }
  }

  Widget renderPending() {
    return Container(
      height: 40,
      alignment: AlignmentDirectional.topCenter,
      child: CircularProgressIndicator(),
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
                              CreateTileShareClusterWidget()));
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

  Widget renderBody() {
    int toBeRenderedElementCount = tileShareClusters.length;
    if (isLoading) {
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
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TileShareDetailWidget.byId(
                            tileShareClusters[index].id!)));
              },
              child: TileShareSimpleWidget(
                tileShareCluster: tileShareClusters[index],
              ),
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
