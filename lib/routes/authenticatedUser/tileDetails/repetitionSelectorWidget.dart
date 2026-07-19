import 'package:flutter/material.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
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
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    this._repetition = this.widget.repetition;
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    super.didChangeDependencies();
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

      // If the user cancelled (no selection returned) leave the current
      // repetition untouched. Previously a repetition whose deadline failed the
      // route's deadline validation was silently discarded and the selector was
      // forced into a non-recurring state. That desynced the selector from the
      // underlying tile (which still held the old repetition) and hid the save
      // button, making the tile impossible to save after changing the
      // frequency. RepetitionData already guarantees a sane default deadline,
      // so we apply exactly what the user chose and always notify the parent.
      if (updatedRepetitionData == null) {
        return;
      }

      setState(() {
        Repetition updatedRepetition =
            Repetition.fromRepetitionData(updatedRepetitionData);
        updatedRepetition.tileTimeline = this.widget.repetition?.tileTimeline;
        _repetition = updatedRepetition;
        if (this.widget.onRepetitionUpdate != null) {
          this.widget.onRepetitionUpdate!(updatedRepetition);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_repetition == null || _repetition!.isEnabled != true) {
      return renderRepetitionDisabled();
    } else {
      return renderEnabledRepetitionDisabled(_repetition!);
    }
  }
}
