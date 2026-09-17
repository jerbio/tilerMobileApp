import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/welcome/tilesVsBlocksExplainer.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// The animated "Tiles vs Blocks" demo shown once the essentials onboarding
/// pages (profession, location) are behind the user — on Submit and on
/// Skip alike — right before the schedule
/// (product-tour-onboarding-redesign.md, section 3.4b / stage 4.4).
///
/// The user reads at their own pace; "Let's Go!" replaces the whole stack
/// with [destinationBuilder] (the authorized app in production).
class OnboardingExplainerScreen extends StatefulWidget {
  static const String routeName = '/OnboardingExplainer';

  /// Builds where "Let's Go!" leads. Production passes `AuthorizedRoute`;
  /// tests pass a marker.
  final WidgetBuilder destinationBuilder;

  const OnboardingExplainerScreen({Key? key, required this.destinationBuilder})
      : super(key: key);

  @override
  State<OnboardingExplainerScreen> createState() =>
      _OnboardingExplainerScreenState();
}

class _OnboardingExplainerScreenState extends State<OnboardingExplainerScreen> {
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AnalysticsSignal.send('EXPLAINER_SHOWN');
    });
  }

  void _continue(BuildContext context) {
    if (_continued) return;
    _continued = true;
    AnalysticsSignal.send('EXPLAINER_CONTINUED');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: widget.destinationBuilder),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final Size size = MediaQuery.of(context).size;
    final bool landscape = size.width > size.height;
    final double textScale = MediaQuery.textScalerOf(context).scale(16) / 16;

    final Widget headline = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.welcomeExplainerHeadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.welcomeExplainerSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.85),
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 15,
          ),
        ),
      ],
    );

    final Widget cta = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _continue(context),
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

    const Widget explainer = TilesVsBlocksExplainer();

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: textScale > 1.3
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    headline,
                    const SizedBox(height: 20),
                    SizedBox(height: 400 * textScale, child: explainer),
                    const SizedBox(height: 20),
                    cta,
                  ],
                ),
              )
            : landscape
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              headline,
                              const SizedBox(height: 20),
                              cta
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(child: explainer),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        headline,
                        const SizedBox(height: 20),
                        const Expanded(child: explainer),
                        const SizedBox(height: 20),
                        cta,
                      ],
                    ),
                  ),
      ),
    );
  }
}
