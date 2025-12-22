import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileProgress.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/prediction.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/nextTileSuggestionCarousel.dart';
import 'package:tiler_app/routes/authenticatedUser/startEndDurationTimeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/tileDetail.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme.dart';
import 'package:tiler_app/util.dart';

class EditTile extends StatefulWidget {
  final String tileId;
  final TileSource? tileSource;
  final String? thirdPartyUserId;
  EditTile({required this.tileId, this.tileSource, this.thirdPartyUserId});

  @override
  _EditTileState createState() => _EditTileState();
}

class _EditTileState extends State<EditTile> {
  late WhatIfApi whatIfApi;
  SubCalendarEvent? subEvent;
  TextEditingController? splitCountController;
  EditTilerEvent? editTilerEvent;
  Function? onProceed;
  int? splitCount;
  late SubCalendarEventApi subCalendarEventApi;
  late CalendarEventApi calendarEventApi;
  bool isPendingSubEventProcessing = false;
  EditTileName? _editTileName;
  Widget? bottomWidget;

  EditTileNote? _editTileNote;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;
  EditDateAndTime? _editCalStartDateAndTime;
  EditDateAndTime? _editCalEndDateAndTime;
  StartEndDurationTimeline? _startEndDurationTimeline;
  bool hideButtons = false;
  List<NextTileSuggestion>? nextTileSuggestions;
  Preview? beforePrediction;
  Preview? afterPrediction;
  static final String editTileCancelAndProceedName = "";
  late ThemeData theme;
  late ColorScheme colorScheme;
  TextStyle labelStyle = TextStyle(
      fontSize: 20,
      fontFamily: TileTextStyles.rubikFontName,
      fontWeight: FontWeight.w500);
  late TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
    this.calendarEventApi =
        new CalendarEventApi(getContextCallBack: () => context);
    this.subCalendarEventApi =
        new SubCalendarEventApi(getContextCallBack: () => context);
    this.whatIfApi = new WhatIfApi(getContextCallBack: () => context);
    print("Edit sub event with id ${this.widget.tileId}");
    this.context.read<SubCalendarTileBloc>().add(GetSubCalendarTileBlocEvent(
        subEventId: this.widget.tileId,
        calendarSource: (this.widget.tileSource?.name ?? ""),
        thirdPartyUserId: this.widget.thirdPartyUserId));

    calendarEventApi.getNextTileSuggestion(this.widget.tileId).then((value) {
      setState(() {
        nextTileSuggestions = value;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  bool isScheduleTimelineReady(EditTilerEvent? editTilerEvent) {
    return editTilerEvent != null &&
        editTilerEvent.startTime != null &&
        editTilerEvent.endTime != null &&
        editTilerEvent.calStartTime != null &&
        editTilerEvent.calEndTime != null;
  }

  Widget _tileHeader(String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 20,
          fontFamily: TileTextStyles.rubikFontName,
        ),
      ),
    );
  }

  Widget _tileBodyHeader(
      {required IconData icon,
      required Color iconColor,
      required String tileCount}) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tileCount),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileTextStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget renderTardyTiles(List<SubCalendarEvent> tiles) {
    Widget tardyHeader = _tileHeader(tiles.isEmpty
        ? AppLocalizations.of(context)!.late
        : AppLocalizations.of(context)!
            .lateDate(tiles.first.startTime.humanDate(context)));

    if (tiles.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          width: MediaQuery.of(context).size.width * TileDimensions.widthRatio,
          child: Column(
            children: [
              tardyHeader,
              Container(
                decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10)),
                child: Container(
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Lottie.asset('assets/lottie/abstract-waves-circles.json',
                          height: 100),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.surfaceContainerLowest
                                      .withValues(alpha: 0.25),
                                  colorScheme.surfaceContainerLowest
                                      .withValues(alpha: 0.9),
                                ])),
                        width: MediaQuery.of(context).size.width *
                            TileDimensions.widthRatio,
                        height: 100,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(AppLocalizations.of(context)!.onTime,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 50,
                              fontFamily: TileTextStyles.rubikFontName,
                            )),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileDimensions.widthRatio,
        child: Column(
          children: [
            tardyHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                _tileBodyHeader(
                    icon: Icons.warning,
                    iconColor: TileColors.warning,
                    tileCount: tiles.length.toString()),
                Column(
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget renderListOfTiles(List<SubCalendarEvent> tiles) {
    return Container(
      height: 100,
      child: ListView(
        children: tiles.map<Widget>((e) => renderTile(e)).toList(),
      ),
    );
  }

  Widget renderTile(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  height: 20,
                  width: 20,
                  margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  decoration: BoxDecoration(
                      color: subCalendarEventTile.color ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(5))),
              Container(
                height: 20,
                width: MediaQuery.of(context).size.width *
                        TileDimensions.widthRatio -
                    190,
                child: Text(
                  subCalendarEventTile.name!,
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [renderDate(subCalendarEventTile)],
          ),
        ],
      ),
    );

    return retValue;
  }

