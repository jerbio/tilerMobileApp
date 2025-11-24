import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingSubWidget.dart';
import 'package:tiler_app/components/tileUI/tilerCheckBox.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TilerUsageWidget extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    final localizations=  AppLocalizations.of(context)!;
    final List<String> usageOptions = [
      localizations.personalScheduling,
      localizations.workPlanning,
      localizations.teamCoordination,
      localizations.fieldBaseCoordination,
      localizations.academicScheduling,
      localizations.clientManagement,
    ];
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return OnboardingSubWidget(
          title: localizations.personalOrWork,
          questionText: localizations.personalProfileQuestion,
          child: Column(
            children: usageOptions.map((usage) {
              bool isChecked = state.usage?.contains(usage) ?? false;
              return TilerCheckBox(
                isChecked: isChecked,
                text: usage,
                onChange: (checkboxState) {
                  context.read<OnboardingBloc>().add(SelectUsageEvent(usage));
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}