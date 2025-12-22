import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'onBoardingSubWidget.dart';

class WorkDayStartWidget extends StatefulWidget {
  @override
  _WorkDayStartWidgetState createState() => _WorkDayStartWidgetState();
}

class _WorkDayStartWidgetState extends State<WorkDayStartWidget> {
  String? selectedTime;
  final TimeOfDay defaultTime = TimeOfDay(hour: 9, minute: 0);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: context.read<OnboardingBloc>().state.startingWorkDayTime ??
          defaultTime,
    );

    if (picked != null) {
      context.read<OnboardingBloc>().add(StartingWorkdayTimeUpdated(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;
    return OnboardingSubWidget(
      questionText: AppLocalizations.of(context)!.workdayStartQuestion,
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final startingWorkDayTime =
              state.startingWorkDayTime?.format(context) ??
                  defaultTime.format(context);
          return GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              width: double.infinity,
              height: 50,
              decoration: TileDecorations.onboardingBoxDecoration(
                  tileThemeExtension.onSurfaceVariantSecondary),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  startingWorkDayTime,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
