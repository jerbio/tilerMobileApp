import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/components/welcome/tilesVsBlocksExplainer.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import '../../util.dart';
import '../authentication/AuthorizedRoute.dart';
import '../authentication/onBoarding.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

enum WelcomeType { register, login }

class WelcomeScreen extends StatefulWidget {
  /// How long the welcome beat stays on screen before routing on. The
  /// launch gate is a local read and the schedule is already loading
  /// (stages 3.5 / 4.1), so this is purely a brand beat — it used to be a
  /// 3s sleep in front of a blocking server check.
  static const Duration displayDuration = Duration(milliseconds: 800);

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

  /// Stage 4.4: a device that still needs the essentials onboarding gets
  /// the animated "Tiles vs Blocks" explainer and moves on when the user
  /// taps "Let's Go!"; a device that is done keeps the short brand beat
  /// and routes on its own.
  bool _showExplainer = false;

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
    final checker =
        widget.onboardingStatusChecker ?? Utility.checkOnboardingStatus;
    final Future<void> beat = Future.delayed(WelcomeScreen.displayDuration);
    final bool onboardingDone = await checker();
    if (!mounted) return;
    if (!onboardingDone) {
      // New device: explain Tiler first; the user decides when to go on.
      setState(() => _showExplainer = true);
      return;
    }
    // The gate check ran alongside the beat, never after it: the wait is
    // max(beat, check), not beat + check.
    await beat;
    if (mounted)
      _routeTo(widget.authorizedRouteBuilder ?? (_) => AuthorizedRoute());
  }

  void _continueToOnboarding() {
    _routeTo(widget.onboardingRouteBuilder ?? (_) => OnboardingView());
  }

  void _routeTo(WidgetBuilder builder) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: builder),
      (route) => false,
    );
  }

  Widget _buildExplainerLayout(
      BuildContext context, double height, double width) {
    final l10n = AppLocalizations.of(context)!;
    final bool landscape = width > height;
    final Widget greeting = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.welcomeType == WelcomeType.register ? l10n.welcome : l10n.hi,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: _calculateAdaptiveSize(height, 22),
          ),
        ),
        Text(
          widget.firstName,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: _calculateAdaptiveSize(height, 28),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.welcomeExplainerHeadline,
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.9),
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
    final Widget cta = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continueToOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.onPrimary,
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          l10n.tutorialNavLetsGo,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final Widget explainer = const TilesVsBlocksExplainer();

    if (landscape) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [greeting, const SizedBox(height: 20), cta],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: explainer),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          greeting,
          const SizedBox(height: 16),
          Expanded(child: explainer),
          const SizedBox(height: 20),
          cta,
        ],
      ),
    );
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
        child: _showExplainer
            ? _buildExplainerLayout(context, height, width)
            : orientation == Orientation.portrait
                ? _buildPortraitLayout(context, height, width)
                : _buildLandscapeLayout(context, height, width),
      ),
    );
  }
}
