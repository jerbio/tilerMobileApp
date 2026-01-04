import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/location/location_bloc.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/previewSummary/preview_summary_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/workProfileWidget.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/vibeChat/vibeChat.dart';
// import 'package:tiler_app/firebase_options.dart';
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
import 'package:tiler_app/routes/authenticatedUser/settings/account%20info/accountInfo.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/connetions.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/notificationsPreferences/notificationPreferences.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareRoute.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/chatApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/vibeChat/vibe_chat_bloc.dart';
import 'components/notification_overlay.dart';
import 'routes/authenticatedUser/settings/settingsWidget.dart';
import 'routes/authentication/authorizedRoute.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import '../../constants.dart' as Constants;

import 'services/api/onBoardingApi.dart';
import 'services/localAuthentication.dart';
import 'package:logging/logging.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (Constants.isDebug) {
      return super.createHttpClient(context)
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
    }
    Logger.root.level = Level.ALL;
    return super.createHttpClient(context);
  }
}

Future main() async {
  if (!Constants.isProduction) {
    HttpOverrides.global = MyHttpOverrides();
  }
  await dotenv.load(fileName: ".env");
  // if (!Constants.isDebug) {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // }
  runApp(TilerApp());
}

class TilerApp extends StatefulWidget {
  @override
  _TilerAppState createState() => new _TilerAppState();
}

class _TilerAppState extends State<TilerApp> {
  bool isAuthenticated = false;
  Authentication? authentication;
  NotificationOverlayMessage? notificationOverlayMessage;
  OnBoardingApi? onBoardingApi;
  bool isDarkMode = false;

  void _loadTheme() async {
    final savedIsDark = await ThemeManager.getThemeMode();
    setState(() => isDarkMode = savedIsDark); // Update state after load
  }

  @override
  void initState() {
    onBoardingApi = OnBoardingApi();
    _loadTheme();
    notificationOverlayMessage = NotificationOverlayMessage();
    super.initState();
  }

  Widget splashScreen() {
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
    return MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) => SubCalendarTileBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(
              create: (context) => CalendarTileBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(create: (context) => UiDateManagerBloc()),
          BlocProvider(
              create: (context) => ScheduleSummaryBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(
              create: (context) => LocationBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(create: (context) => TileListCarouselBloc()),
          BlocProvider(
              create: (context) => DeviceSettingBloc(
                    getContextCallBack: () {
                      return this.context;
                    },
                    initialIsDarkMode: isDarkMode,
                  )),
          //BlocProvider(create: (context) => OnboardingBloc(onBoardingApi!, SettingsApi(getContextCallBack: () => context))),
          BlocProvider(
              create: (context) => ForecastBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(
              create: (context) => ScheduleBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(create: (context) => WeeklyUiDateManagerBloc()),
          BlocProvider(create: (context) => MonthlyUiDateManagerBloc()),
          BlocProvider(
              create: (context) => PreviewSummaryBloc(getContextCallBack: () {
                    return this.context;
                  })),
          BlocProvider(
              create: (context) => VibeChatBloc(
                chatApi: ChatApi(getContextCallBack: () => context),
              )..add(LoadVibeChatSessionEvent())
          ),
        ],
        child: BlocBuilder<DeviceSettingBloc, DeviceSettingState>(
            buildWhen: (previous, current) =>
                previous.isDarkMode != current.isDarkMode,
            builder: (context, settingsState) {
              return MaterialApp(
                title: 'Tiler',
                debugShowCheckedModeBanner: false,
                theme: TileThemeData.lightTheme,
                darkTheme: TileThemeData.darkTheme,
                themeMode:
                    settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                routes: <String, WidgetBuilder>{
                  '/AuthorizedUser': (BuildContext context) =>
                      new AuthorizedRoute(),
                  '/LoggedOut': (BuildContext context) => new SignInRoute(),
                  '/AddTile': (BuildContext context) => new AddTile(),
                  '/SearchTile': (BuildContext context) =>
                      new EventNameSearchWidget(context: context),
                  '/LocationRoute': (BuildContext context) =>
                      new LocationRoute(),
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
                  '/RepetitionRoute': (ctx) => RepetitionRoute(),
                  '/PickColor': (ctx) => PickColor(),
                  '/Setting': (ctx) => Settings(),
                  '/Integrations': (ctx) => IntegrationWidgetRoute(),
                  '/OnBoarding': (ctx) => OnboardingView(),
                  '/TileCluster': (ctx) => CreateTileShareClusterWidget(),
                  '/DesignatedTileList': (ctx) => DesignatedTileList(),
                  '/TileShare': (ctx) => TileShareRoute(),
                  '/accountInfo': (ctx) => AccountInfo(),
                  '/notificationsPreferences': (ctx) =>
                      NotificationPreferences(),
                  '/Connections': (ctx) => Connections(),
                  '/tilePreferences': (ctx) => TilePreferencesScreen(),
                  '/onBoardingWorkProfile': (ctx) => WorkProfileWidget(),
                  '/vibeChat': (ctx) => VibeChat()
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
                    builder: (context,
                        AsyncSnapshot<Tuple2<bool, String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // While waiting for the future to complete, show the splash screen
                        return splashScreen();
                      } else {
                        // // Check if AppLocalizations is available
                        // if (AppLocalizations.of(context) != null) {
                        //   localizationService =
                        //       LocalizationService(AppLocalizations.of(context)!);
                        // } else {
                        //   // If localization data isn't available yet, show the splash screen
                        //   return renderPending();
                        // }

                        Widget retValue;

                        if (snapshot.hasError) {
                          // If there was an error during authentication, handle it here
                          notificationOverlayMessage!.showToast(
                            context,
                            "Error during authentication: ${snapshot.error}",
                            NotificationOverlayMessageType.error,
                          );
                          return SignInRoute();
                        } else if (snapshot.hasData) {
                          if (!snapshot.data!.item1) {
                            if (snapshot.data!.item2 ==
                                Constants.cannotVerifyError) {
                              notificationOverlayMessage!.showToast(
                                context,
                                AppLocalizations.of(context)!
                                    .issuesConnectingToTiler,
                                NotificationOverlayMessageType.error,
                              );
                              return splashScreen();
                            }
                            authentication?.deauthenticateCredentials();
                            retValue = SignInRoute();
                          } else {
                            context
                                .read<ScheduleBloc>()
                                .add(LogInScheduleEvent(getContextCallBack: () {
                              return context;
                            }));
                            AnalysticsSignal.send('LOGIN-VERIFIED');
                            retValue = FutureBuilder<bool>(
                              future: Utility.checkOnboardingStatus(),
                              builder: (context,
                                  AsyncSnapshot<bool> onboardingSnapshot) {
                                if (onboardingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return splashScreen();
                                } else if (onboardingSnapshot.hasError) {
                                  notificationOverlayMessage!.showToast(
                                    context,
                                    "Error checking onboarding status.",
                                    NotificationOverlayMessageType.error,
                                  );
                                  return SignInRoute();
                                } else {
                                  return onboardingSnapshot.data!
                                      ? AuthorizedRoute()
                                      : OnboardingView();
                                }
                              },
                            );
                          }
                        } else {
                          // If there's no data and no error, continue showing the splash screen
                          retValue = splashScreen();
                        }
                        return retValue;
                      }
                    }),
              );
            }));
  }
}
