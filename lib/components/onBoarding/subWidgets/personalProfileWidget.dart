import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';

import 'onBoardingSubWidget.dart';

class PersonalProfileWidget extends StatelessWidget {
  final GlobalKey<CustomTimeRestrictionRouteState> restrictionKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
      if (state.step == OnboardingStep.setPersonalProfile) {
        Map? profile = restrictionKey.currentState?.getData();
        if (profile != null)
          context.read<OnboardingBloc>().add(SetPersonalProfileEvent(profile!));
      }
    }, builder: (context, state) {
      Map<String, dynamic> restrictionParams = {
        'restrictionProfile': state.personalProfile,
        'stackRouteHistory': ['/onBoardingPersonalProfile']
      };

      return OnboardingSubWidget(
          title: localizations.personalHours,
          questionText: localizations.personalProfileQuestion,
          child: CustomTimeRestrictionRoute(
              key: restrictionKey,
              isOnBoarding: true,
              params: restrictionParams));
    });
  }
}
