import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:tiler_app/styles.dart';

import '../../util.dart';
import '../authentication/AuthorizedRoute.dart';
import '../authentication/onBoarding.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/localizationService.dart';

enum WelcomeType { register, login }

class WelcomeScreen extends StatefulWidget {
  final WelcomeType welcomeType;
  final String firstName;
  // final LocalizationService localizationService;

  const WelcomeScreen({
    super.key,
    required this.welcomeType,
    required this.firstName,
    // required this.localizationService
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    checkOnboarding();
  }

  Future<void> checkOnboarding() async {
    // Introduce a delay of 3 seconds
    await Future.delayed(Duration(seconds: 3));

    // Then check the onboarding status
    bool nextPage = await Utility.checkOnboardingStatus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => nextPage ? AuthorizedRoute() : OnboardingView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    // Function to dynamically calculate height according to screen size
    double calculateSizeByHeight(double value) {
      return height / (height / value);
    }

    return Scaffold(
      backgroundColor: TileStyles.primaryColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              height: height *
                  0.3), // Adjust this value to move the text up or down
          Text(
            widget.welcomeType == WelcomeType.register
                ? AppLocalizations.of(context)!.welcome
                : AppLocalizations.of(context)!.hi,
            style: TextStyle(
              color: Colors.white,
              fontFamily: TileStyles.rubikFontName,
              fontSize: calculateSizeByHeight(36),
            ),
          ),
          Text(
            widget.firstName,
            style: TextStyle(
              color: Colors.white,
              fontFamily: TileStyles.rubikFontName,
              fontSize: calculateSizeByHeight(40),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: calculateSizeByHeight(20)),
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Lottie.asset(
                      "assets/images/welcome-wave.json",
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
