import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import '../../util.dart';
import '../authentication/AuthorizedRoute.dart';
import '../authentication/onBoarding.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

enum WelcomeType { register, login }

class WelcomeScreen extends StatefulWidget {
  final WelcomeType welcomeType;
  final String firstName;

  /// Override the onboarding status check — used in tests.
  final Future<bool> Function()? onboardingStatusChecker;

  /// Override the destination widget builder when onboarding is complete — used in tests.
  final WidgetBuilder? authorizedRouteBuilder;

  /// Override the destination widget builder when onboarding is NOT complete — used in tests.
  final WidgetBuilder? onboardingRouteBuilder;

  const WelcomeScreen({
    super.key,
    required this.welcomeType,
    required this.firstName,
    this.onboardingStatusChecker,
    this.authorizedRouteBuilder,
    this.onboardingRouteBuilder,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    checkOnboarding();
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    super.didChangeDependencies();
  }

  Future<void> checkOnboarding() async {
    await Future.delayed(Duration(seconds: 3));
    final checker = widget.onboardingStatusChecker ?? Utility.checkOnboardingStatus;
    bool nextPage = await checker();
    if (mounted) {
      final authorizedBuilder = widget.authorizedRouteBuilder ?? (_) => AuthorizedRoute();
      final onboardingBuilder = widget.onboardingRouteBuilder ?? (_) => OnboardingView();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: nextPage ? authorizedBuilder : onboardingBuilder,
        ),
        (route) => false,
      );
    }
  }

  Widget _buildPortraitLayout(
      BuildContext context, double height, double width) {
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

  Widget _buildLandscapeLayout(
      BuildContext context, double height, double width) {
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
              scale: 1.5, // Adjust this value as needed for your animation
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
        color: colorScheme.onPrimary,
        fontFamily: TileTextStyles.rubikFontName,
        fontSize: _calculateAdaptiveSize(height, 36),
      ),
    );
  }

  Widget _buildNameText(double height) {
    return Text(
      widget.firstName,
      style: TextStyle(
        color: colorScheme.onPrimary,
        fontFamily: TileTextStyles.rubikFontName,
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
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: orientation == Orientation.portrait
            ? _buildPortraitLayout(context, height, width)
            : _buildLandscapeLayout(context, height, width),
      ),
    );
  }
}
