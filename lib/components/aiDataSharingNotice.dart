import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Subtle footer shown at the bottom of the sign-in / sign-up screen.
///
/// Mirrors the common "By continuing, you agree to our Terms and Privacy"
/// pattern: a single muted line with two tappable links. The privacy policy
/// covers how data is handled, including with AI-powered features.
class AiDataSharingNotice extends StatefulWidget {
  const AiDataSharingNotice({super.key});

  @override
  State<AiDataSharingNotice> createState() => _AiDataSharingNoticeState();
}

class _AiDataSharingNoticeState extends State<AiDataSharingNotice> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(Constants.termsOfServiceUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(Constants.privacyPolicyUrl);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final bool launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiConsentLinkError)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiConsentLinkError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.55),
      fontSize: 12,
    );
    final linkStyle = baseStyle?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.75),
      decoration: TextDecoration.underline,
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: l10n.legalFooterPrefix),
            const TextSpan(text: ' '),
            TextSpan(
              text: l10n.legalFooterTerms,
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
            TextSpan(text: ' ${l10n.legalFooterAnd} '),
            TextSpan(
              text: l10n.legalFooterPrivacy,
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

