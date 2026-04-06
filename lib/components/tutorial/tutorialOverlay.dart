import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_state.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tutorial/tutorialDummyData.dart';
import 'package:tiler_app/components/tutorial/tutorialSpotlightPainter.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/components/tutorial/tutorialTooltipWidget.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The main tutorial overlay that renders on top of the AuthorizedRoute.
/// It reads the current step from TutorialBloc, highlights the target widget,
/// and shows a tooltip with instructions.
class TutorialOverlay extends StatefulWidget {
  final Widget child;

  /// Callback that opens the real add-tile bottom sheet during the tutorial.
  /// Receives the [TutorialBloc] so the dialog shown on top of the sheet
  /// can advance / go back without needing a BlocProvider lookup.
  /// Returns a Future that completes when the sheet is dismissed.
  final Future<void> Function(TutorialBloc bloc)? onShowAddTileSheet;

  /// Callback to dismiss the add-tile sheet if it's currently showing.
  final VoidCallback? onDismissAddTileSheet;

  const TutorialOverlay({
    Key? key,
    required this.child,
    this.onShowAddTileSheet,
    this.onDismissAddTileSheet,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<TutorialStep> _steps;

  /// Tracks the previous step index so we can fire onExit / onEnter.
  int _previousStepIndex = 0;

  /// Whether the real add-tile sheet is currently showing.
  bool _addTileSheetShowing = false;

  /// Whether dummy tutorial tiles have been injected into the schedule.
  bool _dummyTilesInjected = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _steps = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _steps = _buildSteps(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<TutorialStep> _buildSteps(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      // Step 1: Your Schedule
      TutorialStep(
        id: 'schedule_view',
        targetKey: TutorialKeys.scheduleViewKey,
        title: l10n.tutorialStepYourScheduleTitle,
        body: l10n.tutorialStepYourScheduleBody,
        headerIcon: Icons.view_agenda_rounded,
        tooltipPosition: TooltipPosition.center,
        spotlightShape: SpotlightShape.roundedRect,
        spotlightPadding: 0,
      ),

      // Step 2: The FAB — Create & Optimize
      TutorialStep(
        id: 'fab_add_tile',
        targetKey: TutorialKeys.fabKey,
        title: l10n.tutorialStepCreateOptimizeTitle,
        body: l10n.tutorialStepCreateOptimizeBody,
        headerIcon: Icons.add_circle_outline,
        tooltipPosition: TooltipPosition.above,
        spotlightShape: SpotlightShape.circle,
        spotlightPadding: 4,
        callouts: [
          TutorialCallout(
            icon: Icons.refresh,
            label: l10n.tutorialCalloutReOptimize,
            description: l10n.tutorialCalloutReOptimizeDesc,
          ),
          TutorialCallout(
            icon: Icons.directions_car,
            label: l10n.tutorialCalloutTravelTime,
            description: l10n.tutorialCalloutTravelTimeDesc,
          ),
        ],
      ),

      // Step 3: Quick Add explanation — opens the real add-tile sheet
      TutorialStep(
        id: 'quick_add',
        targetKey: null, // full-screen overlay (sheet is shown via modal)
        title: l10n.tutorialStepQuickCreateTitle,
        body: l10n.tutorialStepQuickCreateBody,
        headerIcon: Icons.bolt,
        tooltipPosition: TooltipPosition.center,
        callouts: [
          TutorialCallout(
            icon: Icons.edit,
            label: l10n.tutorialCalloutNameYourTile,
            description: l10n.tutorialCalloutNameYourTileDesc,
          ),
          TutorialCallout(
            icon: Icons.timer,
            label: l10n.tutorialCalloutSetDuration,
            description: l10n.tutorialCalloutSetDurationDesc,
          ),
          TutorialCallout(
            icon: Icons.tune,
            label: l10n.tutorialCalloutMoreOptions,
            description: l10n.tutorialCalloutMoreOptionsDesc,
          ),
        ],
      ),

      // Step 4: Smart Scheduling — Tiler Works for You
      TutorialStep(
        id: 'smart_scheduling',
        targetKey: TutorialKeys.bottomNavKey,
        title: l10n.tutorialStepTilerWorksTitle,
        body: l10n.tutorialStepTilerWorksBody,
        headerIcon: Icons.auto_awesome,
        tooltipPosition: TooltipPosition.above,
        spotlightShape: SpotlightShape.roundedRect,
        spotlightPadding: 4,
        callouts: [
          TutorialCallout(
            icon: Icons.preview,
            label: l10n.tutorialCalloutForecast,
            description: l10n.tutorialCalloutForecastDesc,
          ),
          TutorialCallout(
            icon: Icons.shuffle,
            label: l10n.tutorialCalloutShuffle,
            description: l10n.tutorialCalloutShuffleDesc,
          ),
          TutorialCallout(
            icon: Icons.fast_forward,
            label: l10n.tutorialCalloutDeferAll,
            description: l10n.tutorialCalloutDeferAllDesc,
          ),
        ],
      ),

      // Step 5: Tile Interactions
      TutorialStep(
        id: 'tile_interactions',
        targetKey: TutorialKeys.currentTileKey,
        title: l10n.tutorialStepControlTilesTitle,
        body: l10n.tutorialStepControlTilesBody,
        headerIcon: Icons.touch_app,
        tooltipPosition: TooltipPosition.below,
        spotlightShape: SpotlightShape.roundedRect,
        spotlightPadding: 8,
        callouts: [
          TutorialCallout(
            icon: Icons.play_arrow,
            label: l10n.tutorialCalloutPlay,
            description: l10n.tutorialCalloutPlayDesc,
          ),
          TutorialCallout(
            icon: Icons.pause,
            label: l10n.tutorialCalloutPause,
            description: l10n.tutorialCalloutPauseDesc,
          ),
          TutorialCallout(
            icon: Icons.check_circle,
            label: l10n.tutorialCalloutComplete,
            description: l10n.tutorialCalloutCompleteDesc,
          ),
          TutorialCallout(
            icon: Icons.fast_forward,
            label: l10n.tutorialCalloutProcrastinate,
            description: l10n.tutorialCalloutProcrastinateDesc,
          ),
        ],
      ),

      // Step 6: Switch Views — Calendar Toggle
      TutorialStep(
        id: 'switch_views',
        targetKey: TutorialKeys.bottomNavKey,
        title: l10n.tutorialStepBigPictureTitle,
        body: l10n.tutorialStepBigPictureBody,
        headerIcon: Icons.calendar_month,
        tooltipPosition: TooltipPosition.above,
        spotlightShape: SpotlightShape.roundedRect,
        spotlightPadding: 4,
        callouts: [
          TutorialCallout(
            icon: Icons.view_day,
            label: l10n.tutorialCalloutDaily,
            description: l10n.tutorialCalloutDailyDesc,
          ),
          TutorialCallout(
            icon: Icons.view_week,
            label: l10n.tutorialCalloutWeekly,
            description: l10n.tutorialCalloutWeeklyDesc,
          ),
          TutorialCallout(
            icon: Icons.calendar_view_month,
            label: l10n.tutorialCalloutMonthly,
            description: l10n.tutorialCalloutMonthlyDesc,
          ),
        ],
      ),

      // Step 7: Bottom Nav — Share, Search, Settings
      TutorialStep(
        id: 'bottom_nav_tools',
        targetKey: TutorialKeys.bottomNavKey,
        title: l10n.tutorialStepToolkitTitle,
        body: l10n.tutorialStepToolkitBody,
        headerIcon: Icons.dashboard,
        tooltipPosition: TooltipPosition.above,
        spotlightShape: SpotlightShape.roundedRect,
        spotlightPadding: 4,
        callouts: [
          TutorialCallout(
            icon: Icons.share,
            label: l10n.tutorialCalloutShare,
            description: l10n.tutorialCalloutShareDesc,
          ),
          TutorialCallout(
            icon: Icons.search,
            label: l10n.tutorialCalloutSearch,
            description: l10n.tutorialCalloutSearchDesc,
          ),
          TutorialCallout(
            icon: Icons.settings,
            label: l10n.tutorialCalloutSettings,
            description: l10n.tutorialCalloutSettingsDesc,
          ),
        ],
      ),
    ];
  }

  /// Finds the Rect of the target widget on screen using its GlobalKey.
  Rect? _getTargetRect(GlobalKey? key) {
    if (key == null) return null;
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final offset = renderObject.localToGlobal(Offset.zero);
      return offset & renderObject.size;
    }
    return null;
  }

  /// Computes the position of the tooltip relative to the target.
  /// Ensures the tooltip never overlaps the spotlight cutout.
  Offset _computeTooltipOffset(
    Rect? targetRect,
    TooltipPosition position,
    Size screenSize,
  ) {
    if (targetRect == null || position == TooltipPosition.center) {
      return Offset(0, screenSize.height * 0.2);
    }

    const double tooltipMargin = 16.0;
    const double estimatedTooltipHeight = 320.0;
    const double minTopPadding = 40.0;

    final double cutoutTop = targetRect.top -
        (position == TooltipPosition.above || position == TooltipPosition.below
            ? 8
            : 0);
    final double cutoutBottom =
        targetRect.bottom + 8; // account for spotlightPadding
    final double spaceAbove = cutoutTop - minTopPadding;
    final double spaceBelow = screenSize.height - cutoutBottom;

    if (position == TooltipPosition.above) {
      // Try above first
      if (spaceAbove >= estimatedTooltipHeight) {
        double top = cutoutTop - tooltipMargin - estimatedTooltipHeight;
        if (top < minTopPadding) top = minTopPadding;
        return Offset(0, top);
      }
      // Fall back to below if not enough room above
      double top = cutoutBottom + tooltipMargin;
      return Offset(0, top);
    } else {
      // Below — try below first
      if (spaceBelow >= estimatedTooltipHeight + tooltipMargin) {
        double top = cutoutBottom + tooltipMargin;
        return Offset(0, top);
      }
      // Fall back to above if not enough room below
      if (spaceAbove >= estimatedTooltipHeight) {
        double top = cutoutTop - tooltipMargin - estimatedTooltipHeight;
        if (top < minTopPadding) top = minTopPadding;
        return Offset(0, top);
      }
      // Neither side fits well — place at top of screen
      return Offset(0, minTopPadding);
    }
  }

  /// Opens the real add-tile sheet via the callback.
  void _showAddTileSheet() {
    if (widget.onShowAddTileSheet == null || _addTileSheetShowing) return;
    _addTileSheetShowing = true;
    final tutorialBloc = context.read<TutorialBloc>();
    widget.onShowAddTileSheet!(tutorialBloc).whenComplete(() {
      _addTileSheetShowing = false;
      // If tutorial is still on the quick_add step when the sheet is dismissed
      // (e.g. the user tapped the barrier), auto-advance to the next step.
      if (mounted) {
        final tutorialState = context.read<TutorialBloc>().state;
        if (tutorialState.isActive &&
            tutorialState.currentStepIndex < _steps.length &&
            _steps[tutorialState.currentStepIndex].id == 'quick_add') {
          context.read<TutorialBloc>().add(NextTutorialStepEvent());
        }
      }
    });
  }

  /// Dismisses the real add-tile sheet if it's showing.
  void _dismissAddTileSheet() {
    if (_addTileSheetShowing) {
      widget.onDismissAddTileSheet?.call();
      _addTileSheetShowing = false;
    }
  }

  /// Fires onExit for the old step, onEnter for the new step.
  /// Also handles showing / dismissing the add-tile sheet for the quick_add step.
  /// Steps that should keep the add-tile sheet visible.
  static const _sheetSteps = {'quick_add', 'smart_scheduling'};

  void _handleStepTransition(int oldIndex, int newIndex) {
    final oldId = oldIndex < _steps.length ? _steps[oldIndex].id : '';
    final newId = newIndex < _steps.length ? _steps[newIndex].id : '';

    // Exit old step
    if (oldIndex < _steps.length) {
      _steps[oldIndex].onExit?.call(context);
      // Dismiss sheet only when leaving a sheet-step for a non-sheet-step
      if (_sheetSteps.contains(oldId) && !_sheetSteps.contains(newId)) {
        _dismissAddTileSheet();
      }
    }
    // Enter new step
    if (newIndex < _steps.length) {
      _steps[newIndex].onEnter?.call(context);
      // Open the sheet when entering a sheet-step from a non-sheet-step
      if (_sheetSteps.contains(newId) && !_sheetSteps.contains(oldId)) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) _showAddTileSheet();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TutorialBloc, TutorialState>(
      listener: (context, state) {
        if (state.isActive) {
          _animationController.forward();

          // Inject dummy tiles the first time the tutorial becomes active
          // so new users see a populated schedule.
          if (!_dummyTilesInjected) {
            _dummyTilesInjected = true;
            TutorialDummyData.injectDummyTiles(context);
          }

          // Detect step transitions
          if (_previousStepIndex != state.currentStepIndex) {
            _handleStepTransition(_previousStepIndex, state.currentStepIndex);
            _previousStepIndex = state.currentStepIndex;
          }
        } else if (state.status == TutorialStatus.completed ||
            state.status == TutorialStatus.skipped) {
          // Fire onExit for whatever step was active when tutorial ended
          if (_previousStepIndex < _steps.length) {
            _steps[_previousStepIndex].onExit?.call(context);
            // Dismiss the sheet if it's showing
            if (_steps[_previousStepIndex].id == 'quick_add') {
              _dismissAddTileSheet();
            }
          }

          // Restore the real schedule now that the tutorial is done.
          if (_dummyTilesInjected) {
            _dummyTilesInjected = false;
            TutorialDummyData.restoreRealSchedule(context);
          }

          _animationController.reverse();
          _previousStepIndex = 0;
        }
      },
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.currentStepIndex != current.currentStepIndex,
      builder: (context, state) {
        if (!state.isActive) {
          return widget.child;
        }

        final currentStep = _steps[state.currentStepIndex];

        // Don't render the tutorial overlay on step 3 (quick_add)
        // because the real modal bottom sheet is shown above everything.
        // The tooltip is embedded in the modal itself.
        final bool hideOverlay = currentStep.id == 'quick_add';

        return Stack(
          children: [
            // The actual app content underneath
            widget.child,

            if (!hideOverlay)
              // Overlay layer with spotlight + tooltip
              _TutorialOverlayLayer(
                fadeAnimation: _fadeAnimation,
                currentStep: currentStep,
                state: state,
                getTargetRect: _getTargetRect,
                computeTooltipOffset: _computeTooltipOffset,
              ),
          ],
        );
      },
    );
  }
}

/// Separate widget for the overlay layer so it can properly resolve
/// GlobalKey positions after layout.
class _TutorialOverlayLayer extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final TutorialStep currentStep;
  final TutorialState state;
  final Rect? Function(GlobalKey?) getTargetRect;
  final Offset Function(Rect?, TooltipPosition, Size) computeTooltipOffset;

