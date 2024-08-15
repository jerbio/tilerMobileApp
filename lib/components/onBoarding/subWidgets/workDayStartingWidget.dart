import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../bloc/onBoarding/on_boarding_bloc.dart';
import '../../../../../bloc/onBoarding/on_boarding_event.dart';
import '../../../../../bloc/onBoarding/on_boarding_state.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      initialTime: context.read<OnboardingBloc>().state.startingWorkDayTime??defaultTime,
    );

    if (picked != null) {
      context.read<OnboardingBloc>().add(StartingWorkdayTimeUpdated(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSubWidget(
      questionText: AppLocalizations.of(context)!.workdayStartQuestion,
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final startingWorkDayTime =state.startingWorkDayTime?.format(context) ?? defaultTime.format(context);
          return GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey),
              ),
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
