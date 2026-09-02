import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// Primary "preview a better plan" action (spec §5.6 / §6.6).
///
/// Preview-first by contract: this only requests a preview, it must never
/// commit schedule changes. Kept as a leaf widget so toggling [loading] does
/// not rebuild the section list (§12).
class PlanPreviewCta extends StatelessWidget {
  const PlanPreviewCta({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.errorText,
  });

  static const Key buttonKey = Key('todayStatus.previewCta.button');
  static const Key progressKey = Key('todayStatus.previewCta.progress');
  static const Key chevronKey = Key('todayStatus.previewCta.chevron');
  static const Key errorKey = Key('todayStatus.previewCta.error');

  final VoidCallback onPressed;
  final bool loading;
  final bool enabled;

  /// Recoverable, non-destructive preview failure shown inline (§15.3).
  final String? errorText;

  bool get _interactive => enabled && !loading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final Color foreground = Theme.of(context).colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null)
          Padding(
            key: errorKey,
            padding: const EdgeInsets.only(bottom: TodayStatusTokens.space2),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 13, color: tokens.danger),
            ),
          ),
        Semantics(
          button: true,
          enabled: _interactive,
          label: loading
              ? l10n.todayStatusPreviewLoading
              : l10n.todayStatusPreviewCta,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _interactive ? _handleTap : null,
            child: Container(
              key: buttonKey,
              height: TodayStatusTokens.ctaHeight,
              decoration: BoxDecoration(
                color: enabled
                    ? tokens.brand
                    : tokens.brand.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(TodayStatusTokens.radiusMd + 4),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading) ...[
                    SizedBox(
                      key: progressKey,
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: foreground),
                    ),
                    const SizedBox(width: TodayStatusTokens.space2),
                  ],
                  Flexible(
                    child: Text(
                      l10n.todayStatusPreviewCta,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: TodayStatusTokens.space1),
                  Icon(
                    Icons.chevron_right,
                    key: chevronKey,
                    size: TodayStatusTokens.iconSm,
                    color: foreground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTap() {
    Utility.debugPrint(
        '[TodayStatus] preview CTA tapped (preview pipeline not wired yet)');
    onPressed();
  }
}
