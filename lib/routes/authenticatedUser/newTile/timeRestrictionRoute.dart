import 'package:flutter/material.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../../styles.dart';

class _PreloadedRestrictionsRoute extends StatefulWidget {
  Map? params;
  bool _isAnyTime = true;
  RestrictionProfile? _restrictionProfile;
  static final String routeName = '/TimeRestrictionRoute';
  @override
  _PreloadedRestrictionsRouteState createState() =>
      _PreloadedRestrictionsRouteState();
  bool get isAnyTime {
    return _isAnyTime;
  }

  RestrictionProfile? get restrictionProfile {
    return _restrictionProfile;
  }
}

class _PreloadedRestrictionsRouteState
    extends State<_PreloadedRestrictionsRoute> {
  bool _isParamLoaded = false;
  bool _isAnyTime = true;
  RestrictionProfile? _restrictionProfile;
  List<Tuple2<String, RestrictionProfile>>? _namedRestrictionProfiles;
  Map<String, bool> generate = {};
  final Key weekendCheckBoxKey = Key('weekendCheckBoxKey');
  final Key weekdayCheckBoxKey = Key('weekdayCheckBoxKey');
  final Key anyTimeCheckBoxKey = Key('anyTimeCheckBoxKey');

  Function generateFunction(String checkBoxName) {
    if (!generate.containsKey(checkBoxName)) {
      generate[checkBoxName] = false;
    }

    var retValue = (checkBoxState) {
      var generatedCopy = generate;
      if (checkBoxState.isChecked) {
        generatedCopy.keys.forEach((name) {
          generatedCopy[name] = false;
        });
        generatedCopy[checkBoxName] = true;
      } else {
        generatedCopy[checkBoxName] = false;
      }
      bool isAnytime = false;
      if (checkBoxName == 'anytime') {
        isAnytime = true;
      }

      setState(() {
        generate = generatedCopy;
        _isAnyTime = isAnytime;
        if (isAnytime) {
          _restrictionProfile = null;
        }
      });
    };

    return retValue;
  }

  setRestrictionProfile(RestrictionProfile? restrictionProfile) {
    this.widget._restrictionProfile = restrictionProfile;
    setState(() {
      _restrictionProfile = restrictionProfile;
    });
  }

  handleParamLoading() {
    Map? restrictionProfileParams =
        ModalRoute.of(context)?.settings.arguments as Map?;
    this.widget.params = restrictionProfileParams ?? {};
    RestrictionProfile? paramRestrictionProfile;
    List<Tuple2<String, RestrictionProfile>>? namedRestricitonProfile;
    if (this.widget.params!.containsKey('routeRestrictionProfile') &&
        !_isParamLoaded) {
      paramRestrictionProfile =
          this.widget.params!['routeRestrictionProfile'] as RestrictionProfile?;
      _restrictionProfile = paramRestrictionProfile;
      if (_restrictionProfile != null) {
        _isAnyTime = !_restrictionProfile!.isAnyDayNotNull;
      }
    }
    if (this.widget.params!.containsKey('namedRestrictionProfiles') &&
        !_isParamLoaded) {
      namedRestricitonProfile = this.widget.params!['namedRestrictionProfiles']
          as List<Tuple2<String, RestrictionProfile>>?;
      this._namedRestrictionProfiles = namedRestricitonProfile;
    }
    if (!_isParamLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restrictionProfile = paramRestrictionProfile;
        this.widget._restrictionProfile = paramRestrictionProfile;
        this._namedRestrictionProfiles = namedRestricitonProfile;
        _isParamLoaded = true;
      });
    }
  }

  bool isAnyTime() {
    this.widget._isAnyTime = (_restrictionProfile == null ||
            _isAnyTime ||
            !_restrictionProfile!.isEnabled)
        ? true
        : (generate.containsKey('anytime') ? generate['anytime']! : false);
    return this.widget._isAnyTime;
  }

  @override
  Widget build(BuildContext context) {
    handleParamLoading();
    List<Widget> checkListElements = [
      Container(
          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: TilerCheckBox(
            isChecked: isAnyTime(),
            text: AppLocalizations.of(context)!.anytime,
            onChange: generateFunction('anytime'),
            key: anyTimeCheckBoxKey,
          ))
    ];
    if (_namedRestrictionProfiles != null) {
      for (var namedRestrictionProfile in _namedRestrictionProfiles!) {
        checkListElements.add(Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: TilerCheckBox(
              isChecked: _restrictionProfile != null &&
                  _restrictionProfile == namedRestrictionProfile.item2,
              text: namedRestrictionProfile.item1.capitalize(),
              onChange: (checkBoxState) {
                generateFunction(namedRestrictionProfile.item1)(checkBoxState);
                if (_restrictionProfile == null ||
                    (_restrictionProfile != null &&
                        _restrictionProfile != namedRestrictionProfile.item2)) {
                  setRestrictionProfile(namedRestrictionProfile.item2);
                  generate[namedRestrictionProfile.item1] = true;
                  setState(() {
                    _isAnyTime = false;
                  });
                } else {
                  setRestrictionProfile(null);
                  generate[namedRestrictionProfile.item1] = false;
                }
              },
              key: ValueKey(namedRestrictionProfile.item1),
            )));
      }
    }
    var buttonStyle = _isAnyTime
        ? TileStyles.enabledButtonStyle
        : TileStyles.selectedButtonStyle;

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Stack(alignment: Alignment.center, children: [
          FractionallySizedBox(
              alignment: FractionalOffset.topCenter,
              widthFactor: TileStyles.inputWidthFactor,
              child: Container(
                  alignment: Alignment.topCenter,
                  margin: EdgeInsets.fromLTRB(0, 40, 0, 0),
                  child: Column(
                    children: checkListElements,
                  ))),
          Positioned(
            bottom: 20,
            child: ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                List<String> stackRouteHistory = [];
                if (this.widget.params != null &&
                    this.widget.params!.containsKey('stackRouteHistory')) {
                  stackRouteHistory = this.widget.params!['stackRouteHistory'];
                }

                this.widget.params!['restrictionProfile'] = _restrictionProfile;
                stackRouteHistory.add(_PreloadedRestrictionsRoute.routeName);

                Navigator.pushNamed(context, '/CustomRestrictionsRoute',
                        arguments: this.widget.params)
                    .then((resultMap) async {
                  RestrictionProfile? restrictionProfile;
                  bool isAnytime = true;
                  resultMap = resultMap ?? this.widget.params;
                  if (resultMap != null && resultMap is Map) {
                    if (resultMap.containsKey('restrictionProfile')) {
                      restrictionProfile = resultMap['restrictionProfile'];
                      if (restrictionProfile != null) {
                        isAnytime = !restrictionProfile.daySelection
                            .any((restrictedDay) => restrictedDay != null);
                      }
                    }
                  }
                  Map<String, bool> generateCpy = generate;
                  generateCpy['anytime'] = isAnytime;
                  setState(() {
                    setRestrictionProfile(restrictionProfile);
                    _isAnyTime = isAnytime;
                    generate = generateCpy;
                  });
                  return resultMap;
                });
              },
              child: Text(
                  "\n" +
                      AppLocalizations.of(context)!.customRestrictionTitle +
                      "\n",
                  // maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _isAnyTime
                          ? TileStyles.primaryColorDarkHSL.toColor()
                          : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 18)),
              // child: Container(
              //   width: (MediaQuery.of(context).size.width *
              //           TileStyles.inputWidthFactor) -
              //       TileStyles.proceedAndCancelTotalButtonWidth,
              //   height: 60,
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.all(
              //         const Radius.circular(10.0),
              //       ),
              //       gradient: LinearGradient(
              //         begin: Alignment.centerLeft,
              //         end: Alignment.bottomRight,
              //         colors: [
              //           TileStyles.primaryColorLightHSL.toColor(),
              //           TileStyles.primaryColorLightHSL.toColor(),
              //         ],
              //       )),
              //   alignment: Alignment.center,
              //   child: Text(
              //       AppLocalizations.of(context)!.customRestrictionTitle,
              //       maxLines: 2,
              //       overflow: TextOverflow.ellipsis,
              //       textAlign: TextAlign.center,
              //       style: TextStyle(
              //           color: TileStyles.primaryColorDarkHSL.toColor(),
              //           fontWeight: FontWeight.w500,
              //           fontSize: 18)),
              // ),
            ),
          )
        ]),
      ),
    );
  }
}

class TimeRestrictionRoute extends StatefulWidget {
  @override
  TimeRestrictionRouteState createState() => TimeRestrictionRouteState();
}

class TimeRestrictionRouteState extends State<TimeRestrictionRoute> {
  late _PreloadedRestrictionsRoute stateWidget;
  static final String timeRestrictionCancelAndProceedRouteName =
      "timeRestrictionCancelAndProceedRouteName";
  @override
  Widget build(BuildContext context) {
    stateWidget = _PreloadedRestrictionsRoute();
    return CancelAndProceedTemplateWidget(
      routeName: timeRestrictionCancelAndProceedRouteName,
      child: stateWidget,
      onProceed: () {
        Map? restrictionProfileParams =
            ModalRoute.of(context)?.settings.arguments as Map?;
        if (stateWidget.isAnyTime) {
          if (restrictionProfileParams != null) {
            restrictionProfileParams['routeRestrictionProfile'] = null;
            restrictionProfileParams['isAnyTime'] = true;
          }
          return;
        }

        if (restrictionProfileParams != null) {
          restrictionProfileParams['routeRestrictionProfile'] =
              stateWidget.restrictionProfile;
        }
      },
    );
  }
}
