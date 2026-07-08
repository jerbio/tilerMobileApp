import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
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
  bool _readinessRequested = false;
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
    _requestReadinessTracking();
  }

  /// Kicks off background polling of this request's TileCast readiness (once)
  /// so the user can see when the actions become tappable.
  void _requestReadinessTracking() {
    if (_readinessRequested) return;
    final requestId = widget.requestId;
    if (requestId == null || requestId.isEmpty) return;
    if (!_hasClickableActions) return;
    _readinessRequested = true;
    context
        .read<VibeChatBloc>()
        .add(TrackTileCastReadinessEvent(requestId));
  }

  static const Set<ActionType> _nonClickableTypes = {
    ActionType.removeExistingTask,
    ActionType.whatIfRemovedTask,
    ActionType.conversationalAndNotSupported,
    ActionType.none,
  };
  static const Set<ActionStatus> _nonClickableStatuses = {
    ActionStatus.executed,
    ActionStatus.failed,
    ActionStatus.exited,
    ActionStatus.disposed,
  };

  bool _isActionClickable(VibeAction action) {
    if (_nonClickableTypes.contains(action.type)) return false;
    if (_nonClickableStatuses.contains(action.status)) return false;
    return true;
  }

  bool get _hasClickableActions =>
      widget.actions.any(_isActionClickable);

  PreviewState get _previewState =>
      widget.state.tileCastStateFor(widget.requestId);

  bool get _isTileCastReady => _previewState == PreviewState.ready;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final validActions = widget.actions
        .where((a) => a.type != ActionType.conversationalAndNotSupported)
        .toList();

    if (validActions.isEmpty) return SizedBox.shrink();

    Widget actionsWidget;
    if (validActions.length <= 5) {
      actionsWidget = Column(
        children: validActions
            .map((action) => _buildActionTile(action: action))
            .toList(),
      );
    } else {
      actionsWidget = Align(
        alignment: Alignment.centerLeft,
        child: _buildPillGroup(validActions),
      );
    }

    final banner = _buildReadinessBanner();
    if (banner == null) return actionsWidget;

    // Dim the actions until the preview is ready so it's obvious they aren't
    // tappable yet.
    final bool dim = !_isTileCastReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        banner,
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dim ? 0.45 : 1.0,
          child: actionsWidget,
        ),
      ],
    );
  }

  /// Request-level affordance telling the user whether the TileCast preview is
  /// ready to open. Returns null when there is nothing tappable to preview.
  Widget? _buildReadinessBanner() {
    if (!_hasClickableActions) return null;

    late final IconData icon;
    late final String label;
    late final Color color;
    bool showSpinner = false;

    switch (_previewState) {
      case PreviewState.ready:
        icon = Icons.check_circle_rounded;
        label = localization.previewReadyToView;
        color = TileColors.vibeChatExecutedAction;
        break;
      case PreviewState.failed:
        icon = Icons.error_outline_rounded;
        label = localization.previewActionsUnavailable;
        color = colorScheme.error;
        break;
      case PreviewState.invalidated:
        icon = Icons.history_rounded;
        label = localization.previewActionsOutdated;
        color = colorScheme.tertiary;
        break;
      case PreviewState.queued:
      case PreviewState.processing:
      case PreviewState.unknown:
        icon = Icons.hourglass_top_rounded;
        label = localization.previewPreparing;
        color = colorScheme.onSurfaceVariant;
        showSpinner = true;
        break;
    }

    return Padding(
      key: const ValueKey('tilecast_readiness_banner'),
      padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
        if (!_isActionClickable(action)) return;

        // Only open the preview once the request's TileCast has finished
        // generating; otherwise tapping would spin and eventually time out.
        if (!_isTileCastReady) return;

        if (widget.requestId != null) {
          context.read<VibeChatBloc>().add(
              LoadTileCastEvent(widget.requestId!, actionId: action.id));
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
      case ActionType.addNewAppointment:
        return 'assets/icons/vibeChat/add_block.svg';
      case ActionType.addNewTask:
        return 'assets/icons/vibeChat/add_new_tile.svg';
      case ActionType.updateExistingTask:
        return 'assets/icons/vibeChat/update_tile.svg';
      case ActionType.removeExistingTask:
        return 'assets/icons/vibeChat/delete_tile.svg';
      case ActionType.procrastinateAllTasks:
        return 'assets/icons/vibeChat/clear_all.svg';
      case ActionType.exitPrompting:
        return 'assets/icons/vibeChat/exited_action.svg';
      case ActionType.addNewProject:
        return '📋';
      case ActionType.decideIfTaskOrProject:
        return '🤔';
      case ActionType.markTaskAsDone:
        return '✓';
      case ActionType.whatIfAddANewAppointment:
        return '📅❓';
      case ActionType.whatIfAddedNewTask:
        return '✅❓';
      case ActionType.whatIfEditUpdateTask:
        return '✏️❓';
      case ActionType.whatIfProcrastinateTask:
        return '⏱️❓';
      case ActionType.whatIfRemovedTask:
        return '🗑️❓';
      case ActionType.whatIfMarkedTaskAsDone:
        return '✓❓';
      case ActionType.whatIfProcrastinateAll:
        return '⏱️❓';
      case ActionType.conversationalAndNotSupported:
        return '💬';
      case ActionType.none:
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
