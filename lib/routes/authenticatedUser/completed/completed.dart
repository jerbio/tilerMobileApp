import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/elapsedTiles/confirmation_dialog.dart';
import 'package:tiler_app/components/elapsedTiles/elapsed_action.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastPreview.dart';
import 'package:tiler_app/routes/authentication/AuthorizedRoute.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import '../../../bloc/scheduleSummary/schedule_summary_bloc.dart';
import '../../../components/PendingWidget.dart';
import '../../../components/elapsedTiles/NavigationTemplate.dart';
import '../../../styles.dart';
import '../../../data/subCalendarEvent.dart';
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
        child: CompletedTilesWidget());
  }
}

class CompletedTilesWidget extends StatefulWidget {
  // final GlobalKey<NavigatorState> navigatorKey;
  CompletedTilesWidget({super.key});

  @override
  State<CompletedTilesWidget> createState() => _CompletedTilesWidgetState();
}

class _CompletedTilesWidgetState extends State<CompletedTilesWidget> {
  List<bool> selectedOption = [];
  List<TilerEvent> selectedEvents = [];
  SubCalendarEventApi _subCalendarEventApi = new SubCalendarEventApi();
  bool isProcessComplete = false;

  String formatDateTime(DateTime dateTime) {
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
    isProcessComplete = false;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return BlocConsumer<ScheduleSummaryBloc, ScheduleSummaryState>(
      listenWhen: (previous, current) {
        return true;
      },
      buildWhen: (previous, current) {
        return current is ScheduleSummaryLoadingTaskState ||
            current is ScheduleDaySummaryLoading ||
            current is ScheduleDaySummaryLoaded ||
            current is ScheduleSummaryCompleteTaskState;
      },
      listener: (context, state) {
        if (state is ScheduleSummaryLoadingTaskState) {
          _showLoadingDialog();
        } else if (state is ScheduleSummaryCompleteTaskState) {
          _showCompletionDialog();
        } else if (state is ScheduleSummaryErrorState) {
          _closeAnyOpenDialogs();
          _showErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        if (state is ScheduleDaySummaryLoaded) {
          if (selectedOption.length != state.elapsedTasks.length) {
            selectedOption =
                List.generate(state.elapsedTasks.length, (index) => false);
          }
          return _buildTaskList(context, state, height);
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
              child: PendingWidget(
                imageAsset: TileStyles.evaluatingScheduleAsset,
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

  Widget _buildTaskList(
      BuildContext context, ScheduleDaySummaryLoaded state, double height) {
    return Container(
      child: NavigationTemplateWidget(
        onCancel: () {
          Navigator.pop(context);
        },
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
        child: state.elapsedTasks.isEmpty
            ? Container(
                child: Center(child: Text('No elapsed tasks available')),
              )
            : Container(
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
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.elapsedTasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: height / (height / 20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Checkbox widget
                                    SizedBox(
                                      height: height / (height / 30),
                                      width: height / (height / 30),
                                      child: Center(
                                        child: Transform.scale(
                                          scale: 1.4,
                                          child: Checkbox(
                                              checkColor: Colors.transparent,
                                              fillColor: MaterialStateProperty
                                                  .resolveWith<Color>(
                                                      (Set<MaterialState>
                                                          states) {
                                                if (states.contains(
                                                    MaterialState.selected)) {
                                                  return Colors
                                                      .black; // Custom color when checked
                                                }
                                                return Colors
                                                    .transparent; // Custom color when unchecked
                                              }),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          height /
                                                              (height / 10))),
                                              value: selectedOption[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedOption[index] =
                                                      value ?? false;
                                                  if (value ?? false) {
                                                    selectedEvents.add(state
                                                        .elapsedTasks[index]);
                                                  } else {
                                                    selectedEvents.remove(state
                                                        .elapsedTasks[index]);
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
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              fontSize: height / (height / 14),
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black),
                                        ),
                                        SizedBox(
                                          height: height / (height / 10),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              color: Colors.black,
                                              fontSize: height / (height / 14),
                                            ),
                                            children: [
                                              TextSpan(
                                                text: DateFormat('HH:mm a')
                                                    .format(state
                                                        .elapsedTasks[index]
                                                        .startTime),
                                              ),
                                              TextSpan(text: " - "),
                                              TextSpan(
                                                text: DateFormat('HH:mm a')
                                                    .format(state
                                                        .elapsedTasks[index]
                                                        .endTime),
                                              ),
                                              TextSpan(text: ', '),
                                              TextSpan(
                                                  text: formatDateTime(state
                                                      .elapsedTasks[index]
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
                                    // Complete Button
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (BuildContext loadingContext) {
                                            return ConfirmationDialog(
                                              height: height,
                                              textContent:
                                                  "Are you sure you want to complete this tile?",
                                              popEvent: () =>
                                                  Navigator.pop(context),
                                              proceedEvent: () async {
                                                Navigator.pop(
                                                    loadingContext); // Close the confirmation dialog
                                                _showLoadingDialog();

                                                // Wait for the task completion
                                                bool success = await BlocProvider
                                                        .of<ScheduleSummaryBloc>(
                                                            context)
                                                    .completeTask(state
                                                            .elapsedTasks[index]
                                                        as SubCalendarEvent);

                                                // Close loading dialog
                                                Navigator.of(context,
                                                        rootNavigator: true)
                                                    .pop();

                                                // Show completion or error dialog
                                                if (success) {
                                                  showDialog(
                                                    context: context,

                                                    barrierDismissible:
                                                        false, // Prevent the user from dismissing the dialog
                                                    builder: (BuildContext
                                                        completionContext) {
                                                      // Start a timer to close the dialog after 1 second
                                                      Future.delayed(
                                                          Duration(seconds: 1),
                                                          () {
                                                        // Check if the dialog is still showing before trying to close it
                                                        if (Navigator.of(
                                                                completionContext)
                                                            .canPop()) {
                                                          Navigator.of(
                                                                  completionContext)
                                                              .pop();
                                                        }
                                                      });

                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        content: Container(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                "assets/images/task_completed.png",
                                                                width: height /
                                                                    (height /
                                                                        174),
                                                              ),
                                                              SizedBox(
                                                                width: height /
                                                                    (height /
                                                                        174),
                                                                child: Center(
                                                                  child: Text(
                                                                    'Tile completed successfully!',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            TileStyles
                                                                                .rubikFontName,
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ).then(
                                                    (_) {
                                                      // This will run after the dialog is closed
                                                      BlocProvider.of<
                                                                  ScheduleSummaryBloc>(
                                                              context)
                                                          .add(
                                                              GetElapsedTasksEvent()); // Update UI
                                                    },
                                                  );
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                        errorContext) {
                                                      return AlertDialog(
                                                        content: Text(
                                                            "Task completion failed."),
                                                        actions: [
                                                          TextButton(
                                                            child: Text("OK"),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    errorContext),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: ElapsedActionButton(
                                          height: height,
                                          iconData: Icons.check,
                                          label: "Complete"),
                                    ),

                                    // Sizedbox
                                    SizedBox(
                                      width: height / (height / 10),
                                    ),

                                    // Defer Button
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (loadingContext) {
                                            return ConfirmationDialog(
                                              height: height,
                                              textContent:
                                                  "Are you sure you want to defer this tile?",
                                              popEvent: () =>
                                                  Navigator.pop(context),
                                              proceedEvent: () async {
                                                // Current tile extracted
                                                SubCalendarEvent tile =
                                                    state.elapsedTasks[index]
                                                        as SubCalendarEvent;

                                                Navigator.pop(
                                                    loadingContext); // Close the confirmation dialog
                                                _showLoadingDialog();

                                                // Wait for the task completion
                                                bool success = await BlocProvider
                                                        .of<ScheduleSummaryBloc>(
                                                            context)
                                                    .deferTask(
                                                  tile.id != null
                                                      ? tile.id!
                                                      : "",
                                                  Duration(hours: 4),
                                                );

                                                // Close loading dialog
                                                Navigator.of(context,
                                                        rootNavigator: true)
                                                    .pop();

                                                // Show completion or error dialog
                                                if (success) {
                                                  showDialog(
                                                    context: context,

                                                    barrierDismissible:
                                                        false, // Prevent the user from dismissing the dialog
                                                    builder: (BuildContext
                                                        completionContext) {
                                                      // Start a timer to close the dialog after 1 second
                                                      Future.delayed(
                                                        Duration(seconds: 1),
                                                        () {
                                                          // Check if the dialog is still showing before trying to close it
                                                          if (Navigator.of(
                                                                  completionContext)
                                                              .canPop()) {
                                                            Navigator.of(
                                                                    completionContext)
                                                                .pop();
                                                          }
                                                        },
                                                      );

                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        content: Container(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                "assets/images/task_completed.png",
                                                                width: height /
                                                                    (height /
                                                                        174),
                                                              ),
                                                              SizedBox(
                                                                width: height /
                                                                    (height /
                                                                        174),
                                                                child: Center(
                                                                  child: Text(
                                                                    'Tile deferred successfully!',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            TileStyles
                                                                                .rubikFontName,
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ).then(
                                                    (_) {
                                                      // This will run after the dialog is closed
                                                      BlocProvider.of<
                                                                  ScheduleSummaryBloc>(
                                                              context)
                                                          .add(
                                                              GetElapsedTasksEvent()); // Update UI
                                                    },
                                                  );
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                        errorContext) {
                                                      return AlertDialog(
                                                        content: Text(
                                                            "Task completion failed."),
                                                        actions: [
                                                          TextButton(
                                                            child: Text("OK"),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    errorContext),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        );
                                      },
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
                            child: Center(
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
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
      ),
    );
  }

  void _closeAnyOpenDialogs() {
    // if (widget.navigatorKey.currentState!.canPop()) {
    //   widget.navigatorKey.currentState!.pop();
    //   print("Closed an open dialog.");
    // }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) => PendingWidget(
        imageAsset: TileStyles.evaluatingScheduleAsset,
      ),
    );
  }

  void _showCompletionDialog() {
    _closeAnyOpenDialogs(); // Ensure previous dialogs are closed
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) {
        return AlertDialog(
          content: Text("Task completed successfully!"),
        );
      },
    );
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _closeAnyOpenDialogs();
        setState(() {}); // Ensure the UI is updated after task completion
      }
    });
  }

  void _showErrorDialog(String error) {
    _closeAnyOpenDialogs(); // Ensure previous dialogs are closed
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) {
        return AlertDialog(
          content: Text("Error: $error"),
        );
      },
    );
  }
}
