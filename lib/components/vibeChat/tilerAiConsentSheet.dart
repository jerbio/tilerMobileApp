import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy policy destination shown from the AI consent sheet.
const String kTilerPrivacyPolicyUrl = 'https://tiler.app/privacy';

/// Presents the iOS AI data-sharing consent sheet.
///
/// Returns `true` only when the user taps the affirmative CTA. Dismissing the
/// sheet (close control, scrim, or back gesture) returns `false` — there is no
/// decline button, dismissing simply keeps Tiler AI closed.
Future<bool> showTilerAiConsentSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const TilerAiConsentSheet(),
  );
  return result ?? false;
}

/// Attractive, conversion-oriented consent sheet that discloses what data is
/// shared with third-party AI providers (Google Gemini and OpenAI), links to
/// the privacy policy, and offers a single affirmative call to action.
class TilerAiConsentSheet extends StatelessWidget {
  const TilerAiConsentSheet({super.key});

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(kTilerPrivacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: localization.aiConsentClose,
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              _Hero(colorScheme: colorScheme),
              const SizedBox(height: 16),
              Text(
                localization.aiConsentTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localization.aiConsentSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localization.aiConsentIntro,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _DisclosureRow(
                icon: Icons.upload_rounded,
                title: localization.aiConsentDataTitle,
                body: localization.aiConsentDataBody,
                colorScheme: colorScheme,
                textTheme: theme.textTheme,
              ),
              const SizedBox(height: 16),
              _DisclosureRow(
                icon: Icons.hub_outlined,
                title: localization.aiConsentProvidersTitle,
                body: localization.aiConsentProvidersBody,
                colorScheme: colorScheme,
                textTheme: theme.textTheme,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _openPrivacyPolicy,
                  child: Text(localization.aiConsentPrivacyLink),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  localization.aiConsentContinue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.tertiary,
            ],
          ),
        ),
        child: Icon(
          Icons.auto_awesome,
          color: colorScheme.onPrimary,
          size: 36,
        ),
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String title;
  final String body;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
