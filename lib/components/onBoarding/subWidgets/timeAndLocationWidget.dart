import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/onBoardingSubWidget.dart';

class TimeAndLocationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    return OnboardingSubWidget(
      title: localizations.timeAndLocationTitle,
      questionText: localizations.timeAndLocationSubTitle,
      questionSubText: localizations.timeAndLocationSecondarySubTitle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                context
                    .read<OnboardingBloc>()
                    .add(GetTimeAndLocationEvent(true));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                localizations.yes,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 30),
          SizedBox(
            width: 100,
            height: 45,
            child: OutlinedButton(
              onPressed: () {
                context
                    .read<OnboardingBloc>()
                    .add(GetTimeAndLocationEvent(false));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.onSurface),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                localizations.no,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
