import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Setting extends StatefulWidget {
  static final String routeName = '/Setting';
  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late SettingsApi settingsApi;
  RestrictionProfile? workRestrictionProfile;
  RestrictionProfile? personalRestrictionProfile;
  String? localTimeZone;
  bool isAllRestrictionProfileLoaded = false;

  static final String settingCancelAndProceedRouteName =
      "settingCancelAndProceedRouteName";


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

  }

  bool isProceedReady() {
    return  isAllRestrictionProfileLoaded;
  }

  Widget renderRestrictionProfile({
    required String configButtonName,
    required RestrictionProfile? restrictionProfile,
    required Function(RestrictionProfile?) callBack
  }) {
    return TextButton(
      onPressed: () {
        AnalysticsSignal.send('SETTINGS_OPEN_RESTRICTION_PROFILE_$configButtonName');
        Map<String, dynamic> restrictionParams = {
          'routeRestrictionProfile': restrictionProfile,
          'stackRouteHistory': [Setting.routeName]
        };

        Navigator.pushNamed(context, '/TimeRestrictionRoute', arguments: restrictionParams)
            .whenComplete(() {
          if (restrictionParams.containsKey('routeRestrictionProfile')) {
            RestrictionProfile? updatedProfile = restrictionParams['routeRestrictionProfile'] as RestrictionProfile?;

            if (updatedProfile != null && restrictionProfile != null) {
              updatedProfile.id = restrictionProfile.id;
            }

            if (restrictionProfile != null &&
                (updatedProfile == null || (restrictionParams.containsKey('isAnyTime') && restrictionParams['isAnyTime'] != null))) {
              restrictionProfile.isEnabled = !restrictionParams['isAnyTime'];
              updatedProfile = restrictionProfile;
            }

            callBack(updatedProfile);
          }
        });
      },
      child: Text(
        configButtonName,
        style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.w300),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    this.settingsApi = SettingsApi(getContextCallBack: () => context);
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

    FlutterTimezone.getLocalTimezone().then((value) {
      setState(() {
        localTimeZone = value;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    List<Widget> childElements = [];

    if (this.isAllRestrictionProfileLoaded) {
      Widget personalConfigButton = renderRestrictionProfile(
          restrictionProfile: personalRestrictionProfile,
          configButtonName: AppLocalizations.of(context)!.setPersonalHours,
          callBack: (updatedRestrictionProfile) {
            setState(() {
              this.personalRestrictionProfile = updatedRestrictionProfile;
            });
          });

      Widget workConfigButton = renderRestrictionProfile(
          restrictionProfile: workRestrictionProfile,
          configButtonName: AppLocalizations.of(context)!.setWorkProfileHours,
          callBack: (updatedRestrictionProfile) {
            setState(() {
              this.workRestrictionProfile = updatedRestrictionProfile;
            });
          });
      childElements.add(SizedBox(height: 30,));
      childElements.add(workConfigButton);
      childElements.add(SizedBox(height: 20,));
      childElements.add(personalConfigButton);
    }
    if (!this.isAllRestrictionProfileLoaded) {
      childElements.add(PendingWidget(
        backgroundDecoration: BoxDecoration(color: Colors.transparent),
      ));
    }
    return CancelAndProceedTemplateWidget(
      routeName: settingCancelAndProceedRouteName,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Tile Preferences"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      onProceed: this.isProceedReady() ? proceedUpdate : null,
      child:  SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: childElements,
          ),
        ),
      ),
    );
  }
}