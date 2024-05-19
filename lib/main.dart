import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/location/location_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';

import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/routes/authenticatedUser/durationDial.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDuration.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastPreview.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/procrastinateAll.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repetitionRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/timeRestrictionRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/pickColor.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/settings.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/authentication/authorizedRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../../constants.dart' as Constants;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/localAuthentication.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (Constants.isDebug) {
      return super.createHttpClient(context)
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
    }
    return super.createHttpClient(context);
  }
}

Future main() async {
  if (!Constants.isProduction) {
    HttpOverrides.global = MyHttpOverrides();
  }
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TilerApp());
}

class TilerApp extends StatefulWidget {
  @override
  _TilerAppState createState() => new _TilerAppState();
}

class _TilerAppState extends State<TilerApp> {
  bool isAuthenticated = false;
  Authentication? authentication;
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
    super.initState();
    initPlatformState();
  }

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
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

    OneSignal.LiveActivities.setupDefault();
    // OneSignal.LiveActivities.setupDefault(options: new LiveActivitySetupOptions(enablePushToStart: false, enablePushToUpdate: true));

    // AndroidOnly stat only
    // OneSignal.Notifications.removeNotification(1);
    // OneSignal.Notifications.removeGroupedNotifications("group5");

    // OneSignal.Notifications.clearAll();

    OneSignal.User.pushSubscription.addObserver((state) {
      print(OneSignal.User.pushSubscription.optedIn);
      print(OneSignal.User.pushSubscription.id);
      print(OneSignal.User.pushSubscription.token);
      print(state.current.jsonRepresentation());
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
      event.preventDefault();

      /// Do async work

      /// notification.display() to display after preventing default
      event.notification.display();
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

    this.setState(() {
      _enableConsentButton = _requireConsent;
    });

    // Some examples of how to use In App Messaging public methods with OneSignal SDK
    oneSignalInAppMessagingTriggerExamples();

    // Some examples of how to use Outcome Events public methods with OneSignal SDK
    oneSignalOutcomeExamples();

    OneSignal.InAppMessages.paused(true);
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

  Widget renderPending() {
    return Center(
        child: Stack(children: [
      Center(
          child: Image.asset('assets/images/tiler_logo_white_text.png',
              fit: BoxFit.cover, scale: 7)),
    ]));
  }

  Future<Tuple2<bool, String>> authenticateUser(BuildContext context) async {
    authentication = new Authentication();
    var authenticationResult = await authentication!.isUserAuthenticated();
    return authenticationResult;
  }

  @override
  Widget build(BuildContext context) {
    Map<int, Color> color = {
      50: Color.fromRGBO(239, 48, 84, .1),
      100: Color.fromRGBO(239, 48, 84, .2),
      200: Color.fromRGBO(239, 48, 84, .3),
      300: Color.fromRGBO(239, 48, 84, .4),
      400: Color.fromRGBO(239, 48, 84, .5),
      500: Color.fromRGBO(239, 48, 84, .6),
      600: Color.fromRGBO(239, 48, 84, .7),
      700: Color.fromRGBO(239, 48, 84, .8),
      800: Color.fromRGBO(239, 48, 84, .9),
      900: Color.fromRGBO(239, 48, 84, 1),
    };
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SubCalendarTileBloc()),
          BlocProvider(create: (context) => ScheduleBloc()),
          BlocProvider(create: (context) => CalendarTileBloc()),
          BlocProvider(create: (context) => UiDateManagerBloc()),
          BlocProvider(create: (context) => ScheduleSummaryBloc()),
          BlocProvider(create: (context) => LocationBloc()),
        ],
        child: MaterialApp(
          title: 'Tiler',
          theme: ThemeData(
            fontFamily: TileStyles.rubikFontName,
            primarySwatch: MaterialColor(0xFF880E4F, color),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          routes: <String, WidgetBuilder>{
            '/AuthorizedUser': (BuildContext context) => new AuthorizedRoute(),
            '/LoggedOut': (BuildContext context) => new SignInRoute(),
            '/AddTile': (BuildContext context) => new AddTile(),
            '/SearchTile': (BuildContext context) =>
                new EventNameSearchWidget(context: context),
            '/LocationRoute': (BuildContext context) => new LocationRoute(),
            '/CustomRestrictionsRoute': (BuildContext context) =>
                new CustomTimeRestrictionRoute(),
            '/TimeRestrictionRoute': (BuildContext context) =>
                new TimeRestrictionRoute(),
            '/ForecastPreview': (ctx) => ForecastPreview(),
            '/ForecastDuration': (ctx) => ForecastDuration(),
            '/Procrastinate': (ctx) => ProcrastinateAll(),
            '/DurationDial': (ctx) => DurationDial(
                  presetDurations: [
                    Duration(minutes: 30),
                    Duration(hours: 1),
                  ],
                ),
            '/repetitionRoute': (ctx) => RepetitionRoute(),
            '/PickColor': (ctx) => PickColor(),
            '/Setting': (ctx) => Setting(),
          },
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''), // English, no country code
            Locale('es', ''), // Spanish, no country code
          ],
          home: FutureBuilder<Tuple2<bool, String>>(
              future: authenticateUser(context),
              builder: (context, AsyncSnapshot<Tuple2<bool, String>> snapshot) {
                Widget retValue;
                if (snapshot.hasData) {
                  if (!snapshot.data!.item1) {
                    if (snapshot.data!.item2 == Constants.cannotVerifyError) {
                      showErrorMessage(AppLocalizations.of(context)!
                          .issuesConnectingToTiler);
                      return renderPending();
                    }
                    authentication?.deauthenticateCredentials();
                    retValue = SignInRoute();
                  }

                  if (snapshot.data!.item1) {
                    context.read<ScheduleBloc>().add(LogInScheduleEvent());
                    AnalysticsSignal.send('LOGIN-VERIFIED');
                    retValue = new AuthorizedRoute();
                  } else {
                    authentication?.deauthenticateCredentials();
                    retValue = SignInRoute();
                  }
                } else {
                  retValue = renderPending();
                }
                return retValue;
              }),
        ));
  }
}
