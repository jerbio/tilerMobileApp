import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/nameAndDateSheetWidget.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/simpleTileShareTemplareWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareTemplateDetail.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
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
  late TileShareClusterApi tileClusterApi;
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
    tileClusterApi =
        TileShareClusterApi(getContextCallBack: () => this.context);
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

  Future updateTileShareTemplate(TileShareTemplate tileShareTemplate,
      {String? clusterName, DateTime? deadline}) {
    if (tileShareTemplate == null) {
      return Future.value(null);
    }
    ClusterTemplateTileModel dateUpdated = ClusterTemplateTileModel();
    dateUpdated.Id = tileShareTemplate.id;
    dateUpdated.EndTime = deadline?.millisecondsSinceEpoch;
    dateUpdated.Name = clusterName;
    return tileClusterApi.updateTileShareTemplate(dateUpdated).then((value) {
      return getTileShareTemplates();
    });
  }

  void displayDialog(TileShareTemplate tileShareTemplate) {
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
                endTime: tileShareTemplate.end != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        tileShareTemplate.end!)
                    : null,
                name: tileShareTemplate.name,
                onAddTileShare: (NameAndEndTimeUpdate? update) {
                  Navigator.pop(context);
                  if (update != null) {
                    setState(() {
                      isLoading = true;
                    });
                    updateTileShareTemplate(tileShareTemplate,
                            clusterName: update.Name, deadline: update.EndTime)
                        .then((value) {
                      return this
                          .tileClusterApi
                          .getTileShareTemplates(clusterId: this.clusterId)
                          .then((value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            for (int i = 0;
                                i < tileShareTemplates.length;
                                i++) {
                              if (tileShareTemplates[i]
                                      .id
                                      .isNot_NullEmptyOrWhiteSpace() &&
                                  tileShareTemplates[i].id ==
                                      tileShareTemplate.id) {
                                setState(() {
                                  tileShareTemplates[i] = value.first;
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

  generateEditTileShareCallBack(TileShareTemplate tileShareTemplate) {
    return (BuildContext context) {
      if (tileShareTemplate.id.isNot_NullEmptyOrWhiteSpace()) {
        displayDialog(tileShareTemplate);
      }
    };
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
            if (tileShareTemplates[index].id == null) {
              return SizedBox.shrink();
            }
            String tileShareTemplateId = tileShareTemplates[index].id!;
            TileShareTemplate tileShareTemplate = tileShareTemplates[index];
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
                child: Slidable(
                    // Specify a key if the Slidable is dismissible.
                    key: ValueKey<String>(tileShareTemplateId),

                    // The end action pane is the one at the right or the bottom side.
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      dismissible: DismissiblePane(onDismissed: () {
                        tileClusterApi
                            .deleteTileShareTemplate(tileShareTemplateId)
                            .whenComplete(
                                () => getTileShareTemplates(resetList: false));
                      }),
                      children: [
                        SlidableAction(
                          onPressed:
                              generateEditTileShareCallBack(tileShareTemplate),
                          backgroundColor: TileColors.accentColor,
                          foregroundColor: TileColors.primaryContrastColor,
                          icon: Icons.edit,
                          label: AppLocalizations.of(context)!.edit,
                        ),
                        SlidableAction(
                          onPressed: (context) {
                            tileClusterApi
                                .deleteTileShareTemplate(tileShareTemplateId)
                                .whenComplete(() =>
                                    getTileShareTemplates(resetList: true));
                            ;
                          },
                          backgroundColor: TileColors.deletedBackgroundColor,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: AppLocalizations.of(context)!.tileShareDelete,
                        ),
                      ],
                    ),
                    child: TileShareTemplateSimpleWidget(
                      tileShareTemplate: tileShareTemplates[index],
                    )));
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
