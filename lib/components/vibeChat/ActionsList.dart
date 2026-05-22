import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class ActionsList extends StatefulWidget {
  final List<VibeAction> actions;
  final String? requestId;
  final VibeChatState state;

  const ActionsList({
    Key? key,
    required this.actions,
    required this.requestId,
    required this.state,
  }) : super(key: key);

  @override
  State<ActionsList> createState() => _ActionsListState();
}

class _ActionsListState extends State<ActionsList>   with AutomaticKeepAliveClientMixin {
  bool _expanded = false;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late AppLocalizations localization;

  @override
  bool get wantKeepAlive => _expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = Theme
        .of(context)
        .colorScheme;
    tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;
    localization = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final validActions = widget.actions
        .where((a) => a.type != 'conversational_and_not_supported')
        .toList();

    if (validActions.isEmpty) return SizedBox.shrink();

    if (validActions.length <= 5) {
      return Column(
        children: validActions
            .map((action) => _buildActionTile(action: action))
            .toList(),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: _buildPillGroup(validActions),
    );
  }

  Widget _buildPillGroup(List<VibeAction> actions
      ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _expanded ? colorScheme.primary : colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _expanded ? colorScheme.primary : colorScheme.outline
                        .withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: _expanded ? colorScheme.onPrimary : colorScheme
                          .primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _expanded ? localization.hideActions : localization
                          .actionsCount(actions.length),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _expanded ? colorScheme.onPrimary : colorScheme
                            .onSurface,
                      ),
                    ),
                    Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: _expanded ? colorScheme.onPrimary : colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: SizedBox(height: _expanded ? 5 : 0),
            ),
            ...actions
                .asMap()
                .entries
                .map((entry) {
              final i = entry.key;
              final action = entry.value;
              return AnimatedAlign(
                  duration: Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  heightFactor: _expanded ? 1.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200 + i * 40),
                    opacity: _expanded ? 1.0 : 0.0,
                    child: _buildActionTile(action: action),
                  )
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({required VibeAction action}) {
    final statusColor = _getActionStatusColor(action.status, tileThemeExtension);

    return GestureDetector(
      onTap: () {
        if (widget.state.step != VibeChatStep.loaded) return;
        const nonClickableTypes = {
          'remove_existing_task',
          'whatif_removedtask',
          'conversational_and_not_supported',
          'none',
        };
        const nonClickableStatuses = {
          ActionStatus.executed,
          ActionStatus.failed,
          ActionStatus.exited,
          ActionStatus.disposed,
        };

        if (nonClickableTypes.contains(action.type)) return;
        if (nonClickableStatuses.contains(action.status)) return;

        if (widget.requestId != null) {
          context.read<VibeChatBloc>().add(PreviewActionEvent(widget.requestId! , action.id ?? ''));
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.all(5),
          padding: EdgeInsets.all(5),
          constraints: BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionIcon(action),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  action.descriptions ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(VibeAction action) {
    final icon = _getActionIconPath(action);
    if (icon is String && icon.endsWith('.svg')) {
      return SvgPicture.asset(
        icon,
        width: 14,
        height: 14,
      );
    } else {
      return Text(
        icon,
        style: TextStyle(fontSize: 14),
      );
    }
  }

  dynamic _getActionIconPath(VibeAction action) {
    switch (action.type) {
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
      case 'exit_prompting':
        return 'assets/icons/vibeChat/exited_action.svg';
      case 'add_new_project':
        return '📋';
      case 'decide_if_task_or_project':
        return '🤔';
      case 'mark_task_as_done':
        return '✓';
      case 'whatif_addanewappointment':
        return '📅❓';
      case 'whatif_addednewtask':
        return '✅❓';
      case 'whatif_editupdatetask':
        return '✏️❓';
      case 'whatif_procrastinatetask':
        return '⏱️❓';
      case 'whatif_removedtask':
        return '🗑️❓';
      case 'whatif_markedtaskasdone':
        return '✓❓';
      case 'whatif_procrastinateall':
        return '⏱️❓';
      case 'conversational_and_not_supported':
        return '💬';
      case 'none':
        return '⚪';
      default:
        return '🔹';
    }
  }

  Color _getActionStatusColor(ActionStatus? status, TileThemeExtension theme) {
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
        return theme.vibeChatExitedAction;
      case ActionStatus.disposed:
        return theme.vibeChatDisposedAction;
      default:
        return theme.vibeChatDefaultAction;
    }
  }
}
