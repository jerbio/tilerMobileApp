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
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

/// The number of steps in the onboarding tour.
///
/// This MUST stay in sync with the list returned by [buildTutorialSteps].
/// It is the single source of truth used by `TutorialBloc(stepCount:)` and the
/// step-counter fallbacks in `AuthorizedRoute`. The onboarding sync tests assert
/// `buildTutorialSteps(context).length == kTutorialStepCount`.
const int kTutorialStepCount = 8;

/// Builds the ordered list of onboarding tour steps.
///
/// Exposed at the top level (rather than being buried in the overlay state) so
/// tests can verify that every step still points at a live UI target and that
/// the tour hasn't drifted from the actual home-screen buttons.
List<TutorialStep> buildTutorialSteps(BuildContext context) {
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

    // Step 2: The centre Tiler logo — Create a Tile
    TutorialStep(
      id: 'add_tile_button',
      targetKey: TutorialKeys.bottomNavAddTileKey,
      title: l10n.tutorialStepCreateOptimizeTitle,
      body: l10n.tutorialStepCreateOptimizeBody,
      headerIcon: Icons.add_circle_outline,
      tooltipPosition: TooltipPosition.above,
      spotlightShape: SpotlightShape.circle,
      spotlightPadding: 6,
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
    // Callouts mirror the real add-tile sheet action row:
    // Shuffle · Defer All · Options (see PreviewAddWidget.renderModal).
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
          icon: Icons.shuffle,
          label: l10n.tutorialCalloutShuffle,
          description: l10n.tutorialCalloutShuffleDesc,
        ),
        TutorialCallout(
          icon: Icons.fast_forward,
          label: l10n.tutorialCalloutDeferAll,
          description: l10n.tutorialCalloutDeferAllDesc,
        ),
        TutorialCallout(
          icon: Icons.more_time,
          label: l10n.tutorialCalloutMoreOptions,
          description: l10n.tutorialCalloutMoreOptionsSheetDesc,
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
      headerIcon: Icons.calendar_view_month,
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

    // Step 7: Top-right tools — Search & Settings
    TutorialStep(
      id: 'quick_tools',
      targetKey: TutorialKeys.topRightActionsKey,
      title: l10n.tutorialStepToolkitTitle,
      body: l10n.tutorialStepToolkitBody,
      headerIcon: Icons.dashboard,
      tooltipPosition: TooltipPosition.below,
      spotlightShape: SpotlightShape.roundedRect,
      spotlightPadding: 6,
      callouts: [
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

    // Step 8: The Chat FAB — talk to Tiler
    TutorialStep(
      id: 'chat_fab',
      targetKey: TutorialKeys.fabKey,
      title: l10n.tutorialStepChatTitle,
      body: l10n.tutorialStepChatBody,
      // The chat FAB renders Icons.auto_awesome (HomeFab) — the step icon
      // must track the live FAB icon (see onboarding sync tests).
      headerIcon: Icons.auto_awesome,
      tooltipPosition: TooltipPosition.above,
      spotlightShape: SpotlightShape.circle,
      spotlightPadding: 6,
    ),
  ];
}

/// The main tutorial overlay. Renders on top of the surface hosting the
/// tour, reads the current step from [TutorialBloc], highlights the target
/// widget, and shows a tooltip with instructions.
///
/// Generalized per tour (product-tour-onboarding-redesign.md, Phase 1):
/// [stepsBuilder] supplies any tour's steps (defaults to the home tour), and
/// home-specific side effects (dummy-tile injection) only run when
/// [tourId] is the home tour.
class TutorialOverlay extends StatefulWidget {
  final Widget child;

  /// The tour id this overlay is rendering.
  final String tourId;

  /// Builds the ordered list of steps for [tourId]. Defaults to the home
  /// tour steps.
  final List<TutorialStep> Function(BuildContext context) stepsBuilder;

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
    this.tourId = TourPreferencesHelper.homeTourId,
    this.stepsBuilder = buildTutorialSteps,
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

  List<TutorialStep> _buildSteps(BuildContext context) =>
      widget.stepsBuilder(context);

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

          // Inject dummy tiles the first time the home tutorial becomes
          // active so new users see a populated schedule. Home-specific:
          // other tours must not mutate the schedule.
          if (widget.tourId == TourPreferencesHelper.homeTourId &&
              !_dummyTilesInjected) {
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
            // Dismiss the sheet if it's showing (could be on any sheet step)
            if (_sheetSteps.contains(_steps[_previousStepIndex].id)) {
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
        final TutorialStep? currentStep =
            state.isActive ? _steps[state.currentStepIndex] : null;

        // Don't render the tutorial overlay on step 3 (quick_add)
        // because the real modal bottom sheet is shown above everything.
        // The tooltip is embedded in the modal itself.
        final bool showOverlay =
            currentStep != null && currentStep.id != 'quick_add';

        // The surface always lives at the same spot in the tree — under
        // this Stack — whether or not the overlay is showing. Returning
        // `widget.child` bare while inactive and wrapping it in a Stack
        // once active changes the tree shape, which remounts the whole
        // surface when the tour starts and again when it ends: a page
        // that creates its bloc and fetches on mount (Tile Preferences)
        // loaded twice.
        return Stack(
          children: [
            // The actual app content underneath
            widget.child,

            if (showOverlay)
              // Overlay layer with spotlight + tooltip
              _TutorialOverlayLayer(
                fadeAnimation: _fadeAnimation,
                currentStep: currentStep,
                state: state,
                getTargetRect: _getTargetRect,
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

  const _TutorialOverlayLayer({
    required this.fadeAnimation,
    required this.currentStep,
    required this.state,
    required this.getTargetRect,
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
      if (!mounted) return;
      final key = widget.currentStep.targetKey;
      if (_scrollTargetIntoView(key)) {
        // The enclosing scrollable jumped, which scheduled a layout frame;
        // the anchor's global rect is only correct after it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _targetRect = widget.getTargetRect(key));
          }
        });
        return;
      }
      setState(() => _targetRect = widget.getTargetRect(key));
    });
  }

  /// Scrolls the step's anchor into its enclosing scrollable, moving the
  /// minimum needed (a fully visible anchor never moves — home-tour parity).
  /// Returns true if a scroll position actually changed.
  bool _scrollTargetIntoView(GlobalKey? key) {
    final targetContext = key?.currentContext;
    if (targetContext == null) return false;
    final scrollable = Scrollable.maybeOf(targetContext);
    if (scrollable == null || !scrollable.position.hasPixels) return false;
    final before = scrollable.position.pixels;
    // Forward only if the trailing edge is past the viewport end, then
    // backward only if the leading edge is before the viewport start.
    Scrollable.ensureVisible(
      targetContext,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    Scrollable.ensureVisible(
      targetContext,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    return scrollable.position.pixels != before;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final slot = computeTooltipSlot(
      _targetRect,
      widget.currentStep.tooltipPosition,
      screenSize,
      cutoutPadding: widget.currentStep.spotlightPadding,
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
                top: slot.top,
                bottom: slot.bottom,
                child: Align(
                  alignment: slot.alignment,
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

/// The vertical band the tooltip card is laid out in, and where it sits
/// inside that band.
///
/// The band is always bounded (top and bottom) so the card can only ever be
/// as tall as the space it was given: [TutorialTooltipWidget] pins its
/// header and footer and scrolls its body, so a tight band shrinks the card
/// instead of overflowing it.
class TooltipSlot {
  final double top;
  final double bottom;

  /// `bottomCenter` when the card hugs a cutout from above, `topCenter`
  /// when it hugs one from below, `center` when floating.
  final Alignment alignment;

  const TooltipSlot({
    required this.top,
    required this.bottom,
    required this.alignment,
  });
}

/// The smallest band in which the tooltip card is still usable: pinned
/// header + step dots + nav row plus a couple of body lines.
const double kTooltipMinUsableHeight = 200.0;

/// Picks the band the tooltip card is laid out in relative to the spotlight
/// cutout around [targetRect].
///
/// Honours [position] when that side can hold a usable card; otherwise takes
/// whichever side has more room. When neither side can hold a usable card
/// (a tall anchor on a short screen) the card floats over the full screen
/// and overlaps the spotlight — a legible card over the cutout beats an
/// overflowed one beside it. Exposed at the top level so the placement rule
/// can be unit-tested without rendering the overlay.
TooltipSlot computeTooltipSlot(
  Rect? targetRect,
  TooltipPosition position,
  Size screenSize, {
  double cutoutPadding = 8.0,
}) {
  const double tooltipMargin = 16.0;
  const double minTopPadding = 40.0;
  const double bottomMargin = 16.0;

  if (targetRect == null || position == TooltipPosition.center) {
    return TooltipSlot(
      top: screenSize.height * 0.2,
      bottom: bottomMargin,
      alignment: Alignment.topCenter,
    );
  }

  final double cutoutTop = targetRect.top - cutoutPadding;
  final double cutoutBottom = targetRect.bottom + cutoutPadding;
  final double spaceAbove = (cutoutTop - tooltipMargin) - minTopPadding;
  final double spaceBelow =
      (screenSize.height - bottomMargin) - (cutoutBottom + tooltipMargin);

  final bool preferredUsable = position == TooltipPosition.above
      ? spaceAbove >= kTooltipMinUsableHeight
      : spaceBelow >= kTooltipMinUsableHeight;
  final bool above = preferredUsable
      ? position == TooltipPosition.above
      : spaceAbove > spaceBelow;

  if (above && spaceAbove >= kTooltipMinUsableHeight) {
    return TooltipSlot(
      top: minTopPadding,
      bottom: screenSize.height - (cutoutTop - tooltipMargin),
      alignment: Alignment.bottomCenter,
    );
  }
  if (!above && spaceBelow >= kTooltipMinUsableHeight) {
    return TooltipSlot(
      top: cutoutBottom + tooltipMargin,
      bottom: bottomMargin,
      alignment: Alignment.topCenter,
    );
  }
  // Neither side can hold a usable card: overlap the spotlight.
  return TooltipSlot(
    top: minTopPadding,
    bottom: bottomMargin,
    alignment: Alignment.center,
  );
}
