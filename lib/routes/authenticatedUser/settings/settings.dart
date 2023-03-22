import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

class Setting extends StatefulWidget {
  static final String routeName = '/Setting';
  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
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
    bool isTimeRestrictionConfigSet = restrictionProfile != null;
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

  @override
  Widget build(BuildContext context) {
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
    return CancelAndProceedTemplateWidget(
      onProceed: this.isProceedReady() ? proceedUpdate : null,
      child: Container(
          child: Column(
        children: [personalConfigButton, workConfigButton],
      )),
    );
  }
}
