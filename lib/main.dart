import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
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
import 'package:tuple/tuple.dart';
import 'components/tileUI/summaryPage.dart';
import 'routes/authentication/authorizedRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants.dart' as Constants;

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

void main() {
  if (!Constants.isProduction) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(TilerApp());
}

class TilerApp extends StatelessWidget {
  bool isAuthenticated = false;
  Future<Tuple2<bool, String>> authenticateUser(BuildContext context) async {
    Authentication authentication = new Authentication();
    var authenticationResult = await authentication.isUserAuthenticated();
    return authenticationResult;
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
          BlocProvider(create: (context) => UiDateManagerBloc())
        ],
        child: MaterialApp(
          title: 'Tiler',
          theme: ThemeData(
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
            '/DurationDial': (ctx) => DurationDial(),
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
                  if (!snapshot.data!.item1 &&
                      snapshot.data!.item2 == Constants.cannotVerifyError) {
                    showErrorMessage(
                        AppLocalizations.of(context)!.issuesConnectingToTiler);
                    return renderPending();
                  }

                  if (snapshot.data!.item1) {
                    context.read<ScheduleBloc>().add(LogInScheduleEvent());
                    retValue = new AuthorizedRoute();
                  } else {
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
