import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_event.dart';
import '../../../bloc/onBoarding/on_boarding_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../styles.dart';
import 'onBoardingSubWidget.dart';

class EnergyLevelDescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OnboardingSubWidget(
      questionText:
          AppLocalizations.of(context)!.energyLevelDescriptionQuestion,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: Colors.grey),
        ),
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.preferredDaySection,
                isExpanded: true,
                iconEnabledColor: TileStyles.primaryColor,
                items: [
                  DropdownMenuItem(
                    child: Text(AppLocalizations.of(context)!.morningPerson),
                    value: AppLocalizations.of(context)!.morning,
                  ),
                  DropdownMenuItem(
                    child: Text(AppLocalizations.of(context)!.middayPerson),
                    value: AppLocalizations.of(context)!.midday,
                  ),
                  DropdownMenuItem(
                    child: Text(AppLocalizations.of(context)!.nightPerson),
                    value: AppLocalizations.of(context)!.neutral,
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
