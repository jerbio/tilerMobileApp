import 'package:flutter/material.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RestrictionProfileSelectorWidget extends StatefulWidget {
  final RestrictionProfile? restrictionProfile;
  final RestrictionProfile? workProfile;
  final RestrictionProfile? personalProfile;
  final TextStyle? textStyle;
  final Function? onRestrictionProfileUpdate;
  RestrictionProfileSelectorWidget(
      {required this.restrictionProfile,
      this.workProfile,
      this.personalProfile,
      this.textStyle,
      this.onRestrictionProfileUpdate});

  @override
  _RestrictionProfileSelectorWidget createState() =>
      _RestrictionProfileSelectorWidget();
}

class _RestrictionProfileSelectorWidget
    extends State<RestrictionProfileSelectorWidget> {
  RestrictionProfile? _restrictionProfile;
  RestrictionProfile? _workRestrictionProfile;
  RestrictionProfile? _personalRestrictionProfile;
  @override
  void initState() {
    super.initState();
    this._restrictionProfile = this.widget.restrictionProfile;
    this._workRestrictionProfile = this.widget.workProfile;
    this._personalRestrictionProfile = this.widget.personalProfile;
  }

  Widget renderRestrictionProfileInfo() {
    String _restrictionProfileName = AppLocalizations.of(context)!.customHours;
    if (_workRestrictionProfile != null &&
        _workRestrictionProfile == _restrictionProfile) {
      _restrictionProfileName = AppLocalizations.of(context)!.workProfileHours;
    }

    if (_personalRestrictionProfile != null &&
        _personalRestrictionProfile == _restrictionProfile) {
      _restrictionProfileName = AppLocalizations.of(context)!.personalHours;
    }

    if (_restrictionProfile == null || _restrictionProfile?.isEnabled != true) {
      _restrictionProfileName = AppLocalizations.of(context)!.anytime;
    }

    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 20,
        ),
      ),
      onPressed: () {
        Map<String, dynamic> restrictionParams = {
          'routeRestrictionProfile': _restrictionProfile,
        };

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          if (restrictionParams.containsKey('routeRestrictionProfile')) {
            populatedRestrictionProfile =
                restrictionParams['routeRestrictionProfile']
                    as RestrictionProfile?;
            restrictionParams.remove('routeRestrictionProfile');
            setState(() {
              _restrictionProfile = populatedRestrictionProfile;
              if (_workRestrictionProfile != null &&
                  _workRestrictionProfile == _restrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.workProfileHours;
              }

              if (_personalRestrictionProfile != null &&
                  _personalRestrictionProfile == _restrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.personalHours;
              }
              if (this.widget.onRestrictionProfileUpdate != null) {
                this.widget.onRestrictionProfileUpdate!(_restrictionProfile);
              }
            });
          }
        });
      },
      child: Container(
          padding: EdgeInsets.all(10),
          width: MediaQuery.sizeOf(context).width *
              TileStyles.tileWidthRatio *
              TileStyles.tileWidthRatio *
              TileStyles.tileWidthRatio,
          child: Text(
            _restrictionProfileName,
            style: this.widget.textStyle,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return renderRestrictionProfileInfo();
  }
}
