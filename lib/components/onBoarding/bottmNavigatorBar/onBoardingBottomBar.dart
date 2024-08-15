import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_event.dart';
import '../../../bloc/onBoarding/on_boarding_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'onBoradingBottomButton.dart';

class OnboardingBottomNavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingBottomNavigationBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 20, left: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  return state.pageNumber != null && state.pageNumber! > 0? onBoardingBottomButton(
                    icon: Icons.arrow_back,
                    press: () {
                      context.read<OnboardingBloc>().add(PreviousPageEvent());
                    },
                  ):SizedBox();
                },
              ),

              onBoardingBottomButton(
                icon: Icons.arrow_forward,
                press: () {
                  context.read<OnboardingBloc>().add(NextPageEvent());
                },
              ),
            ],
          ),
          SizedBox(height: 5),
           GestureDetector(
             onTap: () {
                context.read<OnboardingBloc>().add(SkipOnboardingEvent());
              },
             child: Text(
                AppLocalizations.of(context)!.skip,
                style: TextStyle(color: Colors.grey, fontSize: 22),
                       ),
           ),
        ],
      ),
    );
  }
}
