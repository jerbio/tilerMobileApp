import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileTime.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class Setting extends StatefulWidget {
  static final String routeName = '/Setting';
  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  Authentication authentication = Authentication();
  SettingsApi settingsApi = SettingsApi();
  RestrictionProfile? workRestrictionProfile;
  RestrictionProfile? personalRestrictionProfile;
  StartOfDay? endOfDay;
  bool isTimeOfDayLoaded = false;
  bool isAllRestrictionProfileLoaded = false;

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

  Future proceedUpdate() {
    List<Future> futureExecutions = <Future>[];
    if (workRestrictionProfile != null) {
      Future workRestrictionProfileUpdateFuture =
          settingsApi.updateRestrictionProfile(workRestrictionProfile!,
              restrictionProfileType: 'work');
      futureExecutions.add(workRestrictionProfileUpdateFuture);
    }
    if (personalRestrictionProfile != null) {
      Future personalRestrictionProfileUpdateFuture =
          settingsApi.updateRestrictionProfile(personalRestrictionProfile!,
              restrictionProfileType: 'personal');
      futureExecutions.add(personalRestrictionProfileUpdateFuture);
    }

    if (this.endOfDay != null) {
      Future endOfDayUpdateFuture =
          settingsApi.updateStartOfDay(this.endOfDay!);

      futureExecutions.add(endOfDayUpdateFuture);
    }

    return Future.wait(futureExecutions).onError((error, stackTrace) {
      if (error is TilerError) {
        if (error.message != null) {
          showErrorMessage(error.message!);
        }
      }
      throw Error();
    });
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
    final Color iconColor = TileStyles.iconColor;
    final BoxDecoration boxDecoration = BoxDecoration(
        color: Color.fromRGBO(31, 31, 31, 0.05),
        borderRadius: BorderRadius.all(
          const Radius.circular(10.0),
        ));
    final BoxDecoration populatedDecoration = BoxDecoration(
        borderRadius: BorderRadius.all(
          const Radius.circular(10.0),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            HSLColor.fromColor(TileStyles.primaryColor)
                .withLightness(
                    HSLColor.fromColor(TileStyles.primaryColor).lightness)
                .toColor(),
            HSLColor.fromColor(TileStyles.primaryColor)
                .withLightness(
                    HSLColor.fromColor(TileStyles.primaryColor).lightness + 0.3)
                .toColor(),
          ],
        ));
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
  }

  Widget createEndOfDay() {
    TimeOfDay napTimeOfDay =
        this.endOfDay?.timeOfDay ?? Utility.defaultEndOfDay;
    final formattedTimeOfDay =
        MaterialLocalizations.of(context).formatTimeOfDay(napTimeOfDay);
    Widget retValue = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.snoozeTime),
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
            },
          ),
        )
      ],
    );
    return retValue;
  }

  Widget createLogOutButton() {
    Widget retValue = ElevatedButton(
        onPressed: () {
          authentication.deauthenticateCredentials();
          Navigator.pushNamedAndRemoveUntil(
              context, '/LoggedOut', (route) => false);
        },
        child: Text(AppLocalizations.of(context)!.logout));
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
    if (isTimeOfDayLoaded) {
      Widget endOfDayWidget =
          Container(alignment: Alignment.center, child: createEndOfDay());
      childElements.add(endOfDayWidget);
    }
    if (!this.isAllRestrictionProfileLoaded || !isTimeOfDayLoaded) {
      childElements.add(PendingWidget());
    }

    childElements.add(logoutButton);
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
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
