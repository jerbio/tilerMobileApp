import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/integrations/integrations_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';

import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileTime.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class Setting extends StatefulWidget {
  static final String routeName = '/Setting';
  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  Authentication authentication = Authentication();
  AuthorizationApi _authorizationApi = AuthorizationApi();
  SecureStorageManager secureStorageManager = SecureStorageManager();
  SettingsApi settingsApi = SettingsApi();
  RestrictionProfile? workRestrictionProfile;
  RestrictionProfile? personalRestrictionProfile;
  StartOfDay? endOfDay;
  String? localTimeZone;
  bool isTimeOfDayLoaded = false;
  bool isAllRestrictionProfileLoaded = false;

  static final String settingCancelAndProceedRouteName =
      "settingCancelAndProceedRouteName";

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

  Future proceedUpdate() async {
    if (workRestrictionProfile != null) {
      Future workRestrictionProfileUpdateFuture =
          settingsApi.updateRestrictionProfile(workRestrictionProfile!,
              restrictionProfileType: 'work');
      await workRestrictionProfileUpdateFuture;
    }
    if (personalRestrictionProfile != null) {
      Future personalRestrictionProfileUpdateFuture =
          settingsApi.updateRestrictionProfile(personalRestrictionProfile!,
              restrictionProfileType: 'personal');
      await personalRestrictionProfileUpdateFuture;
    }

    if (this.endOfDay != null) {
      if (localTimeZone != null) {
        this.endOfDay!.timeZone = localTimeZone!;
      }
      Future endOfDayUpdateFuture =
          settingsApi.updateStartOfDay(this.endOfDay!);
      await endOfDayUpdateFuture;
    }
  }

  bool isProceedReady() {
    return isTimeOfDayLoaded && isAllRestrictionProfileLoaded;
  }

  Widget renderRestrictionProfile(
      {String? configButtonName,
      RestrictionProfile? restrictionProfile,
      Function? callBack}) {
    bool isTimeRestrictionConfigSet =
        restrictionProfile != null && restrictionProfile.isEnabled;
    final Color populatedTextColor = Colors.white;
    final Color iconColor = TileStyles.primaryColorDarkHSL.toColor();
    final BoxDecoration boxDecoration = TileStyles.configUpdate_notSelected;
    final BoxDecoration populatedDecoration = TileStyles.configUpdate_Selected;
    Widget timeRestrictionsConfigButton = ConfigUpdateButton(
      text: configButtonName ?? AppLocalizations.of(context)!.restriction,
      prefixIcon: Icon(
        Icons.switch_left,
        color: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      ),
      decoration:
          isTimeRestrictionConfigSet ? populatedDecoration : boxDecoration,
      textColor: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        AnalysticsSignal.send('SETTINGS_OPEN_RESTRICTION_PROFILE_' +
            (configButtonName ?? "NONE"));
        Map<String, dynamic> restrictionParams = {
          'routeRestrictionProfile': restrictionProfile,
          'stackRouteHistory': [Setting.routeName]
        };

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          if (restrictionParams.containsKey('routeRestrictionProfile')) {
            populatedRestrictionProfile =
                restrictionParams['routeRestrictionProfile']
                    as RestrictionProfile?;
            if (populatedRestrictionProfile != null &&
                restrictionProfile != null) {
              populatedRestrictionProfile.id = restrictionProfile.id;
            }

            if (restrictionProfile != null &&
                (populatedRestrictionProfile == null ||
                    (restrictionParams.containsKey('isAnyTime') &&
                        restrictionParams['isAnyTime'] != null))) {
              restrictionProfile.isEnabled = !restrictionParams['isAnyTime'];
              populatedRestrictionProfile = restrictionProfile;
            }

            if (callBack != null) {
              callBack(populatedRestrictionProfile);
            }
          }
        });
      },
    );
    return timeRestrictionsConfigButton;
  }

  @override
  void initState() {
    super.initState();
    settingsApi.getUserRestrictionProfile().then((value) {
      setState(() {
        isAllRestrictionProfileLoaded = true;
        if (value.containsKey('work')) {
          workRestrictionProfile = value['work'];
        }

        if (value.containsKey('personal')) {
          personalRestrictionProfile = value['personal'];
        }
      });
    }).whenComplete(() {
      setState(() {
        this.isAllRestrictionProfileLoaded = true;
      });
    });
    settingsApi.getUserStartOfDay().then((value) {
      setState(() {
        isTimeOfDayLoaded = true;
        if (value != null) {
          this.endOfDay = value;
        }
      });
    }).whenComplete(() {
      setState(() {
        isTimeOfDayLoaded = true;
      });
    });
    FlutterTimezone.getLocalTimezone().then((value) {
      setState(() {
        localTimeZone = value;
      });
    });
  }

  Widget createEndOfDay() {
    TimeOfDay napTimeOfDay =
        this.endOfDay?.timeOfDay ?? Utility.defaultEndOfDay;
    Widget retValue = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.bedTime),
        Container(
          width: 120,
          height: 50,
          alignment: Alignment.center,
          child: EditTileTime(
            time: napTimeOfDay,
            onInputChange: (updatedTimeOfDay) {
              if (this.endOfDay != null) {
                setState(() {
                  this.endOfDay!.timeOfDay = updatedTimeOfDay;
                });
              }
              AnalysticsSignal.send('SETTINGS_BEDTIME_UPDATE');
            },
          ),
        )
      ],
    );
    return retValue;
  }

  logOutUser() async {
    AnalysticsSignal.send('SETTINGS_LOG_OUT_USER');
    OneSignal.logout().then((value) {
      print("successful logged out of onesignal");
    }).catchError((onError) {
      print("Failed to logout of onesignal");
      print(onError);
    });
    await authentication.deauthenticateCredentials();
    await secureStorageManager.deleteAllStorageData();
    Navigator.pushNamedAndRemoveUntil(context, '/LoggedOut', (route) => false);
    this.context.read<ScheduleBloc>().add(LogOutScheduleEvent());
    this
        .context
        .read<SubCalendarTileBloc>()
        .add(LogOutSubCalendarTileBlocEvent());
    this.context.read<UiDateManagerBloc>().add(LogOutUiDateManagerEvent());
    this
        .context
        .read<WeeklyUiDateManagerBloc>()
        .add(LogOutWeeklyUiDateManagerEvent());
    this
        .context
        .read<MonthlyUiDateManagerBloc>()
        .add(LogOutMonthlyUiDateManagerEvent());
    this.context.read<CalendarTileBloc>().add(LogOutCalendarTileEvent());
    this
        .context
        .read<TileListCarouselBloc>()
        .add(EnableCarouselScrollEvent(isImmediate: true));

    this.context.read<IntegrationsBloc>().add(ResetIntegrationsEvent());
    this
        .context
        .read<ScheduleSummaryBloc>()
        .add(LogOutScheduleDaySummaryEvent());
  }

  Widget createLogOutButton() {
    Widget retValue = ElevatedButton(
        onPressed: logOutUser,
        child: Text(AppLocalizations.of(context)!.logout));
    return retValue;
  }

  Widget createIntegrationButton() {
    Widget retValue = ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/Integrations');
        },
        child: Text(AppLocalizations.of(context)!.integrateOtherCalendars));
    return retValue;
  }

  sendDeleteRequest() async {
    AnalysticsSignal.send('SETTINGS_DELETE_REQUEST_SENT');
    _authorizationApi.deleteTilerAccount().then((result) {
      if (result) {
        logOutUser();
      }
    });
  }

  Widget createDeleteAccountButton() {
    Widget retValue = ElevatedButton(
        onPressed: () {
          AnalysticsSignal.send('SETTINGS_DELETE_USER_INITIATED');
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
                          TileStyles.primaryColorHSL
                              .toColor()
                              .withOpacity(0.75),
                          TileStyles.primaryColorHSL
                              .withLightness(
                                  TileStyles.primaryColorHSL.lightness + .2)
                              .toColor()
                              .withOpacity(0.75),
                        ],
                      ),
                    ),
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .deleteYourTilerAccountQ,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            ElevatedButton(
                              onPressed: sendDeleteRequest,
                              child: Text(
                                AppLocalizations.of(context)!.yes,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(AppLocalizations.of(context)!.no),
                            )
                          ],
                        )),
                  )),
              context: this.context);
        },
        child: Text(AppLocalizations.of(context)!.deleteAccount));
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childElements = [];

    if (this.isAllRestrictionProfileLoaded) {
      Widget personalConfigButton = renderRestrictionProfile(
          restrictionProfile: personalRestrictionProfile,
          configButtonName: AppLocalizations.of(context)!.personalHours,
          callBack: (updatedRestrictionProfile) {
            setState(() {
              this.personalRestrictionProfile = updatedRestrictionProfile;
            });
          });

      Widget workConfigButton = renderRestrictionProfile(
          restrictionProfile: workRestrictionProfile,
          configButtonName: AppLocalizations.of(context)!.workProfileHours,
          callBack: (updatedRestrictionProfile) {
            setState(() {
              this.workRestrictionProfile = updatedRestrictionProfile;
            });
          });
      childElements.add(personalConfigButton);
      childElements.add(workConfigButton);
    }
    Widget logoutButton = createLogOutButton();
    Widget deleteButton = createDeleteAccountButton();
    Widget integrationButton = createIntegrationButton();
    if (isTimeOfDayLoaded) {
      Widget endOfDayWidget =
          Container(alignment: Alignment.center, child: createEndOfDay());
      childElements.add(endOfDayWidget);
    }
    if (!this.isAllRestrictionProfileLoaded || !isTimeOfDayLoaded) {
      childElements.add(PendingWidget(
        backgroundDecoration: BoxDecoration(color: Colors.transparent),
      ));
    }
    childElements.add(integrationButton);
    childElements.add(logoutButton);
    childElements.add(deleteButton);
    return CancelAndProceedTemplateWidget(
      routeName: settingCancelAndProceedRouteName,
      appBar: AppBar(
        backgroundColor: TileStyles.appBarColor,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      onProceed: this.isProceedReady() ? proceedUpdate : null,
      child: Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: childElements,
      )),
    );
  }
}
