import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileWidget.dart';
import 'package:tiler_app/services/api/tileClusterApi.dart';

class DesignatedTileList extends StatefulWidget {
  static final String routeName = '/DesignatedTileList';
  @override
  State<StatefulWidget> createState() => _DesignatedTileListState();
}

class _DesignatedTileListState extends State<DesignatedTileList> {
  TileClusterApi tileClusterApi = TileClusterApi();
  List<DesignatedTile> designatedTiles = [];
  ScrollController _scrollController = new ScrollController();
  int index = 0;
  final int pageSize = 6;
  bool hasMore = true;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    getTiles();
    _scrollController.addListener(handleScrollToEnd);
  }

  void getTiles() {
    tileClusterApi
        .getDesignatedTiles(index: index, pageSize: pageSize)
        .then((value) {
      updateDesignatedTiles(updatedDesignatedTiles: value);
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
    while (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !isLoading) {
      if (!isLoading) {
        getTiles();
      }
    }
  }

  void updateDesignatedTiles(
      {Iterable<DesignatedTile?>? updatedDesignatedTiles}) {
    if (updatedDesignatedTiles != null) {
      List<DesignatedTile> nonNullDesignatedTiles = [];
      (updatedDesignatedTiles).forEach((eachDesignatedTile) {
        if (eachDesignatedTile != null) {
          nonNullDesignatedTiles.add(eachDesignatedTile);
        }
      });
      setState(() {
        designatedTiles =
            designatedTiles.followedBy(nonNullDesignatedTiles).toList();
        index = designatedTiles.length;
        if (nonNullDesignatedTiles.length < pageSize) {
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
    return Center(
      child: Container(
          height: 40,
          alignment: AlignmentDirectional.topCenter,
          child: Text(AppLocalizations.of(context)!.noDesignatedTiles)),
    );
  }

  Widget renderBody() {
    int toBeRenderedElementCount = designatedTiles.length;
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
          if (index < designatedTiles.length) {
            return DesignatedTileWidget(designatedTiles[index]);
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
