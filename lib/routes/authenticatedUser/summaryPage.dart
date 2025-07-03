import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart' as flchart;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/analysis.dart';
import 'package:tiler_app/data/driveTime.dart';
import 'package:tiler_app/data/overview_item.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme.dart';
import 'package:tiler_app/util.dart';

import '../../bloc/scheduleSummary/schedule_summary_bloc.dart';
import '../../components/PendingWidget.dart';

class SummaryPage extends StatefulWidget {
  Timeline timeline;
  SummaryPage({required this.timeline});
  _SummaryPage createState() => _SummaryPage();
}

class _SummaryPage extends State<SummaryPage> {
  List<flchart.FlSpot> shots = [];
  Analysis? analysis;
  TimelineSummary? timelineSummary;
  Map<String, double> dataOverView = {};
  Map<String, double> dataDriveTime = {};
  bool isLoadingAnalysis = true;
  bool isLoadingTimelineSummary = true;
  bool isCheckStateActive = false;
  int times = 10;
  List<Timeline> sleeplines = [];
  List<OverViewItem> overviewItems = [];
  List<DriveTime> driveTimes = [];
  List<bool> unscheduledTilesCheckStates = [];
  List<bool> lateTilesCheckStates = [];
  List<SubCalendarEvent> selectedUnscheduledItems = [];
  late ScheduleApi scheduleApi;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
    scheduleApi = ScheduleApi(getContextCallBack: () => context);
    initialize();
  }
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
  }

  Future<void> initialize() async {
    isLoadingAnalysis = true;
    setState(() {});
    await scheduleApi.getTimelineSummary(this.widget.timeline).then((value) {
      timelineSummary = value;
      if (timelineSummary != null && timelineSummary!.timeline == null) {
        timelineSummary!.timeline = this.widget.timeline;
        setState(() {
          unscheduledTilesCheckStates = List.generate(
              timelineSummary?.nonViable?.length ?? 0, (index) => false);
        });
      }
      if (analysis == null) {
        isLoadingTimelineSummary = false;
        return;
      }

      final timelines = analysis!.sleep!;
      sleeplines = timelines;

      timelines.forEach((element) {
        shots.add(flchart.FlSpot(
          element.startTime.weekday.toDouble(),
          element.duration.inMinutes.toDouble(),
        ));
      });

      final overviewlist = analysis!.overview!;
      overviewItems = overviewlist;
      overviewlist.forEach((element) {
        Map<String, double> other = {
          element.name!.toUpperCase(): element.duration!.toDouble()
        };
        dataOverView.addAll(other);
      });
      final drivetimelist = analysis!.drivesTime!;

      driveTimes = drivetimelist;

      drivetimelist.forEach((element) {
        Map<String, double> other = {
          element.name!: element.duration!.toDouble()
        };
        dataDriveTime.addAll(other);
      });

      isLoadingTimelineSummary = false;
      setState(() {});
    }).catchError((onError) {
      timelineSummary = null;
    });

    // GET ANALYSIS FUNCTION
    await scheduleApi.getAnalysis().then((value) {
      analysis = value;
      if (analysis == null) {
        isLoadingAnalysis = false;
        if (this.mounted) {
          setState(() {});
        }
        return;
      }

      final timeslines = analysis!.sleep!;
      sleeplines = timeslines;

      timeslines.forEach((element) {
        shots.add(flchart.FlSpot(
          element.startTime.weekday.toDouble(),
          element.duration.inMinutes.toDouble(),
        ));
      });

      final overviewlist = analysis!.overview!;
      overviewItems = overviewlist;
      overviewlist.forEach((element) {
        Map<String, double> other = {
          element.name!.toUpperCase(): element.duration!.toDouble()
        };
        dataOverView.addAll(other);
      });
      final drivetimelist = analysis!.drivesTime!;

      driveTimes = drivetimelist;

      drivetimelist.forEach((element) {
        Map<String, double> other = {
          element.name!: element.duration!.toDouble()
        };
        dataDriveTime.addAll(other);
      });

      isLoadingAnalysis = false;

      if (mounted) {
        setState(() {
          isLoadingAnalysis = false;
        });
      }
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) => PendingWidget(
        imageAsset: TileThemeNew.evaluatingScheduleAsset,
      ),
    );
  }

  List<SubCalendarEvent> getSelectedUnscheduledItems() {
    List<SubCalendarEvent> selectedItems = [];
    for (int i = 0; i < unscheduledTilesCheckStates.length; i++) {
      if (unscheduledTilesCheckStates[i]) {
        selectedItems.add(timelineSummary?.nonViable?[i] as SubCalendarEvent);
      }
    }
    return selectedItems;
  }


  Widget renderChecklistDates(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      width: 110,
      height: 30,
      decoration: BoxDecoration(
          color:colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Icon(
              Icons.calendar_month,
              size: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Text(
            (subCalendarEventTile.calendarEventEndTime ??
                    subCalendarEventTile.startTime)
                .humanDate(context),
            style:  TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w600
            )
          ),
        ],
      ),
    );

    return retValue;
  }

  Widget _mainContainer({required Widget child,required String headerTitle}){
    return Align(
        alignment: Alignment.center,
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
            width: MediaQuery.of(context).size.width * TileDimensions.widthRatio,
            child:Column(
              children: [
                _mainHeader(headerTitle),
                child
              ],
            )
        )
    );
}
Widget _mainBody({required int tileCount,required IconData headerIcon,required Widget child, Color? headerIconColor=null,VoidCallback? iconOnPressed=null}){
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color:colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
          children: [
            _mainBodyHeader(
              icon: headerIcon,
              iconColor: headerIconColor,
              count: tileCount,
              onPressed: iconOnPressed,
            ),
            child
          ],
      ),
  );
}

