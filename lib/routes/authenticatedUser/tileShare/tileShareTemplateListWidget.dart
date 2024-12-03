import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/simpleTileShareTemplareWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareTemplateDetail.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/util.dart';

class TileShareTemplateListWidget extends StatefulWidget {
  static final String routeName = '/TileShareTemplateList';
  String? clusterId;
  bool isReadOnly;
  final List<TileShareTemplate>? tileShareTemplates;
  TileShareTemplateListWidget(
      {this.tileShareTemplates, this.isReadOnly = true});
  TileShareTemplateListWidget.byClusterId(
      {required String this.clusterId,
      this.tileShareTemplates,
      this.isReadOnly = true});
  @override
  State<StatefulWidget> createState() => _TileShareTemplateListState();
}

class _TileShareTemplateListState extends State<TileShareTemplateListWidget> {
  TileShareClusterApi tileClusterApi = TileShareClusterApi();
  List<TileShareTemplate> tileShareTemplates = [];
  ScrollController? _scrollController;
  int index = 0;
  final int pageSize = 5;
  bool hasMore = true;
  bool isLoading = false;
  ValueKey listKey = ValueKey(Utility.getUuid);
  @override
  void initState() {
    super.initState();
    if (this.widget.tileShareTemplates == null) {
      _scrollController = new ScrollController();
      getTileShareTemplates();
      _scrollController!.addListener(handleScrollToEnd);
    } else {
      tileShareTemplates = this.widget.tileShareTemplates!;
    }
  }

  String? get clusterId {
    return this.widget.clusterId ??
        this.tileShareTemplates.firstOrNull?.clusterId;
  }

  void getTileShareTemplates({bool resetList = false}) {
    if (this.clusterId.isNot_NullEmptyOrWhiteSpace()) {
      tileClusterApi
          .getTileShareTemplates(clusterId: this.clusterId)
          .then((value) {
        if (!resetList) {
          updateTileShareTemplates(updatedTileShareTemplates: value);
        } else {
          setState(() {
            this.tileShareTemplates = value;
            listKey = ValueKey(Utility.getUuid);
          });
        }
      }).whenComplete(() {
        setState(() {
          isLoading = false;
        });
      });
      setState(() {
        isLoading = true;
      });
    }
  }

  void handleScrollToEnd() {
    if (_scrollController == null) {
      while (_scrollController!.offset >=
              _scrollController!.position.maxScrollExtent &&
          !isLoading) {
        if (!isLoading) {
          getTileShareTemplates();
        }
      }
    }
  }

  void updateTileShareTemplates(
      {Iterable<TileShareTemplate?>? updatedTileShareTemplates}) {
    if (updatedTileShareTemplates != null) {
      List<TileShareTemplate> nonNullTileShareTemplates = [];
      (updatedTileShareTemplates).forEach((eachDesignatedTile) {
        if (eachDesignatedTile != null) {
          nonNullTileShareTemplates.add(eachDesignatedTile);
        }
      });
      setState(() {
        tileShareTemplates =
            tileShareTemplates.followedBy(nonNullTileShareTemplates).toList();
        index = tileShareTemplates.length;
        if (nonNullTileShareTemplates.length < pageSize) {
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
    int toBeRenderedElementCount = tileShareTemplates.length;
    if (isLoading) {
      toBeRenderedElementCount += 1;
    }
    if (toBeRenderedElementCount == 0) {
      return renderEmpty();
    }
    return ListView.builder(
        key: listKey,
        controller: _scrollController,
        itemCount: toBeRenderedElementCount,
        itemBuilder: (context, index) {
          if (index < tileShareTemplates.length) {
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TileShareTemplateDetailWidget(
                              isReadOnly: this.widget.isReadOnly,
                              tileShareTemplate: tileShareTemplates[index],
                            ))).then((value) {
                  getTileShareTemplates(resetList: true);
                });
              },
              child: TileShareTemplateSimpleWidget(
                tileShareTemplate: tileShareTemplates[index],
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
