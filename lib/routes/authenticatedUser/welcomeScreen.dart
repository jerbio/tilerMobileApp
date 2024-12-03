// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';

// import 'package:tiler_app/styles.dart';

// import '../../util.dart';
// import '../authentication/AuthorizedRoute.dart';
// import '../authentication/onBoarding.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:tiler_app/services/localizationService.dart';

// enum WelcomeType { register, login }

// class WelcomeScreen extends StatefulWidget {
//   final WelcomeType welcomeType;
//   final String firstName;
//   // final LocalizationService localizationService;

//   const WelcomeScreen({
//     super.key,
//     required this.welcomeType,
//     required this.firstName,
//     // required this.localizationService
//   });

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     checkOnboarding();
//   }

//   Future<void> checkOnboarding() async {
//     // Introduce a delay of 3 seconds
//     await Future.delayed(Duration(seconds: 3));

//     // Then check the onboarding status
//     bool nextPage = await Utility.checkOnboardingStatus();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => nextPage ? AuthorizedRoute() : OnboardingView(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height;
//     double width = MediaQuery.of(context).size.width;

//     // Function to dynamically calculate height according to screen size
//     double calculateSizeByHeight(double value) {
//       return height / (height / value);
//     }

//     return Scaffold(
//       backgroundColor: TileStyles.primaryColor,
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           SizedBox(
//               height: height *
//                   0.3), // Adjust this value to move the text up or down
//           Text(
//             widget.welcomeType == WelcomeType.register
//                 ? AppLocalizations.of(context)!.welcome
//                 : AppLocalizations.of(context)!.hi,
//             style: TextStyle(
//               color: Colors.white,
//               fontFamily: TileStyles.rubikFontName,
//               fontSize: calculateSizeByHeight(36),
//             ),
//           ),
//           Text(
//             widget.firstName,
//             style: TextStyle(
//               color: Colors.white,
//               fontFamily: TileStyles.rubikFontName,
//               fontSize: calculateSizeByHeight(40),
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.only(bottom: calculateSizeByHeight(20)),
//               width: width,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Transform.scale(
//                     scale: 1.2,
//                     child: Lottie.asset(
//                       "assets/images/welcome-wave.json",
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:tiler_app/styles.dart';
// import '../../util.dart';
// import '../authentication/AuthorizedRoute.dart';
// import '../authentication/onBoarding.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// enum WelcomeType { register, login }

// class WelcomeScreen extends StatefulWidget {
//   final WelcomeType welcomeType;
//   final String firstName;

//   const WelcomeScreen({
//     super.key,
//     required this.welcomeType,
//     required this.firstName,
//   });

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     checkOnboarding();
//   }

//   Future<void> checkOnboarding() async {
//     await Future.delayed(Duration(seconds: 3));
//     bool nextPage = await Utility.checkOnboardingStatus();
//     if (mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => nextPage ? AuthorizedRoute() : OnboardingView(),
//         ),
//       );
//     }
//   }

//   Widget _buildPortraitLayout(BuildContext context, double height, double width) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         SizedBox(height: height * 0.25),
//         _buildWelcomeText(height),
//         _buildNameText(height),
//         Expanded(
//           child: _buildAnimationContainer(height, width, 1.2),
//         ),
//       ],
//     );
//   }

//   Widget _buildLandscapeLayout(BuildContext context, double height, double width) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 1,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildWelcomeText(height),
//               SizedBox(height: height * 0.02),
//               _buildNameText(height),
//             ],
//           ),
//         ),
//         Expanded(
//           flex: 1,
//           child: _buildAnimationContainer(height, width, 0.9),
//         ),
//       ],
//     );
//   }

//   Widget _buildWelcomeText(double height) {
//     return Text(
//       widget.welcomeType == WelcomeType.register
//           ? AppLocalizations.of(context)!.welcome
//           : AppLocalizations.of(context)!.hi,
//       style: TextStyle(
//         color: Colors.white,
//         fontFamily: TileStyles.rubikFontName,
//         fontSize: _calculateAdaptiveSize(height, 36),
//       ),
//     );
//   }

//   Widget _buildNameText(double height) {
//     return Text(
//       widget.firstName,
//       style: TextStyle(
//         color: Colors.white,
//         fontFamily: TileStyles.rubikFontName,
//         fontSize: _calculateAdaptiveSize(height, 40),
//         fontWeight: FontWeight.w700,
//       ),
//     );
//   }

//   Widget _buildAnimationContainer(double height, double width, double scale) {
//     return Container(
//       padding: EdgeInsets.only(bottom: _calculateAdaptiveSize(height, 20)),
//       width: width,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Transform.scale(
//             scale: scale,
//             child: Lottie.asset(
//               "assets/images/welcome-wave.json",
//               fit: BoxFit.contain,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   double _calculateAdaptiveSize(double screenSize, double value) {
//     return screenSize / (screenSize / value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height;
//     double width = MediaQuery.of(context).size.width;
//     Orientation orientation = MediaQuery.of(context).orientation;

//     return Scaffold(
//       backgroundColor: TileStyles.primaryColor,
//       body: SafeArea(
//         child: orientation == Orientation.portrait
//             ? _buildPortraitLayout(context, height, width)
//             : _buildLandscapeLayout(context, height, width),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/styles.dart';
import '../../util.dart';
import '../authentication/AuthorizedRoute.dart';
import '../authentication/onBoarding.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum WelcomeType { register, login }

class WelcomeScreen extends StatefulWidget {
  final WelcomeType welcomeType;
  final String firstName;

  const WelcomeScreen({
    super.key,
    required this.welcomeType,
    required this.firstName,
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
    await Future.delayed(Duration(seconds: 3));
    bool nextPage = await Utility.checkOnboardingStatus();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => nextPage ? AuthorizedRoute() : OnboardingView(),
        ),
      );
    }
  }

  Widget _buildPortraitLayout(BuildContext context, double height, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: height * 0.25),
        _buildWelcomeText(height),
        _buildNameText(height),
        Expanded(
          child: _buildAnimationContainer(height, width, 1.2),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, double height, double width) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWelcomeText(height),
              SizedBox(height: height * 0.02),
              _buildNameText(height),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: height,
            child: Transform.scale(
              scale: 1.5,  // Adjust this value as needed for your animation
              child: Lottie.asset(
                "assets/images/welcome-wave.json",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(double height) {
    return Text(
      widget.welcomeType == WelcomeType.register
          ? AppLocalizations.of(context)!.welcome
          : AppLocalizations.of(context)!.hi,
      style: TextStyle(
        color: Colors.white,
        fontFamily: TileStyles.rubikFontName,
        fontSize: _calculateAdaptiveSize(height, 36),
      ),
    );
  }

  Widget _buildNameText(double height) {
    return Text(
      widget.firstName,
      style: TextStyle(
        color: Colors.white,
        fontFamily: TileStyles.rubikFontName,
        fontSize: _calculateAdaptiveSize(height, 40),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAnimationContainer(double height, double width, double scale) {
    return Container(
      padding: EdgeInsets.only(bottom: _calculateAdaptiveSize(height, 20)),
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Lottie.asset(
              "assets/images/welcome-wave.json",
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAdaptiveSize(double screenSize, double value) {
    return screenSize / (screenSize / value);
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      backgroundColor: TileStyles.primaryColor,
      body: SafeArea(
        child: orientation == Orientation.portrait
            ? _buildPortraitLayout(context, height, width)
            : _buildLandscapeLayout(context, height, width),
      ),
    );
  }
}