Widget _emptyBody({required String lottieName, required String title}){
  return Container(
    decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10)),
    child: Container(
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Lottie.asset(
                lottieName,
                height: 100
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerLow.withValues(alpha: 0.25),
                        colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
                      ])),
              width: MediaQuery.of(context).size.width * TileDimensions.widthRatio,
              height: 100,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                  title,
                  style:TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 50,
                    fontFamily: TileTextStyles.rubikFontName,
                  )
              ),
            ),
          ],
        )),
  );
}

  Widget _mainHeader(String headerTitle){
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(
        headerTitle,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: TileTextStyles.rubikFontName,
        ),
      )
    );
  }

  Widget _mainBodyHeader({
    required IconData icon,
    Color? iconColor=null,
    required int count,
    VoidCallback? onPressed=null,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20)
            ),
            child: onPressed !=null?
            IconButton(
                onPressed: onPressed,
                icon:Icon(icon)
            )
                :Icon(icon,color: iconColor),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
                AppLocalizations.of(context)!.countTile(count.toString()),
                style:  TextStyle(
                  fontSize: 25,
                  fontFamily: TileTextStyles.rubikFontName,
                ),
            ),
          )
        ],
      ),
    );
  }

  void _toEditTile(SubCalendarEvent subCalendarEventTile){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTile(
          tileId: (subCalendarEventTile.isFromTiler
              ? subCalendarEventTile.id
              : subCalendarEventTile.thirdpartyId) ??
              "",
          tileSource: subCalendarEventTile.thirdpartyType,
          thirdPartyUserId: subCalendarEventTile.thirdPartyUserId,
        ),
      ),
    );
  }

  Widget renderTile(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = TextButton(
      style: TextButton.styleFrom(
          padding: EdgeInsets.all(0)
      ),
      onPressed:() =>  _toEditTile(subCalendarEventTile),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: 0.5,
                color: subCalendarEventTile.priority == TilePriority.high
                    ?  TileColors.highPriority
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(5)),
        padding: EdgeInsets.all(10),
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
                        borderRadius: BorderRadius.circular(5)
                    ),
                ),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width *
                      TileDimensions.widthRatio -
                      205,
                  child: Text(
                    subCalendarEventTile.isProcrastinate == true
                        ? AppLocalizations.of(context)!.procrastinateBlockOut
                        : subCalendarEventTile.name ?? "",
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [renderChecklistDates(subCalendarEventTile)],
            ),
          ],
        ),
      ),
    );
    return retValue;
  }



  Widget renderListOfTiles(
    double height,
    List<SubCalendarEvent> tiles,
  ) {
    //ey: the tileKeys and index are not used
    // List<GlobalKey<_TileToBeCompletedState>> tileKeys = List.generate(
    //   tiles.length,
    //   (_) => GlobalKey<_TileToBeCompletedState>(),
   // );
    return Column(
      children: tiles.asMap().entries.map<Widget>((entry) {
        int index = entry.key;
        SubCalendarEvent e = entry.value;
        return renderTile(e);
      }).toList(),
    );
  }

  // Completed section
  Widget renderCompleteTiles(double height, List<SubCalendarEvent> tiles) {
    if (tiles.isEmpty) {
      return _mainContainer(
              headerTitle: AppLocalizations.of(context)!.complete,
              child:_emptyBody(
                  lottieName: 'assets/lottie/abstract-waves-lines.json',
                  title: AppLocalizations.of(context)!.getOnIt,
              )
      );
    }

    return _mainContainer(
      headerTitle: AppLocalizations.of(context)!.complete,
        child:_mainBody(
            tileCount: tiles.length,
            headerIcon: Icons.check_circle,
            headerIconColor:  TileColors.completedTeal,
            child:  renderListOfTiles(
              height,
              tiles,
            )
        )
    );
  }

  Widget renderCheckList(List<SubCalendarEvent> tiles,
      {required List<bool> checkBoxStates}) {
    return Column(
        children: tiles.asMap().entries.map<Widget>((entry) {
      int index = entry.key;
      SubCalendarEvent e = entry.value;
      return Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: 0.5,
                color: e.priority == TilePriority.high
                    ? TileColors.highPriority
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(5)),
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox.adaptive(
                    focusColor:TileColors.checkUnscheduled,
                    value: //false,
                        checkBoxStates[index],
                    onChanged: (value) {
                      setState(() {
                        checkBoxStates[index] = value!;
                        selectedUnscheduledItems =
                            getSelectedUnscheduledItems();
                      });
                    },
                    activeColor: Colors.transparent,
                    checkColor: TileColors.checkUnscheduled,
                  ),
                ),

                //Sizedbox for spacing
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      bool value = checkBoxStates[index];
                      checkBoxStates[index] = !value;
                      selectedUnscheduledItems = getSelectedUnscheduledItems();
                    });
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    height: 35,
                    width: MediaQuery.of(context).size.width *
                        TileDimensions.widthRatio -
                        205,
                    child: Text(
                      e.isProcrastinate == true
                          ? AppLocalizations.of(context)!.procrastinateBlockOut
                          : e.name ?? "",
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                    onTap: () =>  _toEditTile(e),
                    child: renderChecklistDates(e))
              ],
            ),
          ],
        ),
      );
    }).toList());
  }

  Widget renderNonCheckList(List<SubCalendarEvent> tiles,
      {required VoidCallback switchTapFunction,
      required List<bool> checkBoxStates}) {
    return Column(
      children: tiles.asMap().entries.map<Widget>((entry) {
        SubCalendarEvent e = entry.value;
        return TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.all(0)
            ),
            onPressed: switchTapFunction,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      width: 0.5,
                      color: e.priority == TilePriority.high
                          ? TileColors.highPriority
                          : Colors.transparent
                  ),
                  borderRadius: BorderRadius.circular(5)),
              padding: EdgeInsets.all(10),
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
                              color: e.color ?? Colors.transparent,
                              borderRadius: BorderRadius.circular(5))),
                      Container(
                        height: 20,
                        width: MediaQuery.of(context).size.width *
                            TileDimensions.widthRatio -
                            205,
                        child: Text(
                          e.isProcrastinate == true
                              ? AppLocalizations.of(context)!
                                  .procrastinateBlockOut
                              : e.name ?? "",
                          style: TextStyle(
                              fontFamily:TileTextStyles.rubikFontName,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                          onTap: () =>  _toEditTile(e),
                          child: renderChecklistDates(e))
                    ],
                  ),
                ],
              ),
            )
        );
      }).toList(),
    );
  }

  void _completeFunction() async{
    List<String> eventIds = selectedUnscheduledItems
        .map((element) => element.id)
        .where((id) => id != null)
        .cast<String>()
        .toList();
    List<String> eventThirdPartyTypes =
    selectedUnscheduledItems
        .map((element) => element
        .thirdpartyType?.name
        .toLowerCase())
        .where((id) => id != null)
        .cast<String>()
        .toList();
    List<String> eventThirdPartyUserIds =
    selectedUnscheduledItems
        .map((element) {
      if (element
          .thirdPartyUserId.isEmpty ||
          element.thirdPartyUserId == '') {
        return 'tiler-account';
      } else {
        return element.thirdPartyUserId;
      }
    })
        .where((id) => id.isNotEmpty)
        .cast<String>()
        .toList();
    List<String> eventThirdPartyEventId =
    selectedUnscheduledItems
        .map((element) {
      if (element.thirdpartyId!.isEmpty ||
          element.thirdpartyId == '') {
        return '';
      } else {
        return element.thirdpartyId;
      }
    })
        .where((id) => id != null)
        .cast<String>()
        .toList();

    String eventIdString = eventIds
        .where(
          (element) => element != null,
    )
        .join(',');
    String eventThirdPartyTypeString =
    eventThirdPartyTypes.join(',');
    String eventThirdPartyUserIdString =
    eventThirdPartyUserIds.join(',');
    _showLoadingDialog();

    // Wait for the task completion
    bool success =
    await BlocProvider.of<ScheduleSummaryBloc>(
        context)
        .completeTasks(
        eventIdString,
        eventThirdPartyTypeString,
        eventThirdPartyUserIdString);

    if (success) {
      await initialize();
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    };
  }

  Widget _unscheduledCompleteRow({required List<bool> checkBoxStates,required double height,}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.numberOfTilesSelected(
              checkBoxStates
                  .where((value) => value == true)
                  .length
                  .toString()),
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: _completeFunction,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: height / (height / 10),
              vertical: height / (height / 5),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: height / height,
              ),
              borderRadius: BorderRadius.circular(
                height / (height / 4),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.completeTiles,
              style: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                color: colorScheme.primary,
              ),
            ),
          ),
        )
      ],
    );
  }

  // Unscheduled section
  Widget renderUnscheduledTiles(
    double height,
    List<SubCalendarEvent> tiles,
    bool isRenderAsCheckList, {
    required VoidCallback switchTapFunction,
    required List<bool> checkBoxStates,
  }) {
    if (tiles.isEmpty) {
      return SizedBox.shrink();
    }
    return _mainContainer(
        headerTitle: AppLocalizations.of(context)!.unScheduled,
        child:_mainBody(
            tileCount: tiles.length,
            headerIcon:   isCheckStateActive ? Icons.close : Icons.error,
            headerIconColor:  isCheckStateActive ? null : colorScheme.error,
            iconOnPressed: isCheckStateActive ? () => setState(() => isCheckStateActive = false) : null,
            child: Column(
              children: [
                isRenderAsCheckList == true
                    ? renderCheckList(tiles, checkBoxStates: checkBoxStates)
                    : renderNonCheckList(tiles,
                    checkBoxStates: checkBoxStates,
                    switchTapFunction: switchTapFunction),
                // Sizedbox for spacing
                checkBoxStates.where((value) => value == true).length >= 1
                    ? SizedBox(
                  height: 20,
                )
                    : SizedBox.shrink(),
                // Display currently selected tiles
                checkBoxStates.where((value) => value == true).length >= 1 &&
                    this.isCheckStateActive
                    ?_unscheduledCompleteRow(checkBoxStates: checkBoxStates,height: height)
                    : SizedBox.shrink(),
              ],
            )
        )
    );
  }

  // Late section
  Widget renderTardyTiles(double height, List<SubCalendarEvent> tiles) {
    if (tiles.isEmpty) {
      return _mainContainer(
              headerTitle: AppLocalizations.of(context)!.late,
              child:_emptyBody(
                lottieName: 'assets/lottie/abstract-waves-circles.json',
                title: AppLocalizations.of(context)!.onTime,
              )
          );
    }
    return _mainContainer(
        headerTitle: AppLocalizations.of(context)!.late,
        child:_mainBody(
            tileCount: tiles.length,
            headerIcon:  Icons.warning,
            headerIconColor:  TileColors.warning,
            child:  renderListOfTiles(
              height,
              tiles,
            )
        )
    );
  }

  // Widget renderSleepData() {
  //   return Column(
  //     children: [
  //       Text(
  //         AppLocalizations.of(context)!.sleep,
  //         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
  //       ),
  //       Container(
  //         height: 300,
  //         decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.all(Radius.circular(10))),
  //         child: (isLoadingAnalysis)
  //             ? CircularProgressIndicator(
  //                 color: Colors.blue,
  //               )
  //             : (shots.isEmpty)
  //                 ? Container(
  //                     child: Center(
  //                         child: Text(
  //                             AppLocalizations.of(context)!.noDataAvailable)),
  //                   )
  //                 : Stack(
  //                     children: [
  //                       Positioned(
  //                         left: 20,
  //                         top: 80,
  //                         child: Container(
  //                             height: 180,
  //                             width: MediaQuery.of(context).size.width * 0.8,
  //                             child: (shots.isEmpty)
  //                                 ? Container(
  //                                     width: MediaQuery.of(context).size.width,
  //                                     child: Center(
  //                                       child: Text(
  //                                           AppLocalizations.of(context)!
  //                                               .noDataAvailable),
  //                                     ),
  //                                   )
  //                                 : _LineChart(
  //                                     isShowingMainData: true,
  //                                     spots: shots,
  //                                   )),
  //                       ),
  //                       Positioned(
  //                         top: 0,
  //                         left: 0,
  //                         child: Container(
  //                             margin: EdgeInsets.only(left: 0, right: 20),
  //                             decoration: BoxDecoration(
  //                                 color: Colors.white,
  //                                 borderRadius: BorderRadius.circular(12)),
  //                             width: MediaQuery.of(context).size.width,
  //                             height: 100,
  //                             child: Row(
  //                               mainAxisAlignment: MainAxisAlignment.start,
  //                               crossAxisAlignment: CrossAxisAlignment.center,
  //                               children: [
  //                                 SizedBox(
  //                                   width: 12,
  //                                 ),
  //                                 Container(
  //                                   width: 50,
  //                                   height: 50,
  //                                   decoration: BoxDecoration(
  //                                     color: Color(0xffFAFAFA),
  //                                     borderRadius:
  //                                         BorderRadius.all(Radius.circular(20)),
  //                                   ),
  //                                   child: Padding(
  //                                     padding: const EdgeInsets.all(8.0),
  //                                     child: Image.asset(
  //                                         "assets/images/image8.png"),
  //                                   ),
  //                                 ),
  //                                 SizedBox(
  //                                   width: 12,
  //                                 ),
  //                                 Container(
  //                                   child: Column(
  //                                     mainAxisAlignment:
  //                                         MainAxisAlignment.center,
  //                                     crossAxisAlignment:
  //                                         CrossAxisAlignment.start,
  //                                     children: [
  //                                       Text(
  //                                         "Today",
  //                                         maxLines: 2,
  //                                         style: TextStyle(
  //                                             color: Color(0xff1F1F1F),
  //                                             fontSize: 13,
  //                                             fontWeight: FontWeight.w400),
  //                                       ),
  //                                       Text(
  //                                         "8h 8m",
  //                                         maxLines: 2,
  //                                         style: TextStyle(
  //                                             color: Color(0xff1F1F1F),
  //                                             fontSize: 20,
  //                                             fontWeight: FontWeight.bold),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                                 Expanded(child: SizedBox()),
  //                                 Container(
  //                                   width:
  //                                       MediaQuery.of(context).size.width * 0.2,
  //                                   child: Text(
  //                                     "8% more than last week!",
  //                                     maxLines: 2,
  //                                     style: TextStyle(
  //                                         color: Color(0xff1F1F1F),
  //                                         fontSize: 13,
  //                                         fontWeight: FontWeight.w400),
  //                                   ),
  //                                 ),
  //                                 SizedBox(
  //                                   width: 60,
  //                                 )
  //                               ],
  //                             )),
  //                       ),
  //                     ],
  //                   ),
  //       ),
  //     ],
  //   );
  // }

  // Widget renderDriveData() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
  //     alignment: Alignment.center,
  //     width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
  //     child: Column(
  //       children: [
  //         Container(
  //           alignment: Alignment.topLeft,
  //           padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
  //           child: Text(
  //             AppLocalizations.of(context)!.driveTime,
  //             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
  //           ),
  //         ),
  //         Container(
  //           width: MediaQuery.of(context).size.width,
  //           height: 300,
  //           decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.all(Radius.circular(10))),
  //           child: Stack(
  //             children: [
  //               Positioned(
  //                 left: 0,
  //                 top: 20,
  //                 child: Container(
  //                     height: 280,
  //                     width: MediaQuery.of(context).size.width - 30,
  //                     child: SingleChildScrollView(
  //                       scrollDirection: Axis.horizontal,
  //                       child: (dataDriveTime.isEmpty)
  //                           ? Container(
  //                               width: MediaQuery.of(context).size.width,
  //                               child: Center(
  //                                 child: Text(AppLocalizations.of(context)!
  //                                     .noDataAvailable),
  //                               ),
  //                             )
  //                           : PieChart(
  //                               dataMap: dataDriveTime,
  //                               animationDuration: Duration(milliseconds: 800),
  //                               chartLegendSpacing: 32,
  //                               chartRadius:
  //                                   MediaQuery.of(context).size.width / 3.2,
  //                               initialAngleInDegree: 0,
  //                               chartType: ChartType.disc,
  //                               ringStrokeWidth: 6,
  //                               centerText: "",
  //                               legendOptions: LegendOptions(
  //                                 showLegendsInRow: false,
  //                                 legendPosition: LegendPosition.right,
  //                                 showLegends: true,
  //                                 legendShape: BoxShape.rectangle,
  //                                 legendTextStyle: TextStyle(
  //                                     fontWeight: FontWeight.w400,
  //                                     overflow: TextOverflow.ellipsis,
  //                                     fontSize: 12),
  //                               ),
  //                               chartValuesOptions: ChartValuesOptions(
  //                                 showChartValueBackground: true,
  //                                 showChartValues: false,
  //                                 showChartValuesInPercentage: false,
  //                                 showChartValuesOutside: false,
  //                                 decimalPlaces: 1,
  //                               ),
  //                             ),
  //                     )),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget renderAnalysisData() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
  //     alignment: Alignment.center,
  //     width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Container(
  //             alignment: Alignment.topLeft,
  //             padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
  //             child: Text(
  //               AppLocalizations.of(context)!.analysis,
  //               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
  //             )),
  //         Container(
  //           height: 200,
  //           padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
  //           decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.all(Radius.circular(10))),
  //           child: Stack(
  //             children: [
  //               Container(
  //                 height: 180,
  //                 width: MediaQuery.of(context).size.width - 30,
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: (dataOverView.isEmpty)
  //                       ? Container(
  //                           width: MediaQuery.of(context).size.width,
  //                           child: Center(
  //                             child: Text(AppLocalizations.of(context)!
  //                                 .noDataAvailable),
  //                           ),
  //                         )
  //                       : PieChart(
  //                           dataMap: dataOverView,
  //                           animationDuration: Duration(milliseconds: 800),
  //                           chartLegendSpacing: 30,
  //                           chartRadius:
  //                               MediaQuery.of(context).size.width / 3.2,
  //                           initialAngleInDegree: 0,
  //                           chartType: ChartType.ring,
  //                           ringStrokeWidth: 6,
  //                           centerText: AppLocalizations.of(context)!.overview,
  //                           legendOptions: LegendOptions(
  //                             showLegendsInRow: false,
  //                             legendPosition: LegendPosition.right,
  //                             showLegends: true,
  //                             legendShape: BoxShape.rectangle,
  //                             legendTextStyle: TextStyle(
  //                                 fontWeight: FontWeight.bold, fontSize: 12),
  //                           ),
  //                           chartValuesOptions: ChartValuesOptions(
  //                             showChartValueBackground: true,
  //                             showChartValues: false,
  //                             showChartValuesInPercentage: false,
  //                             showChartValuesOutside: false,
  //                             decimalPlaces: 1,
  //                           ),
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    bool isFuture = false;
    double height = MediaQuery.of(context).size.height;

    if (this.timelineSummary != null) {
      if (!isFuture && this.timelineSummary!.date != null) {
        isFuture = this
            .timelineSummary!
            .date!
            .isAfter(Utility.todayTimeline().endTime);
      }

      if (!isFuture && this.timelineSummary!.timeline != null) {
        isFuture = this
            .timelineSummary!
            .timeline!
            .endTime
            .isAfter(Utility.todayTimeline().endTime);
      }
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(this.widget.timeline.startTime.humanDate(context)),
          leading: CloseButton(),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: colorScheme.primaryContainer,
          child: (isLoadingTimelineSummary)
              ?  PendingWidget()
              : SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width *
                            TileDimensions.widthRatio,
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.only(
                          top: 15,
                          bottom: 15,
                        ),
                      ),
                      // renderAnalysisData(),
                      this.timelineSummary == null || isFuture
                          ? SizedBox.shrink()
                          : renderCompleteTiles(height, <SubCalendarEvent>[
                              ...((this.timelineSummary!.complete ?? [])
                                  .map<SubCalendarEvent>((eachSubEvent) {
                                return eachSubEvent as SubCalendarEvent;
                              }))
                            ]),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderUnscheduledTiles(
                              height,
                              this
                                      .timelineSummary
                                      ?.nonViable
                                      ?.cast<SubCalendarEvent>() ??
                                  [],
                              this.isCheckStateActive,
                              switchTapFunction: () => setState(() {
                                this.isCheckStateActive =
                                    !this.isCheckStateActive;
                              }),
                              checkBoxStates: unscheduledTilesCheckStates,
                            ),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderTardyTiles(height, <SubCalendarEvent>[
                              ...((this.timelineSummary!.tardy ?? [])
                                  .map<SubCalendarEvent>((eachSubEvent) {
                                return eachSubEvent as SubCalendarEvent;
                              }))
                            ]),
                    ],
                  ),
              ),
        ),
      ),
    );
  }
}