  const _TutorialOverlayLayer({
    required this.fadeAnimation,
    required this.currentStep,
    required this.state,
    required this.getTargetRect,
    required this.computeTooltipOffset,
  });

  @override
  State<_TutorialOverlayLayer> createState() => _TutorialOverlayLayerState();
}

class _TutorialOverlayLayerState extends State<_TutorialOverlayLayer> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _resolveTargetRect();
  }

  @override
  void didUpdateWidget(covariant _TutorialOverlayLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep.id != widget.currentStep.id) {
      _resolveTargetRect();
    }
  }

  void _resolveTargetRect() {
    // Schedule after the frame so GlobalKeys have valid RenderObjects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _targetRect = widget.getTargetRect(widget.currentStep.targetKey);
        });
      }
    });
  }

  /// Computes the bottom constraint for the tooltip so it never overlaps
  /// the spotlight cutout. Returns null when no constraint is needed.
  double? _getTooltipBottom(
    Rect? targetRect,
    double tooltipTop,
    TooltipPosition position,
    Size screenSize,
  ) {
    if (targetRect == null) return null;

    const double padding = 8.0; // spotlightPadding allowance

    if (position == TooltipPosition.above || tooltipTop < targetRect.top) {
      // Tooltip is above the cutout — constrain its bottom edge
      // so it doesn't extend into the cutout.
      final bottomLimit = screenSize.height - (targetRect.top - padding);
      return bottomLimit > 0 ? bottomLimit : null;
    }

    // Tooltip is below the cutout — let it extend to screen bottom.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipOffset = widget.computeTooltipOffset(
      _targetRect,
      widget.currentStep.tooltipPosition,
      screenSize,
    );

    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        // Steps handled by dialog-on-dialog (shown over the sheet)
        // don't need the overlay tooltip — it would be hidden behind the sheet.
        final isSheetStep =
            _TutorialOverlayState._sheetSteps.contains(widget.currentStep.id);

        return Stack(
          children: [
            // Spotlight overlay — absorbs taps
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Don't advance via tap during sheet steps — dialogs handle it
                  if (!isSheetStep) {
                    context.read<TutorialBloc>().add(NextTutorialStepEvent());
                  }
                },
                child: CustomPaint(
                  painter: TutorialSpotlightPainter(
                    targetRect: isSheetStep ? null : _targetRect,
                    padding: widget.currentStep.spotlightPadding,
                    shape: widget.currentStep.spotlightShape,
                    animationValue: widget.fadeAnimation.value,
                  ),
                ),
              ),
            ),

            // Tooltip card — hidden for sheet steps (dialog-on-dialog handles those)
            if (!isSheetStep)
              Positioned(
                left: 0,
                right: 0,
                top: tooltipOffset.dy,
                bottom: _getTooltipBottom(
                  _targetRect,
                  tooltipOffset.dy,
                  widget.currentStep.tooltipPosition,
                  screenSize,
                ),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: TutorialTooltipWidget(
                      step: widget.currentStep,
                      currentStepIndex: widget.state.currentStepIndex,
                      totalSteps: widget.state.totalSteps,
                      onNext: () => context
                          .read<TutorialBloc>()
                          .add(NextTutorialStepEvent()),
                      onPrevious: () => context
                          .read<TutorialBloc>()
                          .add(PreviousTutorialStepEvent()),
                      onSkip: () =>
                          context.read<TutorialBloc>().add(SkipTutorialEvent()),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
