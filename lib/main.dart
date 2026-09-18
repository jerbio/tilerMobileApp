import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
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
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/components/tutorial/tours/settingsTour.dart';
import 'package:tiler_app/components/tutorial/tours/tilePreferencesTour.dart';
import 'package:tiler_app/components/vibeChat/vibeChat.dart';
// import 'package:tiler_app/firebase_options.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDuration.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastPreview.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/procrastinateAll.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/account%20info/accountInfo.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/connetions.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/notificationsPreferences/notificationPreferences.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/feedback/feedbackPage.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/createTileShareClusterWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareRoute.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'package:tiler_app/services/schedulePrimer.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
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
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(
              create: (context) => CalendarTileBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(create: (context) => UiDateManagerBloc()),
          BlocProvider(
              create: (context) => ScheduleSummaryBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(
              create: (context) => LocationBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(create: (context) => TileListCarouselBloc()),
          BlocProvider(
              create: (context) => DeviceSettingBloc(
                    getContextCallBack: () {
                      return _navigatorKey.currentState?.overlay?.context ??
                          this.context;
                    },
                    initialIsDarkMode: isDarkMode,
                  )),
          //BlocProvider(create: (context) => OnboardingBloc(onBoardingApi!, SettingsApi(getContextCallBack: () => context))),
          BlocProvider(
              create: (context) => ForecastBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(
              create: (context) => ScheduleBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(create: (context) => WeeklyUiDateManagerBloc()),
          BlocProvider(create: (context) => MonthlyUiDateManagerBloc()),
          BlocProvider(
              create: (context) => PreviewSummaryBloc(getContextCallBack: () {
                    return _navigatorKey.currentState?.overlay?.context ??
                        this.context;
                  })),
          BlocProvider(
              create: (context) => VibeChatBloc(
                    getContextCallBack: () {
                      return _navigatorKey.currentState?.overlay?.context ??
                          this.context;
                    },
                    scheduleBloc: context.read<ScheduleBloc>(),
                    scheduleSummaryBloc: context.read<ScheduleSummaryBloc>(),
                  )),
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
                navigatorKey: _navigatorKey,
                routes: <String, WidgetBuilder>{
                  '/AuthorizedUser': (BuildContext context) =>
                      new AuthorizedRoute(),
                  '/LoggedOut': (BuildContext context) => new SignInRoute(),
                  // Add Tile: ONE entry for every push site (D65, D66).
                  '/AddTile': (BuildContext context) => const AddTileEntry(),
                  // Edit Tile redesign shell (Phase 1, Step 1.4). Its own
                  // route so it can be reviewed independently of the legacy
                  // EditTile screen, which every production entry point still
                  // pushes directly. Arguments: EditTileRedesignRouteArgs or a
                  // {tileId, source?, thirdPartyUserId?} map.
                  '/EditTileRedesign': (BuildContext context) {
                    final EditTileRedesignRouteArgs? args =
                        EditTileRedesignRouteArgs.from(
                            ModalRoute.of(context)?.settings.arguments);
                    return buildEditTileRedesign(context,
                        args ?? const EditTileRedesignRouteArgs(tileId: ''));
                  },
                  '/SearchTile': (BuildContext context) =>
                      new EventNameSearchWidget(context: context),
                  '/ForecastPreview': (ctx) => ForecastPreview(),
                  '/ForecastDuration': (ctx) => ForecastDuration(),
                  '/Procrastinate': (ctx) => ProcrastinateAll(),
                  '/Setting': buildSettingsRoute,
                  '/Integrations': (ctx) => IntegrationWidgetRoute(),
                  '/OnBoarding': (ctx) => OnboardingView(),
                  '/TileCluster': (ctx) => CreateTileShareClusterWidget(),
                  '/DesignatedTileList': (ctx) => DesignatedTileList(),
                  '/TileShare': (ctx) => TileShareRoute(),
                  '/accountInfo': (ctx) => AccountInfo(),
                  '/notificationsPreferences': (ctx) =>
                      NotificationPreferences(),
                  '/Connections': (ctx) => Connections(),
                  '/Feedback': (ctx) => FeedbackPage(),
                  '/tilePreferences': buildTilePreferencesRoute,
                  '/vibeChat': (ctx) => VibeChat()
                },
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
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
                            // Stage 3.5: start loading the schedule
                            // before the onboarding gate resolves, so
                            // it is in flight while the essentials
                            // pages show (parity with the sign-in path).
                            primeScheduleAfterLogin(context);
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

/// The `/Setting` route: the settings page hosted under the per-device
/// 1-step settings pointer (product-tour-onboarding-redesign.md, Phase 2
/// item 3 / stage 2.5). The pointer only points users at the Tile
/// Preferences row; the tour that teaches AI preferences is hosted by
/// [buildTilePreferencesRoute].
///
/// Top-level (rather than inlined in the `MaterialApp` routes map) so the
/// production wiring stays testable: `test/settings_tour_test.dart` mounts
/// `MaterialApp(routes: {'/Setting': buildSettingsRoute})` and asserts the
/// tour starts on the first visit, spotlighting the live settings rows.
/// Uses [TourHost]'s default settle delay so the settings list renders
/// before the spotlight appears.
Widget buildSettingsRoute(BuildContext context) {
  return TourHost(
    tourId: TourPreferencesHelper.settingsTourId,
    stepCount: kSettingsTourStepCount,
    stepsBuilder: buildSettingsTourSteps,
    child: Settings(),
  );
}

/// The `/tilePreferences` route: the Tile Preferences page hosted under the
/// per-device tile-preferences tour (product-tour-onboarding-redesign.md,
/// section 3.4 / stage 2.5).
///
/// Top-level for the same reason as [buildSettingsRoute]: the production
/// wiring stays testable (`test/tile_preferences_tour_test.dart`). Both
/// entry points — the Settings row and the tile-list return connector —
/// push this named route, so hosting the tour here covers both.
///
/// The page shows a pending widget until its preferences load, so the
/// tour's anchors mount asynchronously: the readiness gate is enabled and
/// the host polls for the first card before starting. If the fetch never
/// completes the tour is simply not started this visit (never marked
/// complete), so it retries next time.
Widget buildTilePreferencesRoute(BuildContext context) {
  return TourHost(
    tourId: TourPreferencesHelper.tilePreferencesTourId,
    stepCount: kTilePreferencesTourStepCount,
    stepsBuilder: buildTilePreferencesTourSteps,
    anchorReadyTimeout: const Duration(seconds: 20),
    child: TilePreferencesScreen(),
  );
}
