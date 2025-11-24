import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingSubWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkProfileWidget extends StatelessWidget {
  static const String routeName = '/onBoardingWorkProfile';
  const WorkProfileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final GlobalKey<CustomTimeRestrictionRouteState> restrictionKey = GlobalKey();
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.step == OnboardingStep.setWorkProfile) {
          final profile = restrictionKey.currentState?.getData();
          if(profile!=null)
           context.read<OnboardingBloc>().add(SetWorkProfileEvent(profile));
        }
      },
    builder: (context, state) {
        Map<String, dynamic> restrictionParams = {
          'restrictionProfile': state.workProfile,
          'stackRouteHistory': ['/onBoardingWorkProfile']
        };

       return  OnboardingSubWidget(
                title: localizations.workProfileHours,
                questionText: localizations.workProfileQuestion,
                child: CustomTimeRestrictionRoute( key: restrictionKey,isOnBoarding: true,params:restrictionParams)
       );}
    );
  }
}