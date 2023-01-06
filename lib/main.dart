import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/routes/authenticatedUser/durationDial.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDuration.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastPreview.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/procrastinateAll.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/timeRestrictionRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/pickColor.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';
import 'routes/authentication/preAuthenticationRoute.dart';
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
  Future<bool> authenticateUser() async {
    Authentication authentication = new Authentication();
    isAuthenticated = await authentication.isUserAuthenticated();
    return isAuthenticated;
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
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SubCalendarTilesBloc()),
          BlocProvider(create: (context) => ScheduleBloc()),
          BlocProvider(create: (context) => CalendarTileBloc())
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
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
            '/PickColor': (ctx) => PickColor(),
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
          home: FutureBuilder<bool>(
              future: authenticateUser(),
              builder: (context, AsyncSnapshot<bool> snapshot) {
                Widget retValue;
                if (snapshot.hasData) {
                  if (isAuthenticated) {
                    retValue = AuthorizedRoute();
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
