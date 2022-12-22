import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/routes/authenticatedUser/durationDial.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDuration.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastPreview.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/timeRestrictionRoute.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'routes/authentication/preAuthenticationRoute.dart';
import 'routes/authentication/authorizedRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants.dart' as Constants;

import 'services/localAuthentication.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  if (!Constants.isProduction) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(TilerApp());
}

class TilerApp extends StatelessWidget {
  // This widget is the root of your application.
  bool isAuthenticated = false;
  Future<bool> authenticateUser() async {
    Authentication authentication = new Authentication();
    isAuthenticated = await authentication.isUserAuthenticated();
    return isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: <String, WidgetBuilder>{
        '/AuthorizedUser': (BuildContext context) => new AuthorizedRoute(),
        '/LoggedOut': (BuildContext context) => new PreAuthenticationRoute(),
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
        '/DurationDial': (ctx) => DurationDial(),
      },
      localizationsDelegates: [
        AppLocalizations.delegate, // Add this line
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
                retValue = PreAuthenticationRoute();
              }
            } else {
              retValue = CircularProgressIndicator();
            }
            return retValue;
          }),
    );
  }
}
