import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class SimulationReviewSheet extends StatelessWidget {
  final VibeRequestPreview simulation;
  final void Function(String actionId)? onActionTap;

  const SimulationReviewSheet({
    Key? key,
    required this.simulation,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final tileTheme = Theme.of(context).extension<TileThemeExtension>()!;
    final actions = simulation.previewActions ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text(
                  localization.previewChanges,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (actions.isNotEmpty)
                  Text(
                    localization.changesCount(actions.length),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                localization.noActionsInPreview,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            Flexible(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionRow(
                            previewAction: actions[i],
                            tileTheme: tileTheme,
                            colorScheme: colorScheme,
                            onTap: () {
                              final actionId = actions[i].action?.id;
                              if (actionId != null) onActionTap?.call(actionId);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                      childCount: actions.length,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VibePreviewAction previewAction;
  final TileThemeExtension tileTheme;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.previewAction,
    required this.tileTheme,
    required this.colorScheme,
    this.onTap,
  });

  Color _statusColor(ActionStatus? status) {
    switch (status) {
      case ActionStatus.parsed:
        return TileColors.vibeChatParsedAction;
      case ActionStatus.clarification:
        return TileColors.vibeChatClarificationAction;
      case ActionStatus.pending:
        return TileColors.vibeChatPendingAction;
      case ActionStatus.executed:
        return TileColors.vibeChatExecutedAction;
      case ActionStatus.failed:
        return TileColors.vibeChatFailedAction;
      case ActionStatus.exited:
        return tileTheme.vibeChatExitedAction;
      case ActionStatus.disposed:
        return tileTheme.vibeChatDisposedAction;
      default:
        return tileTheme.vibeChatDefaultAction;
    }
  }

  String? _iconPath(VibeAction? action) {
    switch (action?.type) {
      case 'add_new_appointment':
        return 'assets/icons/vibeChat/add_block.svg';
      case 'add_new_task':
        return 'assets/icons/vibeChat/add_new_tile.svg';
      case 'update_existing_task':
        return 'assets/icons/vibeChat/update_tile.svg';
      case 'remove_existing_task':
        return 'assets/icons/vibeChat/delete_tile.svg';
      case 'procrastinate_all_tasks':
        return 'assets/icons/vibeChat/clear_all.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = previewAction.action;
    final iconPath = _iconPath(action);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (iconPath != null)
              SvgPicture.asset(iconPath, width: 16, height: 16)
            else
              const Text('🔹', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action?.descriptions ?? previewAction.entityType ?? '—',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(action?.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
