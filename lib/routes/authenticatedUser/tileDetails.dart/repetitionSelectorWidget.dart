import 'package:flutter/material.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class RepetitionSelectorWidget extends StatefulWidget {
  final Repetition? repetition;
  final TextStyle? textStyle;
  final Function? onRepetitionUpdate;
  RepetitionSelectorWidget(
      {this.repetition, this.textStyle, this.onRepetitionUpdate});

  @override
  _RepetitionSelectorWidgetState createState() =>
      _RepetitionSelectorWidgetState();
}

class _RepetitionSelectorWidgetState extends State<RepetitionSelectorWidget> {
  Repetition? _repetition;
  @override
  void initState() {
    super.initState();
    this._repetition = this.widget.repetition;
  }

  Widget renderRepetitionDisabled() {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 20,
        ),
      ),
      onPressed: () {
        Repetition repetition = this._repetition ?? Repetition.fromJson({});
        onRepetitionTap(repetition, repetition.toRepetitionData());
      },
      child: Container(
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.nonRecurring,
              style: this.widget.textStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget renderEnabledRepetitionDisabled(Repetition repetition) {
    String recurringText = AppLocalizations.of(context)!.recurring;
    if (repetition.frequency == RepetitionFrequency.daily) {
      recurringText = AppLocalizations.of(context)!.dailyReurring;
    } else if (repetition.frequency == RepetitionFrequency.weekly) {
      recurringText = AppLocalizations.of(context)!.weeklyReurring;
    } else if (repetition.frequency == RepetitionFrequency.monthly) {
      recurringText = AppLocalizations.of(context)!.monthlyReurring;
    } else if (repetition.frequency == RepetitionFrequency.yearly) {
      recurringText = AppLocalizations.of(context)!.yearlyReurring;
    }
    RepetitionData? _repetitionData = repetition.toRepetitionData();
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 20,
        ),
      ),
      onPressed: () {
        onRepetitionTap(repetition, _repetitionData);
      },
      child: Container(
        child: Text(
          recurringText,
          style: this.widget.textStyle,
        ),
      ),
    );
  }

  void onRepetitionTap(Repetition repetition, RepetitionData? _repetitionData) {
    Timeline tileTimeline = repetition.tileTimeline ?? Utility.todayTimeline();
    RepetitionData? repetitionData = _repetitionData?.clone();

    Map<String, dynamic> repetitionParams = {
      'repetitionData': repetitionData,
      'tileTimeline': tileTimeline,
    };
    AnalysticsSignal.send('REPETITION_SELECTION_UPDATE');
    Navigator.pushNamed(context, '/RepetitionRoute',
            arguments: repetitionParams)
        .whenComplete(() {
      RepetitionData? updatedRepetitionData =
          repetitionParams['updatedRepetition'] as RepetitionData?;
      bool isRepetitionEndValid = true;
      if (repetitionParams.containsKey('isRepetitionEndValid')) {
        isRepetitionEndValid =
            repetitionParams['isRepetitionEndValid'] ?? false;
      }

      if (updatedRepetitionData != null) {
        setState(() {
          _repetitionData = isRepetitionEndValid ? updatedRepetitionData : null;
          if (_repetitionData != null &&
              this.widget.onRepetitionUpdate != null) {
            this.widget.onRepetitionUpdate!(
                Repetition.fromRepetitionData(_repetitionData!));
          }
        });
      }
      if (!isRepetitionEndValid) {
        setState(() {
          _repetitionData = null;
        });
      }
    });
  }

  // Widget redirect

  @override
  Widget build(BuildContext context) {
    if (_repetition == null || _repetition!.isEnabled != true) {
      return renderRepetitionDisabled();
    } else {
      return renderEnabledRepetitionDisabled(_repetition!);
    }
  }
}
