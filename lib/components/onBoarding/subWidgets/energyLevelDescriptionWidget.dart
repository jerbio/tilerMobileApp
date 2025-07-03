import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'onBoardingSubWidget.dart';

class EnergyLevelDescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final appLocalizations=  AppLocalizations.of(context)!;
    return OnboardingSubWidget(
      questionText:
      appLocalizations.energyLevelDescriptionQuestion,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: colorScheme.onSurfaceVariant),
        ),
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.preferredDaySection,
                isExpanded: true,
                iconEnabledColor: colorScheme.primary,
                items: [
                  DropdownMenuItem(
                    child: Text(appLocalizations.morningPerson),
                    value:"Morning",
                  ),
                  DropdownMenuItem(
                    child: Text(appLocalizations.middayPerson),
                    value:  "Midday",
                  ),
                  DropdownMenuItem(
                    child: Text(appLocalizations.nightPerson),
                    value:"Neutral",
                  ),
                ],
                onChanged: (value) {
                  context
                      .read<OnboardingBloc>()
                      .add(PreferredDaySectionUpdated(value));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
