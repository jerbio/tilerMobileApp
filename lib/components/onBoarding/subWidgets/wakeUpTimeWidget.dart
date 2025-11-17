import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'onBoardingSubWidget.dart';

class WakeUpTimeWidget extends StatefulWidget {
  @override
  _WakeUpTimeWidgetState createState() => _WakeUpTimeWidgetState();
}

class _WakeUpTimeWidgetState extends State<WakeUpTimeWidget> {
  String? selectedTime;
  final TimeOfDay defaultTime = TimeOfDay(hour: 7, minute: 0);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          context.read<OnboardingBloc>().state.wakeUpTime ?? defaultTime,
    );

    if (picked != null) {
      context.read<OnboardingBloc>().add(WakeUpTimeUpdated(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    return OnboardingSubWidget(
      questionText: AppLocalizations.of(context)!.wakeUpTimeQuestion,
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final wakeUpTime =
              state.wakeUpTime?.format(context) ?? defaultTime.format(context);

          return GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: tileThemeExtension.onSurfaceVariantSecondary),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  wakeUpTime,
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
