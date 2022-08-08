import 'package:flutter/material.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _PreloadedRestrictionsRoute extends StatefulWidget {
  Map? params;
  static final String routeName = '/TimeRestrictionRoute';
  @override
  _PreloadedRestrictionsRouteState createState() =>
      _PreloadedRestrictionsRouteState();
}

class _PreloadedRestrictionsRouteState
    extends State<_PreloadedRestrictionsRoute> {
  Map<String, bool> generate = {};
  final Key weekendCheckBoxKey = Key('weekendCheckBoxKey');
  final Key weekdayCheckBoxKey = Key('weekdayCheckBoxKey');

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

      setState(() {
        generate = generatedCopy;
      });
    };

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    Map restrictionProfileParams =
        ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.params = restrictionProfileParams;
    return Scaffold(
      body: Container(
        child: Stack(alignment: Alignment.center, children: [
          Column(
            children: [
              TilerCheckBox(
                isChecked: generate.containsKey('weekdays')
                    ? generate['weekdays']!
                    : false,
                text: 'Weekdays and work hours',
                onChange: generateFunction('weekdays'),
                key: weekdayCheckBoxKey,
              ),
              TilerCheckBox(
                isChecked: generate.containsKey('weekend')
                    ? generate['weekend']!
                    : false,
                text: 'Weekend',
                onChange: generateFunction('weekend'),
                key: weekendCheckBoxKey,
              )
            ],
          ),
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: () {
                List<String> stackRouteHistory = [];
                if (this.widget.params != null &&
                    this.widget.params!.containsKey('stackRouteHistory')) {
                  stackRouteHistory = this.widget.params!['stackRouteHistory'];
                }

                stackRouteHistory.add(_PreloadedRestrictionsRoute.routeName);

                Navigator.pushNamed(context, '/CustomRestrictionsRoute',
                    arguments: this.widget.params);
              },
              child: Container(
                width: 250,
                height: 60,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromAHSL(0.12, 198, 1, 0.33).toColor(),
                        HSLColor.fromAHSL(0.12, 198, 1, 0.33).toColor(),
                      ],
                    )),
                alignment: Alignment.center,
                child: Text(
                    AppLocalizations.of(context)!.setupCustomRestrictions,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 119, 255, 1),
                        fontWeight: FontWeight.w500,
                        fontSize: 18)),
              ),
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
  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      child: _PreloadedRestrictionsRoute(),
      onProceed: () {},
    );
  }
}