  Widget renderDate(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      width: 110,
      height: 30,
      decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Icon(
              Icons.calendar_month,
              size: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Container(
            child: Text(
              (subCalendarEventTile.calendarEventEndTime ??
                      subCalendarEventTile.startTime)
                  .humanDate(context),
              style: TextStyle(
                fontSize: 12,
                fontFamily: TileTextStyles.rubikFontName,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );

    return retValue;
  }

  Widget renderUnscheduledTiles(List<SubCalendarEvent> tiles) {
    if (tiles.isEmpty) {
      return SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileDimensions.widthRatio,
        child: Column(
          children: [
            _tileHeader(AppLocalizations.of(context)!.unScheduled),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                _tileBodyHeader(
                    icon: Icons.error,
                    iconColor: colorScheme.error,
                    tileCount: tiles.length.toString()),
                renderListOfTiles(tiles)
              ]),
            )
          ],
        ),
      ),
    );
  }

  updatePredictionWidget() {
    List<SubCalendarEvent> tardySubEvents = [];
    if (afterPrediction != null &&
        afterPrediction!.tardies != null &&
        afterPrediction!.tardies!.dayPreviews != null &&
        afterPrediction!.tardies!.dayPreviews!.isNotEmpty &&
        afterPrediction!.tardies!.dayPreviews!.first.subEvents != null) {
      tardySubEvents = afterPrediction!.tardies!.dayPreviews!.first.subEvents!
          .map<SubCalendarEvent>((e) => e as SubCalendarEvent)
          .toList();
    }

    List<SubCalendarEvent> unScheduledSubEvents = [];
    if (afterPrediction != null &&
        afterPrediction!.nonViable != null &&
        afterPrediction!.nonViable!.isNotEmpty) {
      Map<int, List<SubCalendarEvent>> dayIndexToSubEvents = {};
      int? firstDayIndex;
      for (TilerEvent eachSubEvent in afterPrediction!.nonViable!) {
        DateTime referenceEndTime =
            (eachSubEvent as SubCalendarEvent).calendarEventEndTime ??
                (eachSubEvent).endTime;
        int dayIndex = referenceEndTime.universalDayIndex;
        if (firstDayIndex == null || firstDayIndex > dayIndex) {
          firstDayIndex = dayIndex;
        }
        List<SubCalendarEvent> subEvents = dayIndexToSubEvents[dayIndex] ??= [];
        subEvents.add(eachSubEvent);
      }

      unScheduledSubEvents = dayIndexToSubEvents[firstDayIndex!]!;
    }
    if (tardySubEvents.isEmpty && unScheduledSubEvents.isEmpty) {
      clearPredictionButton();
      return;
    }

    setState(() {
      bottomWidget = ElevatedButton(
        onPressed: () {
          if (afterPrediction == null) {
            clearPredictionButton();
            return;
          }
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              Widget tardyTiles = tardySubEvents.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: renderTardyTiles(tardySubEvents))
                  : SizedBox.shrink();
              Widget unscheduledTiles = unScheduledSubEvents.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: renderUnscheduledTiles(unScheduledSubEvents),
                    )
                  : SizedBox.shrink();
              return Container(
                height: 300,
                color: tileThemeExtension.surfaceContainerPlus
                    .withValues(alpha: 0.3),
                child: Center(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    children: <Widget>[tardyTiles, unscheduledTiles],
                  ),
                ),
              );
            },
          );
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.resolveWith(
            (states) => EdgeInsets.all(0),
          ),
        ),
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              child: Text(AppLocalizations.of(context)!.prediction,
                  style: TextStyle(fontSize: 20)),
            ),
            Shimmer.fromColors(
              baseColor: colorScheme.tertiaryContainer.withAlpha(75),
              highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  clearPredictionButton() {
    setState(() {
      bottomWidget = null;
    });
  }

  showPendingPreview() {
    setState(() {
      bottomWidget = PendingWidget(
        imageAsset: TileThemeNew.evaluatingScheduleAsset,
      );
    });
  }

  void onScheduleTimelineChange() {
    if (editTilerEvent != null && isScheduleTimelineReady(editTilerEvent)) {
      int beforeSplitCount = editTilerEvent!.splitCount ?? 1;
      Timeline beforeStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.startTime!, editTilerEvent!.endTime!);
      Timeline beforeCalStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.calStartTime!, editTilerEvent!.calEndTime!);
      dataChange();
      int afterSplitCount = editTilerEvent!.splitCount ?? 1;
      Timeline afterStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.startTime!, editTilerEvent!.endTime!);
      Timeline afterCalStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.calStartTime!, editTilerEvent!.calEndTime!);
      if ((this.onProceed != null) &&
          isScheduleTimelineReady(editTilerEvent) &&
          editTilerEvent!.splitCount != null &&
          (beforeSplitCount != afterSplitCount ||
              !beforeStartToEnd.isStartAndEndEqual(afterStartToEnd) ||
              !beforeCalStartToEnd.isStartAndEndEqual(afterCalStartToEnd))) {
        showPendingPreview();
        whatIfApi.updateSubEvent(editTilerEvent!).then((value) {
          if (value == null) {
            clearPredictionButton();
            return;
          }
          if (this.mounted) {
            setState(() {
              beforePrediction = value.item1;
              afterPrediction = value.item2;
            });
            updatePredictionWidget();
          }
        }).catchError((onError) {
          if (this.mounted) {
            clearPredictionButton();
          }
          print(onError);
        });
      }
    } else {
      dataChange();
      if (this.onProceed == null) {
        clearPredictionButton();
      }
    }
  }

  void onInputCountChange() {
    onScheduleTimelineChange();
  }

  Future<SubCalendarEvent> subEventUpdate() {
    AnalysticsSignal.send('EDIT_TILE_REQUEST_INITIALIZED');
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          scheduleStatus: currentState.scheduleStatus,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    return this
        .subCalendarEventApi
        .updateSubEvent(this.editTilerEvent!)
        .then((value) {
      AnalysticsSignal.send('EDIT_TILE_REQUEST_SUCCESS');
      final currentState = this.context.read<ScheduleBloc>().state;
      var stateResult = ScheduleBloc.preserveState(currentState);
      List<SubCalendarEvent>? subEvents = stateResult.item1;
      List<Timeline>? timelines = stateResult.item2;
      Timeline? lookupTimeline = stateResult.item3;
      this.context.read<ScheduleBloc>().add(GetScheduleEvent(
          isAlreadyLoaded: true,
          previousSubEvents: subEvents,
          scheduleTimeline: lookupTimeline,
          previousTimeline: lookupTimeline,
          forceRefresh: true));
      refreshScheduleSummary(lookupTimeline);
      return value;
    });
  }

  void dataChange() {
    if (editTilerEvent != null) {
      EditTilerEvent revisedEditTilerEvent = editTilerEvent!;
      if (_editTileName != null && !isProcrastinateTile) {
        revisedEditTilerEvent.name = _editTileName!.name;
      }

      if (_editTileNote != null) {
        revisedEditTilerEvent.note = _editTileNote!.tileNote;
      }
      if (_editStartDateAndTime != null &&
          _editStartDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.startTime =
            _editStartDateAndTime!.dateAndTime!.toUtc();
      }

      if (_startEndDurationTimeline != null) {
        TimeRange timeRange = _startEndDurationTimeline!.timeRange;
        revisedEditTilerEvent.startTime = timeRange.startTime;
        revisedEditTilerEvent.endTime = timeRange.endTime;
      }

      if (_editCalStartDateAndTime != null &&
          _editCalStartDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.calStartTime =
            _editCalStartDateAndTime!.dateAndTime!.toUtc();
      }

      if (_editCalEndDateAndTime != null &&
          _editCalEndDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.calEndTime =
            _editCalEndDateAndTime!.dateAndTime!.toUtc();
      }

      if (splitCountController != null && splitCountController != null) {
        revisedEditTilerEvent.splitCount =
            int.tryParse(splitCountController!.text);
      }
      updateProceed();
      setState(() {
        editTilerEvent = revisedEditTilerEvent;
      });
    }
  }

  bool get isProcrastinateTile {
    return (this.subEvent!.isProcrastinate ?? false);
  }

  bool get isRigidTile {
    return (this.subEvent!.calendarEvent?.isRigid ??
        this.subEvent!.isRigid ??
        false);
  }

  void updateProceed() {
    if (editTilerEvent != null) {
      if (isProcrastinateTile) {
        bool timeIsTheSame =
            editTilerEvent!.startTime!.toLocal().millisecondsSinceEpoch ==
                    subEvent!.startTime.toLocal().millisecondsSinceEpoch &&
                editTilerEvent!.endTime!.toLocal().millisecondsSinceEpoch ==
                    subEvent!.endTime.toLocal().millisecondsSinceEpoch;

        bool isValidTimeFrame = Utility.utcEpochMillisecondsFromDateTime(
                editTilerEvent!.startTime!) <
            Utility.utcEpochMillisecondsFromDateTime(editTilerEvent!.endTime!);
        if (!timeIsTheSame && isValidTimeFrame) {
          setState(() {
            onProceed = subEventUpdate;
          });
          return;
        }
      }
      if (editTilerEvent!.isValid) {
        if (!Utility.isEditTileEventEquivalentToSubCalendarEvent(
            editTilerEvent!, this.subEvent!)) {
          setState(() {
            onProceed = subEventUpdate;
          });
          return;
        }
      }
    }
    setState(() {
      onProceed = null;
    });
  }

  Widget renderNextTileSuggestionContainer() {
    Widget retValue = SizedBox.shrink();
    if (this.nextTileSuggestions != null &&
        this.nextTileSuggestions!.length > 0) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(25, 0, 0, 0),
            alignment: Alignment.topLeft,
            child: Text(
              AppLocalizations.of(context)!.suggestions,
              style: this.labelStyle,
            ),
          ),
          NextTileSuggestionCarouselWidget(
              nextTileSuggestions: this.nextTileSuggestions!),
        ],
      );
    }

    return retValue;
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      lookupTimeline =
          lookupTimeline == null ? Utility.todayTimeline() : lookupTimeline;
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  List<Widget>? getAppBarActionButtons() {
    final appBarActionButtons = <Widget>[];
    if (this.subEvent != null &&
        this.subEvent?.calendarEvent?.id != null &&
        this.subEvent?.thirdpartyType == TileSource.tiler) {
      appBarActionButtons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TileDetail(
                          tileId: this.subEvent?.calendarEvent?.id ??
                              this.widget.tileId,
                          loadSubEvents: false,
                        ))).whenComplete(() {
              this.context.read<SubCalendarTileBloc>().add(
                  GetSubCalendarTileBlocEvent(
                      subEventId: this.widget.tileId,
                      calendarSource: (this.widget.tileSource?.name ?? ""),
                      thirdPartyUserId: this.widget.thirdPartyUserId));
              subEvent = null;
            });
          },
          style: TileButtonStyles.onlyIconsContrast(
              foregroundColor: colorScheme.onPrimary),
          child: Icon(Icons.app_registration),
        ),
      );
    }
    return appBarActionButtons;
  }

  Widget _buildClusterContainer({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    String? svgAssets,
  }) {
    // Apply default horizontal margin for consistent spacing like Settings page
    final effectiveMargin = EdgeInsets.fromLTRB(
      20,
      margin?.top ?? 0,
      20,
      margin?.bottom ?? 0,
    );
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
      ),
      margin: effectiveMargin,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: svgAssets != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -20,
                  right: -20,
                  child: SvgPicture.asset(
                    svgAssets,
                    height: 150,
                    colorFilter: ColorFilter.mode(
                      colorScheme.onSurface.withValues(alpha: 0.05),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
        routeName: editTileCancelAndProceedName,
        hideButtons: hideButtons,
        child: BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
          listener: (context, state) {
            if (state is SubCalendarTileLoadedState) {
              setState(() {
                if (subEvent == null) {
                  subEvent = state.subEvent;
                  editTilerEvent = new EditTilerEvent();
                  editTilerEvent!.endTime = subEvent!.endTime;
                  editTilerEvent!.startTime = subEvent!.startTime;
                  editTilerEvent!.splitCount = subEvent!.split;
                  editTilerEvent!.name = subEvent!.name ?? '';
                  editTilerEvent!.thirdPartyId = subEvent!.thirdpartyId;
                  editTilerEvent!.thirdPartyType =
                      subEvent!.thirdpartyType?.name.toLowerCase() ?? "";
                  editTilerEvent!.thirdPartyUserId = subEvent!.thirdPartyUserId;
                  editTilerEvent!.id = subEvent!.isFromTiler
                      ? subEvent!.id
                      : subEvent!.thirdpartyId;
                  if (subEvent!.noteData != null) {
                    editTilerEvent!.note = subEvent!.noteData!.note;
                  }
                  if (subEvent!.calendarEvent != null) {
                    splitCount = subEvent!.calendarEvent!.split;
                    splitCountController =
                        TextEditingController(text: splitCount!.toString());
                    splitCountController!.addListener(onInputCountChange);
                    editTilerEvent!.splitCount = splitCount;
                    editTilerEvent!.calEndTime =
                        subEvent!.calendarEvent!.endTime;
                    editTilerEvent!.calStartTime =
                        subEvent!.calendarEvent!.startTime;
                  }
                }
              });
            }
          },
          child: BlocBuilder<SubCalendarTileBloc, SubCalendarTileState>(
            builder: (context, state) {
              if (state is SubCalendarTilesInitialState ||
                  state is SubCalendarTilesLoadingState ||
                  this.subEvent == null) {
                return PendingWidget();
              }
              final Color textBorderColor = colorScheme.primaryContainer;

              Widget? tileProgressWidget;

              String tileName =
                  this.editTilerEvent?.name ?? this.subEvent!.name ?? '';
              _editTileName = EditTileName(
                tileName: tileName,
                isProcrastinate: isProcrastinateTile,
                isReadOnly: !this.subEvent!.isActive,
                onInputChange: (_) {
                  dataChange();
                },
              );

              var inputChildWidgets = <Widget>[];
              String tileNote = this.editTilerEvent?.note ??
                  this.subEvent!.noteData?.note ??
                  '';

              bool isNoteReadOnly = !this.subEvent!.isActive ||
                  (this.subEvent == null ? false : !this.subEvent!.isFromTiler);
              _editTileNote = EditTileNote(
                tileNote: tileNote,
                onInputChange: dataChange,
                isReadOnly: isNoteReadOnly,
              );
              DateTime startTime =
                  this.editTilerEvent?.startTime ?? this.subEvent!.startTime;
              _editStartDateAndTime = EditDateAndTime(
                time: startTime,
                onInputChange: onScheduleTimelineChange,
              );
              DateTime endTime =
                  this.editTilerEvent?.endTime ?? this.subEvent!.endTime;
              _editEndDateAndTime = EditDateAndTime(
                time: endTime,
                onInputChange: onScheduleTimelineChange,
              );
              if (this.subEvent!.calendarEventStartTime != null) {
                DateTime calStartTime = this.editTilerEvent?.calStartTime ??
                    this.subEvent!.calendarEventStartTime!;
                _editCalStartDateAndTime = EditDateAndTime(
                  time: calStartTime,
                  onInputChange: onScheduleTimelineChange,
                );
              }

              if (this.subEvent!.calendarEventEndTime != null) {
                DateTime calEndTime = this.editTilerEvent?.calEndTime ??
                    this.subEvent!.calendarEventEndTime!;
                _editCalEndDateAndTime = EditDateAndTime(
                  time: calEndTime,
                  onInputChange: onScheduleTimelineChange,
                  isReadOnly: !this.subEvent!.isActive,
                );
              }

              _startEndDurationTimeline = StartEndDurationTimeline.fromTimeline(
                timeRange: this.subEvent!,
                isReadOnly: !this.subEvent!.isActive,
                onChange: (timeline) {
                  onScheduleTimelineChange();
                },
              );
              _startEndDurationTimeline!.headerTextStyle = labelStyle;

              List<Widget> nameAndSplitCluster = <Widget>[
                FractionallySizedBox(
                    widthFactor: TileDimensions.tileWidthRatio,
                    child: _editTileName!)
              ];
              List<Widget> durationAndDeadlineCluster = <Widget>[
                FractionallySizedBox(
                    widthFactor: TileDimensions.tileWidthRatio,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: _startEndDurationTimeline))
              ];

              if (!isRigidTile && !isProcrastinateTile) {
                Widget splitWidget = FractionallySizedBox(
                    widthFactor: TileDimensions.tileWidthRatio,
                    child: Container(
                      height: 70,
                      margin: EdgeInsets.fromLTRB(30, 20, 0, 15),
                      child: Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
                            height: 40,
                            child: Text(AppLocalizations.of(context)!.split,
                                style: labelStyle),
                          ),
                          Positioned(
                            top: 40,
                            child: Container(
                              child: Text(
                                AppLocalizations.of(context)!.timeBlocks,
                                style: TextStyle(
                                  color:
                                      tileThemeExtension.onSurfaceTimeBlockLbl,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 14,
                                  fontFamily: TileTextStyles.rubikFontName,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 5,
                            child: Container(
                              width: 100,
                              height: 70,
                              child: TextField(
                                decoration: InputDecoration(
                                  filled: true,
                                  isDense: true,
                                  enabled: this.subEvent!.isActive,
                                  fillColor: Colors.transparent,
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: textBorderColor)),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: textBorderColor.withLightness(0.8),
                                    ),
                                  ),
                                  contentPadding:
                                      EdgeInsets.fromLTRB(20, 5, 20, 0),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24),
                                keyboardType: TextInputType.numberWithOptions(
                                    signed: true, decimal: true),
                                controller: splitCountController,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ));

                inputChildWidgets.add(_buildClusterContainer(
                    svgAssets: 'assets/images/iconScout/block.svg',
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: splitWidget));
                if (_editCalEndDateAndTime != null &&
                    subEvent != null &&
                    subEvent!.isRecurring == true) {
                  Widget deadlineWidget = FractionallySizedBox(
                      widthFactor: TileDimensions.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(
                                  AppLocalizations.of(context)!.deadline,
                                  style: labelStyle),
                            ),
                            _editCalEndDateAndTime!
                          ],
                        ),
                      ));
                  durationAndDeadlineCluster.add(deadlineWidget);
                }
                tileProgressWidget = _buildClusterContainer(
                    svgAssets: 'assets/images/iconScout/chart.svg',
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(25, 0, 0, 0),
                        alignment: Alignment.topLeft,
                        child: Text(
                          AppLocalizations.of(context)!.progress,
                          style: this.labelStyle,
                        ),
                      ),
                      TileProgress(
                          calendarEvent:
                              this.subEvent!.calendarEvent! as CalendarEvent),
                    ]));
              }
              Widget nameAndSplitClusterWrapper = _buildClusterContainer(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 15),
                padding: EdgeInsets.fromLTRB(0, 16, 0, 12),
                child: Column(children: nameAndSplitCluster),
              );

              inputChildWidgets.insert(0, nameAndSplitClusterWrapper);

              Widget durationClusterWrapper = _buildClusterContainer(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
                  padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
                  svgAssets: 'assets/images/iconScout/deadline.svg',
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      children: durationAndDeadlineCluster,
                    ),
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                  ));

              inputChildWidgets.add(durationClusterWrapper);

              if (_editTileNote != null && subEvent!.isFromTiler) {
                inputChildWidgets.add(_buildClusterContainer(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    svgAssets: 'assets/images/iconScout/notes.svg',
                    child: Container(
                      child: _editTileNote!,
                      margin: EdgeInsets.fromLTRB(0, 30, 0, 10),
                    )));
              }

              List<PlaybackOptions> playbackOptions = [
                PlaybackOptions.Procrastinate,
                PlaybackOptions.Now,
                PlaybackOptions.Delete,
                PlaybackOptions.Complete
              ];
              if (((this.subEvent!.isComplete)) ||
                  (!(this.subEvent!.isEnabled))) {
                playbackOptions.remove(PlaybackOptions.Complete);
                playbackOptions.remove(PlaybackOptions.Delete);
                playbackOptions.remove(PlaybackOptions.Now);
                playbackOptions.remove(PlaybackOptions.Procrastinate);
              }
              if ((this.subEvent!.isProcrastinate ?? false)) {
                playbackOptions.remove(PlaybackOptions.Procrastinate);
                playbackOptions.remove(PlaybackOptions.PlayPause);
                playbackOptions.remove(PlaybackOptions.Now);
              }
              if ((!(this.subEvent!.isViable ?? false))) {
                playbackOptions.remove(PlaybackOptions.PlayPause);
              }

              if (!subEvent!.isFromTiler) {
                playbackOptions = [PlaybackOptions.Delete];
              }

              Widget playBackButtonWrapper = _buildClusterContainer(
                padding: EdgeInsets.fromLTRB(0, 25, 0, 25),
                margin: !this.subEvent!.isFromTiler
                    ? EdgeInsets.fromLTRB(0, 25, 0, 0)
                    : EdgeInsets.fromLTRB(0, 7.5, 0, 0),
                child: PlayBack(
                  this.subEvent!,
                  forcedOption: playbackOptions,
                  callBack: (status, Future responseFuture) {
                    setState(() {
                      isPendingSubEventProcessing = true;
                      hideButtons = true;
                    });
                    responseFuture.then((value) {
                      if (!this.mounted) {
                        return value;
                      }
                      setState(() {
                        isPendingSubEventProcessing = false;
                        hideButtons = false;
                      });
                      final currentState =
                          this.context.read<ScheduleBloc>().state;
                      if (currentState is ScheduleEvaluationState) {
                        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                        refreshScheduleSummary(currentState.lookupTimeline);
                      }
                      if (currentState is ScheduleLoadedState) {
                        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                        refreshScheduleSummary(currentState.lookupTimeline);
                      }
                      Navigator.pop(context);
                      return value;
                    });
                  },
                ),
              );

              if (this.nextTileSuggestions != null &&
                  this.nextTileSuggestions!.length > 0) {
                Widget nextTileSuggestionWrapper = _buildClusterContainer(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: renderNextTileSuggestionContainer());
                inputChildWidgets.add(nextTileSuggestionWrapper);
              }
              if (subEvent!.isActive) {
                inputChildWidgets.add(playBackButtonWrapper);
              }
              if (tileProgressWidget != null && subEvent!.isFromTiler) {
                inputChildWidgets.add(tileProgressWidget);
              }

              List<Widget> stackElements = <Widget>[
                Container(
                  color: tileThemeExtension.primaryContainerLow,
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 100),
                  alignment: Alignment.topCenter,
                  child: ListView(
                    children: inputChildWidgets,
                  ),
                )
              ];

              if (isPendingSubEventProcessing) {
                stackElements.add(PendingWidget(
                  imageAsset: TileThemeNew.evaluatingScheduleAsset,
                ));
              }
              return Stack(
                children: stackElements,
              );
            },
          ),
        ),
        onCancel: () {
          this
              .context
              .read<SubCalendarTileBloc>()
              .add(ResetSubCalendarTileBlocEvent());
        },
        onProceed: this.onProceed,
        bottomWidget: this.bottomWidget,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.edit,
          ),
          actions: this.getAppBarActionButtons(),
          automaticallyImplyLeading: false,
        ));
  }

  @override
  void dispose() {
    if (splitCountController != null) {
      splitCountController!.dispose();
    }
    super.dispose();
  }
}
