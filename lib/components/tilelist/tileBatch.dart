import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';

class TileBatch extends StatefulWidget {
  static final TextStyle dayHeaderTextStyle = TextStyle(
      fontSize: 40,
      fontFamily: TileStyles.rubikFontName,
      color: TileStyles.primaryColorDarkHSL.toColor(),
      fontWeight: FontWeight.w700);
  List<TilerEvent>? tiles;
  Timeline? sleepTimeline;
  String? header;
  String? footer;
  int? dayIndex;
  TimelineSummary? dayData;
  ConnectionState? connectionState;

  TileBatch(
      {this.header,
      this.footer,
      this.dayIndex,
      this.tiles,
      this.sleepTimeline,
      this.connectionState,
      this.dayData,
      Key? key})
      : super(key: key);

  @override
  TileBatchState createState() => TileBatchState();
}

class TileBatchState extends State<TileBatch> {
  String uniqueKey = Utility.getUuid;
  late bool isInitialLoad;
  Map<String, TilerEvent> renderedTiles = new Map<String, TilerEvent>();
  Map<String, TilerEvent>? pendingRenderedTiles;
  Map<String, TilerEvent> latestBuildTiles = new Map<String, TilerEvent>();
  Map<String, Tuple3<TilerEvent, int?, int?>>? orderedTiles;
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();
  List<Widget> childrenColumnWidgets = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _list;
  bool _pendingRendering = false;
  double _emptyDayOpacity = 0;
  final double daySummaryToHeightBuffer = 245;

  Timeline? sleepTimeline;
  TimelineSummary? _dayData;
  AnimatedList? animatedList;

  @override
  void initState() {
    super.initState();
    isInitialLoad = true;
    if (dayData == null && this.widget.dayIndex != null) {
      _dayData = TimelineSummary();
      _dayData!.dayIndex = this.widget.dayIndex;
    }
    if (this.widget.dayData != null) {
      _dayData = this.widget.dayData!;
    }
    _list = ListModel(listKey: _listKey, removedItemBuilder: _buildRemovedItem);
  }

  TimelineSummary? get dayData {
    return this._dayData;
  }

  void updateSleepTimelines(Timeline timeline) {
    this.setState(() {
      sleepTimeline = timeline;
      uniqueKey = uniqueKey + " || " + this.widget.dayIndex.toString();
    });
    // print('---sleep TL 0 -- ' +
    //     sleepTimeline!.startTime.toString() +
    //     ' - ' +
    //     uniqueKey);
  }

