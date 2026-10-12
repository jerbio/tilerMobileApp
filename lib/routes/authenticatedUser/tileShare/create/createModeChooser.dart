import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// One way to share work, as the chooser offers it.
class CreateModeOption {
  final TileShareMode mode;
  final String Function(AppLocalizations l10n) description;

  /// Not yet creatable: shown, marked *Coming soon*, not tappable.
  final bool available;

  const CreateModeOption(this.mode, this.description, {this.available = true});
}

/// The modes on offer, in order. Data, so a mode joins (or a deferred one,
/// T12) by adding a line. Class and Project are created in 9.19 / 9.20.
final List<CreateModeOption> createModeOptions = <CreateModeOption>[
  CreateModeOption(
    TileShareMode.broadcast,
    (l10n) => l10n.createModeBroadcastBody,
  ),
  CreateModeOption(
    TileShareMode.class_,
    (l10n) => l10n.createModeClassBody,
    available: false,
  ),
  CreateModeOption(
    TileShareMode.project,
    (l10n) => l10n.createModeProjectBody,
    available: false,
  ),
];

/// Create starts with the mode (T14, §5.7): a sheet of the ways to share,
/// in plain words. Answers with the mode picked, or `null` when closed.
Future<TileShareMode?> showCreateModeChooser(
  BuildContext context, {
  List<CreateModeOption>? options,
}) => showModalBottomSheet<TileShareMode>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => CreateModeChooser(options: options ?? createModeOptions),
);

class CreateModeChooser extends StatelessWidget {
  final List<CreateModeOption> options;

  const CreateModeChooser({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      key: const Key('create_mode_chooser'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createChooserTitle,
              style: textTheme.titleLarge?.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.createChooserSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (final CreateModeOption option in options) ...[
              _ModeCard(option: option),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final CreateModeOption option;

  const _ModeCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = option.available;
    final String title = TileShareModeBadge.labelOf(l10n, option.mode) ?? '';
    final Color muted = tokens.textSecondary;
    return Semantics(
      button: available,
      enabled: available,
      child: Material(
        key: Key('create_mode_${option.mode.wire}'),
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: available
              ? () => Navigator.of(context).pop(option.mode)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.brand.withValues(
                      alpha: available ? 0.12 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    TileShareModeBadge.iconOf(option.mode),
                    size: 22,
                    color: available ? tokens.brand : muted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: available ? tokens.textPrimary : muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description(l10n),
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      if (!available) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.createComingSoon,
                          style: textTheme.labelSmall?.copyWith(
                            color: muted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (available) Icon(Icons.chevron_right, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
