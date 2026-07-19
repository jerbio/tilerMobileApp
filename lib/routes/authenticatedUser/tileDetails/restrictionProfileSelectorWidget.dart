import 'package:flutter/material.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tuple/tuple.dart';

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
  @override
  void initState() {
    super.initState();
  }

  RestrictionProfile? get _restrictionProfile {
    return this.widget.restrictionProfile;
  }

  RestrictionProfile? get _workRestrictionProfile {
    return this.widget.workProfile;
  }

  RestrictionProfile? get _personalRestrictionProfile {
    return this.widget.personalProfile;
  }

  Widget renderRestrictionProfileInfo() {
    String _restrictionProfileName = AppLocalizations.of(context)!.customHours;
    if ((_workRestrictionProfile != null &&
            _workRestrictionProfile == _restrictionProfile) ||
        (_workRestrictionProfile != null &&
            _restrictionProfile != null &&
            _restrictionProfile?.id != null &&
            _restrictionProfile?.id == _workRestrictionProfile?.id)) {
      _restrictionProfileName = AppLocalizations.of(context)!.workProfileHours;
    }

    if ((_personalRestrictionProfile != null &&
            _personalRestrictionProfile == _restrictionProfile) ||
        (_personalRestrictionProfile != null &&
            _restrictionProfile != null &&
            _restrictionProfile?.id != null &&
            _restrictionProfile?.id == _personalRestrictionProfile?.id)) {
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
        List<Tuple2<String, RestrictionProfile>>? _listedRestrictionProfile =
            [];
        if (_workRestrictionProfile != null) {
          _listedRestrictionProfile.add(new Tuple2(
              AppLocalizations.of(context)!.workProfileHours,
              _workRestrictionProfile!));
        }
        if (_personalRestrictionProfile != null) {
          _listedRestrictionProfile.add(new Tuple2(
              AppLocalizations.of(context)!.personalHours,
              _personalRestrictionProfile!));
        }
        Map<String, dynamic> restrictionParams = {
          'routeRestrictionProfile': _restrictionProfile,
          'namedRestrictionProfiles': _listedRestrictionProfile
        };

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          if (restrictionParams.containsKey('routeRestrictionProfile') ||
              restrictionParams["isAnyTime"] == true) {
            populatedRestrictionProfile =
                restrictionParams['routeRestrictionProfile']
                    as RestrictionProfile?;
            if (restrictionParams["isAnyTime"] == true) {
              populatedRestrictionProfile = this._restrictionProfile?.clone();
              if (populatedRestrictionProfile != null) {
                populatedRestrictionProfile.isEnabled = false;
              }
            }
            restrictionParams.remove('routeRestrictionProfile');
            setState(() {
              if (_workRestrictionProfile != null &&
                  _workRestrictionProfile == populatedRestrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.workProfileHours;
              }

              if (_personalRestrictionProfile != null &&
                  _personalRestrictionProfile == populatedRestrictionProfile) {
                _restrictionProfileName =
                    AppLocalizations.of(context)!.personalHours;
              }
              if (this.widget.onRestrictionProfileUpdate != null) {
                this
                    .widget
                    .onRestrictionProfileUpdate!(populatedRestrictionProfile);
              }
            });
          }
        });
      },
      child: Container(
          padding: EdgeInsets.all(10),
          width: MediaQuery.sizeOf(context).width *
              TileDimensions.tileWidthRatio *
              TileDimensions.tileWidthRatio *
              TileDimensions.tileWidthRatio,
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
