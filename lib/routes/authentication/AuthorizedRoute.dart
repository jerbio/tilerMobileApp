import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiler_app/firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../constants.dart' as Constants;

enum ActivePage { tilelist, search, addTile, procrastinate, review }

class AuthorizedRoute extends StatefulWidget {
  AuthorizedRoute();
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<AuthorizedRoute>
    with TickerProviderStateMixin {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  final ScheduleApi scheduleApi = new ScheduleApi();
  final AccessManager accessManager = AccessManager();
  Tuple3<Position, bool, bool> locationAccess = Tuple3(
      Position(
        altitudeAccuracy: 777.0,
        headingAccuracy: 0.0,
        longitude: Location.fromDefault().longitude!,
        latitude: Location.fromDefault().latitude!,
        timestamp: Utility.currentTime(),
        heading: 0,
        accuracy: 0,
        altitude: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
      false,
      true);
  late final LocalNotificationService localNotificationService;
  bool isAddButtonClicked = false;
  ActivePage selecedBottomMenu = ActivePage.tilelist;
  bool isLocationRequestTriggered = false;
  String _debugLabelString = "";
  String? _emailAddress;
  String? _smsNumber;
  String? _externalUserId;
  String? _language;
  String? _liveActivityId;
  bool _enableConsentButton = false;

  // CHANGE THIS parameter to true if you want to test GDPR privacy consent
  bool _requireConsent = false;

  @override
  void initState() {
    localNotificationService = LocalNotificationService();
    super.initState();

    initPlatformState();
    localNotificationService.initialize(this.context);
    accessManager.locationAccess(statusCheck: true).then((value) {
      setState(() {
        if (value != null) {
          locationAccess = value;
          return;
        }
      });
    });
  }

  void _onBottomNavigationTap(int index) {
    ActivePage selectedPage = ActivePage.tilelist;
    switch (index) {
      case 0:
        {
          AnalysticsSignal.send('SEARCH_PRESSED');
          Navigator.pushNamed(context, '/SearchTile');
        }
        break;
      case 1:
        {
          // Navigator.pushNamed(context, '/AddTile');
          AnalysticsSignal.send('GLOBAL_PLUS_BUTTON');
          displayDialog(MediaQuery.of(context).size);
        }
        break;
      case 2:
        {
          AnalysticsSignal.send('SETTING_PRESSED');
          Navigator.pushNamed(context, '/Setting');
        }
        break;
    }
  }

  void disableSearch() {
    this.setState(() {
      selecedBottomMenu = ActivePage.tilelist;
    });
  }

  Widget generateSearchWidget() {
    var eventNameSearch = Scaffold(
      extendBody: true,
      body: Container(
        child: EventNameSearchWidget(onInputCompletion: this.disableSearch),
      ),
    );

    return eventNameSearch;
  }

  bool _iskeyboardVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  Widget generatePredictiveAdd() {
    Widget containerWrapper = GestureDetector(
        onTap: () {
          setState(() {
            isAddButtonClicked = false;
          });
        },
        child: Container(
            height: MediaQuery.of(this.context).size.height,
            width: MediaQuery.of(this.context).size.width,
            color: Colors.amber,
            child: Stack(children: <Widget>[
              AutoAddTile(),
            ])));

    return containerWrapper;
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
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

  void displayDialog(Size screenSize) {
    showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.white70,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(1, 1, 1, 1),
        insetPadding: EdgeInsets.fromLTRB(0, 250, 0, 0),
        titlePadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [
                TileStyles.primaryColorHSL.toColor().withOpacity(0.75),
                TileStyles.primaryColorHSL
                    .withLightness(TileStyles.primaryColorHSL.lightness + .2)
                    .toColor()
                    .withOpacity(0.75),
              ],
            ),
          ),
          child: SizedBox(
            height: screenSize.height * 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // GestureDetector(
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.of(context).pushNamed('/ForecastPreview');
                //   },
                //   child: ListTile(
                //     leading: Image.asset('assets/images/binocular.png'),
                //     title: Text(
                //       AppLocalizations.of(context)!.forecast,
                //       style: TextStyle(
                //           fontSize: 20,
                //           fontFamily: TileStyles.rubikFontName,
                //           fontWeight: FontWeight.w300,
                //           color: Colors.white),
                //     ),
                //   ),
                // ),
                GestureDetector(
                  onTap: () {
                    AnalysticsSignal.send('REVISE_BUTTON');
                    final currentState =
                        this.context.read<ScheduleBloc>().state;
                    if (currentState is ScheduleLoadedState) {
                      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
                            isAlreadyLoaded: true,
                            renderedScheduleTimeline:
                                currentState.lookupTimeline,
                            renderedSubEvents: currentState.subEvents,
                            renderedTimelines: currentState.timelines,
                            message:
                                AppLocalizations.of(context)!.revisingSchedule,
                          ));
                    }
                    ScheduleApi().reviseSchedule().then((value) {
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
                    }).catchError((onError) {
                      final currentState =
                          this.context.read<ScheduleBloc>().state;
                      Fluttertoast.showToast(
                          msg: onError!.message,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.black45,
                          textColor: Colors.white,
                          fontSize: 16.0);
                      if (currentState is ScheduleEvaluationState) {
                        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                        refreshScheduleSummary(currentState.lookupTimeline);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Colors.white),
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                      child: Text(
                        AppLocalizations.of(context)!.revise,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      AnalysticsSignal.send('PROCRASTINATE_ALL_BUTTON');
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/Procrastinate')
                          .whenComplete(() {
                        var scheduleBloc =
                            this.context.read<ScheduleBloc>().state;
                        Timeline? lookupTimeline;
                        if (scheduleBloc is ScheduleLoadedState) {
                          this.context.read<ScheduleBloc>().add(
                              GetScheduleEvent(
                                  previousSubEvents: scheduleBloc.subEvents,
                                  scheduleTimeline: scheduleBloc.lookupTimeline,
                                  isAlreadyLoaded: true));
                          lookupTimeline = scheduleBloc.lookupTimeline;
                        }
                        if (scheduleBloc is ScheduleInitialState) {
                          this.context.read<ScheduleBloc>().add(
                              GetScheduleEvent(
                                  previousSubEvents: [],
                                  scheduleTimeline:
                                      Utility.initialScheduleTimeline,
                                  isAlreadyLoaded: false));
                          lookupTimeline = Utility.initialScheduleTimeline;
                        }

                        refreshScheduleSummary(lookupTimeline);
                      });
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: Stack(
                            children: [
                              Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  left: -15,
                                  child: Icon(Icons.chevron_right,
                                      color: Colors.white)),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                left: 0,
                                child: Icon(Icons.chevron_right,
                                    color: Colors.white),
                              ),
                              Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  left: 15,
                                  child: Icon(Icons.chevron_right,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        contentPadding: EdgeInsets.all(5),
                        title: Container(
                          child: Text(
                            AppLocalizations.of(context)!.deferAll,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: TileStyles.rubikFontName,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: () {
                    AnalysticsSignal.send('NEW_ADD_TILE');
                    Navigator.pop(context);
                    Map<String, dynamic> newTileParams = {'newTile': null};

                    Navigator.pushNamed(context, '/AddTile',
                        arguments: newTileParams);
                  },
                  child: ListTile(
                    leading: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                      child: Text(
                        AppLocalizations.of(context)!.addTile,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        elevation: 2,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(
          child: child,
          opacity: anim1,
        ),
      ),
      context: context,
    );
  }

  void locationUpdate(Tuple3<Position, bool, bool> update) {
    setState(() {
      locationAccess = update;
      isLocationRequestTriggered = true;
    });
  }

  Widget renderLocationRequest(AccessManager accessManager) {
    return LocationAccessWidget(accessManager, locationUpdate);
  }

  @override
  Widget build(BuildContext context) {
    // return renderLocationRequest();

    print('isLocationRequestTriggered $isLocationRequestTriggered');
    print('locationAccess $locationAccess');
    // if (!isLocationRequestTriggered &&
    //     !locationAccess.item2 &&
    //     locationAccess.item3) {
    //   return renderLocationRequest(accessManager);
    // }

    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      TileList(), //this is the default and we need to switch these to routes and so we dont loose back button support
      Container(
        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 7,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: DayRibbonCarousel(
          Utility.currentTime().dayDate,
          autoUpdateAnchorDate: true,
        ),
      ),
    ];
    if (isAddButtonClicked) {
      widgetChildren.add(generatePredictiveAdd());
    }
    dayStatusWidget.onDayStatusChange(DateTime.now());

    Widget? bottomNavigator;
    if (selecedBottomMenu == ActivePage.search) {
      bottomNavigator = null;
      var eventNameSearch = this.generateSearchWidget();
      widgetChildren.add(eventNameSearch);
    } else {
      bottomNavigator = ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Colors.white,
                Colors.white,
                Colors.white,
              ])),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.search,
                    color: TileStyles.primaryColorDarkHSL.toColor()),
                label: '',
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.add,
                    color: Color.fromRGBO(0, 0, 0, 0),
                  ),
                  label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings,
                      color: TileStyles.primaryColorDarkHSL.toColor()),
                  label: ''),
            ],
            unselectedItemColor: Colors.white,
            selectedItemColor: Colors.black,
            backgroundColor: Colors.transparent,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onBottomNavigationTap,
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Container(
          child: Stack(
            children: widgetChildren,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigator,
      floatingActionButton: isAddButtonClicked
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                AnalysticsSignal.send('GLOBAL_PLUS_BUTTON');
                displayDialog(MediaQuery.of(context).size);
              },
              child: Icon(
                Icons.add,
                size: 35,
                color: TileStyles.primaryColorDarkHSL.toColor(),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;

    String app_id = dotenv.env[Constants.oneSignalAppleIdKey] ?? "";
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(_requireConsent);

    // NOTE: Replace with your own app ID from https://www.onesignal.com

    OneSignal.initialize(app_id);
    // OneSignal.initialize('d77c1015-5cff-4b07-9d0b-06fee86d71b0');
    // OneSignal.initialize('17ef3538-ba4d-4951-a220-2c3e3d4c28fa');

    // OneSignalPushSubscription ppp = OneSignalPushSubscription();

    // OneSignal.LiveActivities.setupDefault();
    // await OneSignal.logout().then((value) => print("logged out of account"));
    // OneSignal.LiveActivities.setupDefault(options: new LiveActivitySetupOptions(enablePushToStart: false, enablePushToUpdate: true));

    // AndroidOnly stat only
    // OneSignal.Notifications.removeNotification(1);
    // OneSignal.Notifications.removeGroupedNotifications("group5");

    // OneSignal.Notifications.clearAll();

    ;

    OneSignal.User.getExternalId().then((value) {
      print("onesignal verified login");
      print("onesignal verified login " + (value ?? "novaluefound"));
    }).catchError((onError) {
      print("onesignal verified onError");
      print("onesignal verified onError " + (onError ?? "novaluefound"));
    });
    OneSignal.User.pushSubscription.addObserver((state) {
      print('OneSignal.User.pushSubscription.optedIn: ' +
          (OneSignal.User.pushSubscription.optedIn ?? false).toString());
      print('OneSignal.User.pushSubscription.id: ' +
          (OneSignal.User.pushSubscription.id ?? false).toString());
      print('OneSignal.User.pushSubscription.token: ' +
          (OneSignal.User.pushSubscription.token ?? false).toString());
      print('state.current.jsonRepresentation()): ' +
          (state.current.jsonRepresentation() ?? false).toString());
    });

    OneSignal.User.addObserver((state) {
      var userState = state.jsonRepresentation();
      print('OneSignal user changed: $userState');
    });

    OneSignal.Notifications.addPermissionObserver((state) {
      print("Has permission " + state.toString());
    });

    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
      this.setState(() {
        _debugLabelString =
            "Clicked notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print(
          'NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: ${event.notification.jsonRepresentation()}');

      /// Display Notification, preventDefault to not display
      // event.preventDefault();

      /// Do async work

      /// notification.display() to display after preventing default
      // event.notification.display();
      _handlePromptForPushPermission();

      this.setState(() {
        _debugLabelString =
            "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.InAppMessages.addClickListener((event) {
      this.setState(() {
        _debugLabelString =
            "In App Message Clicked: \n${event.result.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });
    OneSignal.InAppMessages.addWillDisplayListener((event) {
      print("ON WILL DISPLAY IN APP MESSAGE ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addDidDisplayListener((event) {
      print("ON DID DISPLAY IN APP MESSAGE ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addWillDismissListener((event) {
      print("ON WILL DISMISS IN APP MESSAGE ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addDidDismissListener((event) {
      print("ON DID DISMISS IN APP MESSAGE ${event.message.messageId}");
    });

    // await OneSignal.login(
    //         "onesignal_c17bda01-3a13-46b9-ae7a-b81b7c92dedb_892d862b-f678-42f6-90a1-d3fddc62de76")
    await OneSignal.login(
            'onesignal_c17bda01-3a13-46b9-ae7a-b81b7c92dedb_892d862b-f678-42f6-90a1-d3fddc62de76')
        // await OneSignal.login("broken-cce1a5b5-2cc8-40ae-a487-556a43f9d032")
        .then((value) => print("onesignal successful login"))
        .catchError((value) => print("onesignal failed to login "));

    this.setState(() {
      _enableConsentButton = _requireConsent;
    });

    // // Some examples of how to use In App Messaging public methods with OneSignal SDK
    // oneSignalInAppMessagingTriggerExamples();

    // // Some examples of how to use Outcome Events public methods with OneSignal SDK
    // oneSignalOutcomeExamples();

    // OneSignal.InAppMessages.paused(true);
  }

  void _handleSendTags() {
    print("Sending tags");
    OneSignal.User.addTagWithKey("test2", "val2");

    print("Sending tags array");
    var sendTags = {'test': 'value', 'test2': 'value2'};
    OneSignal.User.addTags(sendTags);
  }

  void _handleRemoveTag() {
    print("Deleting tag");
    OneSignal.User.removeTag("test2");

    print("Deleting tags array");
    OneSignal.User.removeTags(['test']);
  }

  void _handleGetTags() async {
    print("Get tags");

    var tags = await OneSignal.User.getTags();
    print(tags);
  }

  void _handlePromptForPushPermission() {
    print("Prompting for Permission");
    OneSignal.Notifications.requestPermission(true).then((value) {
      print("requested push notification successfully");
    }).catchError((err) {
      print("failed to register push notification");
      print(err);
    });
  }

  void _handleSetLanguage() {
    if (_language == null) return;
    print("Setting language");
    OneSignal.User.setLanguage(_language!);
  }

  void _handleSetEmail() {
    if (_emailAddress == null) return;
    print("Setting email");

    OneSignal.User.addEmail(_emailAddress!);
  }

  void _handleRemoveEmail() {
    if (_emailAddress == null) return;
    print("Remove email");

    OneSignal.User.removeEmail(_emailAddress!);
  }

  void _handleSetSMSNumber() {
    if (_smsNumber == null) return;
    print("Setting SMS Number");

    OneSignal.User.addSms(_smsNumber!);
  }

  void _handleRemoveSMSNumber() {
    if (_smsNumber == null) return;
    print("Remove smsNumber");

    OneSignal.User.removeSms(_smsNumber!);
  }

  void _handleConsent() {
    print("Setting consent to true");
    OneSignal.consentGiven(true);

    print("Setting state");
    this.setState(() {
      _enableConsentButton = false;
    });
  }

  void _handleSetLocationShared() {
    print("Setting location shared to true");
    OneSignal.Location.setShared(true);
  }

  void _handleGetExternalId() async {
    var externalId = await OneSignal.User.getExternalId();
    print('External ID: $externalId');
  }

  void _handleLogin() {
    print("Setting external user ID");
    if (_externalUserId == null) return;
    OneSignal.login(_externalUserId!);
    OneSignal.User.addAlias("fb_id", "1341524");
  }

  void _handleLogout() {
    OneSignal.logout();
    OneSignal.User.removeAlias("fb_id");
  }

  void _handleGetOnesignalId() async {
    var onesignalId = await OneSignal.User.getOnesignalId();
    print('OneSignal ID: $onesignalId');
  }

  oneSignalInAppMessagingTriggerExamples() async {
    /// Example addTrigger call for IAM
    /// This will add 1 trigger so if there are any IAM satisfying it, it
    /// will be shown to the user
    OneSignal.InAppMessages.addTrigger("trigger_1", "one");

    /// Example addTriggers call for IAM
    /// This will add 2 triggers so if there are any IAM satisfying these, they
    /// will be shown to the user
    Map<String, String> triggers = new Map<String, String>();
    triggers["trigger_2"] = "two";
    triggers["trigger_3"] = "three";
    OneSignal.InAppMessages.addTriggers(triggers);

    // Removes a trigger by its key so if any future IAM are pulled with
    // these triggers they will not be shown until the trigger is added back
    OneSignal.InAppMessages.removeTrigger("trigger_2");

    // Create a list and bulk remove triggers based on keys supplied
    List<String> keys = ["trigger_1", "trigger_3"];
    OneSignal.InAppMessages.removeTriggers(keys);

    // Toggle pausing (displaying or not) of IAMs
    OneSignal.InAppMessages.paused(true);
    var arePaused = await OneSignal.InAppMessages.arePaused();
    print('Notifications paused $arePaused');
  }

  oneSignalOutcomeExamples() async {
    OneSignal.Session.addOutcome("normal_1");
    OneSignal.Session.addOutcome("normal_2");

    OneSignal.Session.addUniqueOutcome("unique_1");
    OneSignal.Session.addUniqueOutcome("unique_2");

    OneSignal.Session.addOutcomeWithValue("value_1", 3.2);
    OneSignal.Session.addOutcomeWithValue("value_2", 3.9);
  }
}
