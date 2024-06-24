import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/bloc/integrations_bloc.dart';
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
import 'package:tiler_app/routes/authenticatedUser/settings/integrationWidgetRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/settings.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/onBoarding/on_boarding_bloc.dart';
import 'routes/authentication/authorizedRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import '../../constants.dart' as Constants;

import 'services/localAuthentication.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // if (Constants.isDebug) {
    //   return super.createHttpClient(context)
    //     ..badCertificateCallback =
    //         (X509Certificate cert, String host, int port) => true;
    // }
    return super.createHttpClient(context);
  }
}

Future main() async {
  if (!Constants.isProduction) {
    HttpOverrides.global = MyHttpOverrides();
  }
  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(TilerApp());
}

class TilerApp extends StatefulWidget {
  @override
  _TilerAppState createState() => new _TilerAppState();
}

class _TilerAppState extends State<TilerApp> {
  bool isAuthenticated = false;
  Authentication? authentication;
  OnBoardingApi? onBoardingApi;
  @override
  void initState() {
    onBoardingApi = OnBoardingApi();
    super.initState();
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
          BlocProvider(create: (context) => IntegrationsBloc()),
          BlocProvider(create: (context) => OnboardingBloc(onBoardingApi!)),
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
            '/Integrations': (ctx) => IntegrationWidgetRoute(),
            '/OnBoarding':(ctx) => OnboardingView()
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
                    retValue = FutureBuilder<bool>(
                      future: Utility.checkOnboardingStatus(),
                      builder: (context, AsyncSnapshot<bool> onboardingSnapshot) {
                        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                          return renderPending();
                        } else if (onboardingSnapshot.hasError) {
                          showErrorMessage("Error checking onboarding status.");
                          return SignInRoute();
                        } else {
                          return onboardingSnapshot.data! ? AuthorizedRoute() : OnboardingView();
                        }
                      },
                    );
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