  Widget _buildRemovedItem(
      TilerEvent item, BuildContext context, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: TileWidget(item)),
    );
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter, child: TileWidget(_list![index])),
    );
  }

  evaluateTileDelta(Iterable<TilerEvent>? tiles) {
    if (orderedTiles == null) {
      orderedTiles = {};
    }

    if (tiles == null) {
      tiles = <TilerEvent>[];
    }
    List<TilerEvent> orderedByTimeTiles = tiles.toList();
    orderedByTimeTiles
        .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

    Map<String, TilerEvent> allFoundTiles = {};

    for (var eachTile in orderedTiles!.values) {
      allFoundTiles[eachTile.item1.uniqueId] = eachTile.item1;
    }

    for (int i = 0; i < orderedByTimeTiles.length; i++) {
      TilerEvent eachTile = orderedByTimeTiles[i];
      int? currentIndexPosition;
      if (orderedTiles!.containsKey(eachTile.uniqueId)) {
        currentIndexPosition = orderedTiles![eachTile.uniqueId]!.item2;
      }
      orderedTiles![eachTile.uniqueId] =
          Tuple3(eachTile, currentIndexPosition, i);
      allFoundTiles.remove(eachTile.uniqueId);
    }

    for (TilerEvent eachTile in allFoundTiles.values) {
      orderedTiles![eachTile.uniqueId] =
          Tuple3(eachTile, orderedTiles![eachTile.uniqueId]!.item2, null);
    }
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double heightMargin = 262;
    renderedTiles = {};
    if (widget.tiles != null) {
      widget.tiles!.forEach((eachTile) {
        if (eachTile.id != null &&
            (((eachTile) as SubCalendarEvent?)?.isViable ?? true)) {
          renderedTiles[eachTile.uniqueId] = eachTile;
        }
      });
    }

    // print('' +
    //     this.widget.dayIndex.toString() +
    //     " " +
    //     Utility.getTimeFromIndex(this.widget.dayIndex!).humanDate +
    //     " " +
    //     (widget.tiles ?? []).length.toString() +
    //     " " +
    //     uniqueKey);
    childrenColumnWidgets = [];
    if (dayData != null && this.widget.tiles != null) {
      this.dayData!.nonViable = this
          .widget
          .tiles!
          .where(
              (eachTile) => !((eachTile as SubCalendarEvent).isViable ?? true))
          .toList();
      childrenColumnWidgets.add(Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
          child: DaySummary(dayTimelineSummary: this.dayData!)));
    }

    Widget? sleepWidget;
    if (sleepTimeline != null) {
      Timeline sleepTimeline = this.sleepTimeline!;
      sleepWidget = SleepTileWidget(sleepTimeline);
      childrenColumnWidgets.add(sleepWidget);
    }

    evaluateTileDelta(renderedTiles.values);
    late Widget dayContent;
    if (renderedTiles.length > 0) {
      if (this.animatedList == null || this.pendingRenderedTiles == null) {
        bool onlyNewEntriesPopulated = isAllNewEntries(this.orderedTiles!);
        var initialItems = this.orderedTiles!.values.where((element) {
          if (onlyNewEntriesPopulated) {
            return element.item3 != null;
          }
          return element.item2 != null;
        }).toList();

        initialItems.sort((tupleA, tupleB) {
          if (tupleA.item1.start == tupleB.item1.start) {
            if (tupleA.item1.end == tupleB.item1.end!) {
              return tupleA.item1.uniqueId.compareTo(tupleB.item1.uniqueId);
            }
            return tupleA.item1.end!.compareTo(tupleB.item1.end!);
          }
          return tupleA.item1.start!.compareTo(tupleB.item1.start!);
        });
        animatedList = AnimatedList(
          shrinkWrap: true,
          itemBuilder: _buildItem,
          key: _listKey,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: initialItems.length,
        );
        _list = ListModel<TilerEvent>(
          listKey: _listKey,
          initialItems: Utility.orderTiles(
              initialItems.map<TilerEvent>((e) => e.item1).toList()),
          removedItemBuilder: _buildRemovedItem,
        );
      }
      dayContent = Container(
        height: MediaQuery.of(context).size.height - daySummaryToHeightBuffer,
        width: MediaQuery.of(context).size.width,
        child: ListView(
          children: [
            animatedList!,
            MediaQuery.of(context).orientation == Orientation.landscape
                ? TileStyles.bottomLandScapePaddingForTileBatchListOfTiles
                : TileStyles.bottomPortraitPaddingForTileBatchListOfTiles
          ],
        ),
      );
    }

    if (renderedTiles.length == 0) {
      animatedList = null;
      _list = null;
      this.orderedTiles = null;
      DateTime? endOfDayTime;
      if (this.widget.dayIndex != null) {
        DateTime evaluatedEndOfTime =
            Utility.getTimeFromIndex(this.widget.dayIndex!).endOfDay;
        if (Utility.utcEpochMillisecondsFromDateTime(evaluatedEndOfTime) >
            Utility.msCurrentTime) {
          endOfDayTime = evaluatedEndOfTime;
        }
      }

      dayContent = Flex(
        direction: Axis.vertical,
        children: [
          AnimatedOpacity(
            opacity: _emptyDayOpacity,
            duration: const Duration(milliseconds: 500),
            child: Container(
                height: MediaQuery.of(context).size.height - heightMargin,
                child: EmptyDayTile(
                  deadline: endOfDayTime,
                  dayIndex: this.widget.dayIndex,
                )),
          )
        ],
      );
      if (_emptyDayOpacity == 0) {
        Timer(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _emptyDayOpacity = 1;
            });
          }
        });
      }
    }

    childrenColumnWidgets.add(RefreshIndicator(
        onRefresh: () async {
          final currentState = this.context.read<ScheduleBloc>().state;
          if (currentState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                isAlreadyLoaded: true,
                previousSubEvents: currentState.subEvents,
                scheduleTimeline: currentState.lookupTimeline,
                previousTimeline: currentState.lookupTimeline,
                forceRefresh: true));
            refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
          }

          if (currentState is ScheduleLoadedState) {
            this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                isAlreadyLoaded: true,
                previousSubEvents: currentState.subEvents,
                scheduleTimeline: currentState.lookupTimeline,
                previousTimeline: currentState.lookupTimeline,
                forceRefresh: true));
            refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
          }

          if (currentState is ScheduleLoadingState) {
            this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                isAlreadyLoaded: true,
                previousSubEvents: currentState.subEvents,
                scheduleTimeline: currentState.previousLookupTimeline,
                previousTimeline: currentState.previousLookupTimeline,
                forceRefresh: true));
            refreshScheduleSummary(
                lookupTimeline: currentState.previousLookupTimeline);
          }
        },
        child: dayContent));

    if (sleepWidget != null && sleepTimeline != null) {
      if (childrenColumnWidgets.contains(sleepWidget)) {
        print('---sleep TL 4 -- ' +
            sleepTimeline!.startTime.toString() +
            '\t\t' +
            childrenColumnWidgets.length.toString() +
            "Child widgets " +
            uniqueKey);
      }
    }
    bool beforeProcessingPendingRenderingFlag = this._pendingRendering;
    if (this.pendingRenderedTiles == null) {
      handleAddOrRemovalOfTimeSectionTiles(
          this.orderedTiles, this._list, beforeProcessingPendingRenderingFlag);
      if (!beforeProcessingPendingRenderingFlag && this._pendingRendering) {
        this.pendingRenderedTiles = Map.from(this.renderedTiles);
      }
    }

    if (!this._pendingRendering && this.pendingRenderedTiles != null) {
      Timer(Duration(milliseconds: 1000), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              this.pendingRenderedTiles = null;
            });
          }
        });
      });
    }
    return Column(
      children: childrenColumnWidgets,
    );
  }

  bool isAllNewEntries(
      Map<String, Tuple3<TilerEvent, int?, int?>> timeSectionTiles) {
    return !timeSectionTiles.values.any((element) => element.item2 != null);
  }

  handleAddOrRemovalOfTimeSectionTiles(
      Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles,
      ListModel<TilerEvent>? _timeSectionListModel,
      bool pendingRendering) {
    if (timeSectionTiles != null && !pendingRendering) {
      List<Tuple3<TilerEvent, int?, int?>> changeInTilerEventOrdering =
          timeSectionTiles.values
              .where((element) => element.item2 != element.item3)
              .toList();
      bool allNewEntries = isAllNewEntries(timeSectionTiles);
      if (allNewEntries) {
        List finalOrederedTileValues = timeSectionTiles.values.toList();
        for (var eachTileTupleData in finalOrederedTileValues) {
          timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
              eachTileTupleData.item1,
              eachTileTupleData.item3,
              eachTileTupleData.item3);
        }
        return;
      }

      List<Tuple3<TilerEvent, int?, int?>> removedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> reorderedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> insertedTiles = [];
      for (var eachTileTuple in changeInTilerEventOrdering) {
        if (eachTileTuple.item3 == null && eachTileTuple.item2 != null) {
          removedTiles.add(eachTileTuple);
          continue;
        }

        if (eachTileTuple.item2 != null) {
          reorderedTiles.add(eachTileTuple);
        } else {
          insertedTiles.add(eachTileTuple);
        }
      }

      List<String> listIds = _timeSectionListModel!
          .toList()
          .map<String>((e) => e.uniqueId)
          .toList();
      for (var removedTile in removedTiles) {
        listIds = _timeSectionListModel
            .toList()
            .map<String>((e) => e.uniqueId)
            .toList();
        int toBeRemovedIndex = listIds.indexOf(removedTile.item1.uniqueId);
        if (toBeRemovedIndex != removedTile.item3) {
          if (toBeRemovedIndex >= 0) {
            print('tileBatch 0 removeAt');
            _timeSectionListModel.removeAt(toBeRemovedIndex);
          }
        }
      }

      for (var removedTile in removedTiles) {
        timeSectionTiles.remove(removedTile.item1.uniqueId);
      }

      Utility.isWithinNowSet = false;
      if (insertedTiles.isNotEmpty || reorderedTiles.isNotEmpty) {
        this._pendingRendering = true;
        Timer(Duration(milliseconds: 500), () {
          Utility.isWithinNowSet = true;
          print('tileBatch Delayed UI update');
          for (var insertedTile in insertedTiles) {
            print('tileBatch insert');
            _timeSectionListModel.insert(
              insertedTile.item3!,
              insertedTile.item1,
            );
          }

          for (var reorderedTile in reorderedTiles) {
            listIds = _timeSectionListModel
                .toList()
                .map<String>((e) => e.uniqueId)
                .toList();
            int toMovedIndex = listIds.indexOf(reorderedTile.item1.uniqueId);
            if (toMovedIndex != -1) {
              print('tileBatch 1 removeAndUpdate');
              _timeSectionListModel.removeAndUpdate(
                  toMovedIndex, reorderedTile.item3!, reorderedTile.item1,
                  animate: toMovedIndex != reorderedTile.item3);
            }
          }
          if (mounted) {
            setState(() {
              this._pendingRendering = false;
            });
          }
        });
      }
    }
    if (timeSectionTiles != null) {
      List finalOrederedTileValues = timeSectionTiles.values.toList();
      for (var eachTileTupleData in finalOrederedTileValues) {
        timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
            eachTileTupleData.item1,
            eachTileTupleData.item3,
            eachTileTupleData.item3);
      }
    }
  }
}
