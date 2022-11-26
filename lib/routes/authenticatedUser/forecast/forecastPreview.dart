import 'package:flutter/material.dart';
import 'package:tiler_app/components/forecastTemplate/DatePickerWidget.dart';
import 'package:tiler_app/components/forecastTemplate/durationWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';

import '../../../styles.dart';

class ForecastPreview extends StatelessWidget {
  ForecastPreview({Key? key}) : super(key: key);

  TextEditingController date = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.forecast,
          style: TextStyle(
              color: TileStyles.enabledTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.close,
              color: TileStyles.enabledTextColor,
              size: 30,
            ),
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        children: [
          DatePickerField(
              hintText: AppLocalizations.of(context)!.whenQ,
              dateController: date),
          DurationWidget(),
        ],
      ),
    );
  }
}
