import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class ThirdPartyDecisionBar extends StatelessWidget {
  final TileSource? source;
  final RsvpStatus? rsvpStatus;
  final bool isProcessing;
  final String? errorText;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ThirdPartyDecisionBar({
    super.key,
    required this.source,
    required this.rsvpStatus,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
    this.errorText,
  });

  String _getSourceLabel(BuildContext context) {
    if (source == null) {
      return AppLocalizations.of(context)?.unknown ?? 'Calendar invite';
    }
    String name = source!.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sourceLabel = _getSourceLabel(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.respondToCalendar(sourceLabel),
                style: theme.textTheme.titleMedium,
              ),
              if (isProcessing)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.25,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: rsvpStatus == RsvpStatus.declined
                    ? FilledButton(
                        onPressed: isProcessing ? null : onDecline,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.surface,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.declined,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: isProcessing ? null : onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: cs.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.decline),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: rsvpStatus == RsvpStatus.accepted
                    ? FilledButton(
                        onPressed: isProcessing ? null : onAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.accepted,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: isProcessing ? null : onAccept,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.accept),
                      ),
              ),
            ],
          ),
          if (errorText != null && errorText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}
