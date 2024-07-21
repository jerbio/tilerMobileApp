import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/elapsedTiles/elapsed_action.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import '../../../../bloc/forecast/forecast_bloc.dart';
import '../../../../styles.dart';
import '../../../bloc/scheduleSummary/schedule_summary_bloc.dart';
import '../../../components/tileUI/tile.dart';
import '../../../services/api/subCalendarEventApi.dart';

class CompletedTiles extends StatefulWidget {
  const CompletedTiles({super.key});

  @override
  State<CompletedTiles> createState() => _CompletedTilesState();
}

class _CompletedTilesState extends State<CompletedTiles> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleSummaryBloc()..add(GetElapsedTasksEvent()),
      child: CompletedTilesWidget(),
    );
  }
}

class CompletedTilesWidget extends StatefulWidget {
  CompletedTilesWidget({super.key});

  @override
  State<CompletedTilesWidget> createState() => _CompletedTilesWidgetState();
}

class _CompletedTilesWidgetState extends State<CompletedTilesWidget> {
  List<bool> selectedOption = [];
  List<TilerEvent> selectedEvents = [];
  SubCalendarEventApi _subCalendarEventApi = new SubCalendarEventApi();

  String formatDateTime(DateTime dateTime) {
    // Format day of the week, month, and day of the month
    String formattedDay =
        DateFormat('EEE').format(dateTime); // Short weekday name
    String month = DateFormat('MMM').format(dateTime); // Short month name
    String day = dateTime.day.toString();

    return '$formattedDay $month $day';
  }

  @override
  void initState() {
    super.initState();
    selectedOption = [];
    selectedEvents = [];
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
      builder: (context, state) {
        if (state is ScheduleDaySummaryLoaded) {
          if (selectedOption.length != state.elapsedTasks.length) {
            selectedOption =
                List.generate(state.elapsedTasks.length, (index) => false);
          }
          return Container(
            child: CancelAndProceedTemplateWidget(
              appBar: AppBar(
                backgroundColor: TileStyles.primaryColor,
                title: Text(
                  "Complete Tiles",
                  style: TextStyle(
                      color: TileStyles.appBarTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22),
                ),
                centerTitle: true,
                elevation: 0,
                automaticallyImplyLeading: false,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: height / (height / 15),
                    horizontal: height / (height / 10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-select to complete all tiles',
                      style: TextStyle(
                        fontFamily: TileStyles.rubikFontName,
                        fontSize: height / (height / 14),
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.elapsedTasks.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height / (height / 20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Checkbox widget
                                          SizedBox(
                                            height: height / (height / 30),
                                            width: height / (height / 30),
                                            child: Center(
                                              child: Transform.scale(
                                                scale: 1.4,
                                                child: Checkbox(
                                                    checkColor:
                                                        Colors.transparent,
                                                    fillColor:
                                                        WidgetStateProperty
                                                            .resolveWith<
                                                                Color>((Set<
                                                                    WidgetState>
                                                                states) {
                                                      if (states.contains(
                                                          WidgetState
                                                              .selected)) {
                                                        return Colors
                                                            .black; // Custom color when checked
                                                      }
                                                      return Colors
                                                          .transparent; // Custom color when unchecked
                                                    }),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(height /
                                                                (height / 10))),
                                                    value:
                                                        selectedOption[index],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        selectedOption[index] =
                                                            value ?? false;
                                                        if (value ?? false) {
                                                          selectedEvents.add(
                                                              state.elapsedTasks[
                                                                  index]);
                                                        } else {
                                                          selectedEvents.remove(
                                                              state.elapsedTasks[
                                                                  index]);
                                                        }
                                                      });
                                                    }),
                                              ),
                                            ),
                                          ),

                                          // Spacer Sizedbox
                                          SizedBox(
                                            width: height / (height / 10),
                                          ),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                state.elapsedTasks[index].name!,
                                                style: TextStyle(
                                                    fontFamily: TileStyles
                                                        .rubikFontName,
                                                    fontSize:
                                                        height / (height / 14),
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black),
                                              ),
                                              SizedBox(
                                                height: height / (height / 10),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: TileStyles
                                                        .rubikFontName,
                                                    color: Colors.black,
                                                    fontSize:
                                                        height / (height / 14),
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          DateFormat('HH:mm a')
                                                              .format(state
                                                                  .elapsedTasks[
                                                                      index]
                                                                  .startTime),
                                                    ),
                                                    TextSpan(text: " - "),
                                                    TextSpan(
                                                      text:
                                                          DateFormat('HH:mm a')
                                                              .format(state
                                                                  .elapsedTasks[
                                                                      index]
                                                                  .endTime),
                                                    ),
                                                    TextSpan(text: ', '),
                                                    TextSpan(
                                                        text: formatDateTime(
                                                            state
                                                                .elapsedTasks[
                                                                    index]
                                                                .endTime))
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {},
                                            child: ElapsedActionButton(
                                                height: height,
                                                iconData: Icons.check,
                                                label: "Complete"),
                                          ),
                                          SizedBox(
                                            width: height / (height / 10),
                                          ),
                                          GestureDetector(
                                            onTap: () {},
                                            child: ElapsedActionButton(
                                                height: height,
                                                iconData: Icons.chevron_right,
                                                label: "Defer"),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          selectedEvents.length > 1
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: height / (height / 20),
                                  ),
                                  child: Container(
                                    width: height / (height / 287),
                                    height: height / (height / 44),
                                    decoration: BoxDecoration(
                                      color: TileStyles.primaryColor,
                                      borderRadius: BorderRadius.circular(
                                          height / (height / 10)),
                                      border: Border.all(
                                        width: height / height,
                                        color: Color(0xFF87162A),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Complete All',
                                        style: TextStyle(
                                          fontFamily: TileStyles.rubikFontName,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        } else if (state is ScheduleDaySummaryLoading) {
          return Container(
            child: CancelAndProceedTemplateWidget(
              appBar: AppBar(
                backgroundColor: TileStyles.primaryColor,
                title: Text(
                  "Complete Tiles",
                  style: TextStyle(
                      color: TileStyles.appBarTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22),
                ),
                centerTitle: true,
                elevation: 0,
                automaticallyImplyLeading: false,
              ),
              child: Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        } else {
          return Container(
            child: CancelAndProceedTemplateWidget(
              appBar: AppBar(
                backgroundColor: TileStyles.primaryColor,
                title: Text(
                  "Complete Tiles",
                  style: TextStyle(
                      color: TileStyles.appBarTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22),
                ),
                centerTitle: true,
                elevation: 0,
                automaticallyImplyLeading: false,
              ),
              child: Container(
                child: Center(child: Text('No elapsed tasks available')),
              ),
            ),
          );
        }
      },
    );
  }
}
