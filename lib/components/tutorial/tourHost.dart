import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_state.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';
import 'package:tiler_app/util.dart';

/// Hosts one product tour on a surface
/// (product-tour-onboarding-redesign.md, Phase 1).
///
/// Extracted from `AuthorizedRoute`'s `_TutorialWrapper` and generalized per
/// tour. Start decision pipeline:
///   1. per-tour completion check ([TourPreferencesHelper] — applies the
///      legacy `hasCompletedAppTutorial` migration for the home tour);
///   2. post-frame settle delay so the surface renders first;
///   3. optional anchor readiness gate ([anchorReadyTimeout]) for surfaces
///      that mount their anchors asynchronously (e.g. behind a network
///      fetch): the host polls until step 1's target key is mounted, then
///      leaves the loaded surface undimmed for [anchorSettleDelay];
///   4. one-tour-at-a-time guard ([TourCoordinator]);
///   5. [StartTutorialEvent] on the per-tour [TutorialBloc].
///
/// A tour blocked from starting — by the coordinator or by anchors that
/// never appear before [anchorReadyTimeout] — is never marked complete; it
/// retries on the next surface visit (a fresh mount of this host). The host owns the
/// [TutorialBloc] provider so [TutorialOverlay] (and any child) can read it
/// from context, and releases the coordinator when the tour completes or is
/// skipped.
class TourHost extends StatefulWidget {
  /// Which tour this host drives (e.g. `home`, `settings`).
  final String tourId;

  /// Number of steps the tour has (drives the [TutorialBloc]).
  final int stepCount;

  /// Delay before starting the tour, letting the surface render first.
  final Duration settleDelay;

  /// When non-null, the host polls every [anchorPollInterval] from mount
  /// until the first step's `targetKey` is mounted, then starts the tour
  /// once both [settleDelay] (from mount) and [anchorSettleDelay] (from the
  /// anchor appearing) have elapsed. It gives up this long after
  /// [settleDelay] if the anchor never appears. Use it on surfaces whose
  /// anchors render asynchronously (a page that shows a pending widget
  /// until its data loads); a timer-only start would spotlight nothing.
  ///
  /// `null` (the default) keeps the timer-only start: the tour begins right
  /// after [settleDelay], which is what synchronously-rendered surfaces
  /// (home, settings) rely on.
  final Duration? anchorReadyTimeout;

  /// How often the readiness gate re-checks the first anchor.
  final Duration anchorPollInterval;

  /// Readiness gate only: how long the freshly loaded surface stays
  /// undimmed after its first anchor appears. Starting on the frame the
  /// pending widget disappears reads as "the tour began before the page
  /// loaded", so the user gets a beat to see the page first.
  final Duration anchorSettleDelay;

  final Widget child;

  /// Builds the ordered list of steps for [tourId]. Defaults to the home
  /// tour steps and is passed through to [TutorialOverlay] unchanged, so
  /// any tour (e.g. the settings tour) can supply its own steps while the
  /// existing home-tour wiring keeps working without changes.
  final List<TutorialStep> Function(BuildContext context) stepsBuilder;

  const TourHost({
    Key? key,
    required this.tourId,
    required this.stepCount,
    required this.child,
    this.settleDelay = const Duration(milliseconds: 1200),
    this.anchorReadyTimeout,
    this.anchorPollInterval = const Duration(milliseconds: 100),
    this.anchorSettleDelay = const Duration(milliseconds: 800),
    this.stepsBuilder = buildTutorialSteps,
  }) : super(key: key);

  @override
  State<TourHost> createState() => _TourHostState();
}

class _TourHostState extends State<TourHost> {
  late final TutorialBloc _tourBloc;

  @override
  void initState() {
    super.initState();
    _tourBloc =
        TutorialBloc(stepCount: widget.stepCount, tourId: widget.tourId);
    _checkAndStartTour();
  }

  @override
  void dispose() {
    TourCoordinator.instance.release(widget.tourId);
    _tourBloc.close();
    super.dispose();
  }

  void _checkAndStartTour() {
    TourPreferencesHelper.hasCompletedTour(widget.tourId).then((completed) {
      if (completed || !mounted) return;
      if (widget.anchorReadyTimeout == null) {
        // Timer-only start: delay to let the surface render first.
        Future.delayed(widget.settleDelay, () {
          if (mounted) _requestStart();
        });
        return;
      }
      _pollForAnchor(Duration.zero);
    });
  }

  /// Readiness gate: polls until step 1's anchor is mounted, then holds
  /// the loaded surface undimmed for [TourHost.anchorSettleDelay] (never
  /// starting before [TourHost.settleDelay] from mount either). [waited]
  /// is how long since the host mounted.
  void _pollForAnchor(Duration waited) {
    if (!mounted) return;
    if (_firstAnchorMounted()) {
      final Duration remainingSettle = widget.settleDelay - waited;
      final Duration beat = remainingSettle > widget.anchorSettleDelay
          ? remainingSettle
          : widget.anchorSettleDelay;
      Future.delayed(beat, () {
        if (!mounted) return;
        // The surface may have changed under us (e.g. an error state
        // replaced the cards): only start if the anchor is still there,
        // otherwise keep waiting for it.
        if (_firstAnchorMounted()) {
          _requestStart();
        } else {
          _pollForAnchor(waited + beat);
        }
      });
      return;
    }
    if (waited >= widget.settleDelay + widget.anchorReadyTimeout!) {
      // Give up for this visit. Not marked complete — the tour retries on
      // the next surface visit.
      Utility.debugPrint(
          'TourHost(${widget.tourId}): first anchor never mounted within '
          '${widget.anchorReadyTimeout!.inMilliseconds}ms after the settle '
          'delay; not starting this visit');
      return;
    }
    Future.delayed(widget.anchorPollInterval, () {
      _pollForAnchor(waited + widget.anchorPollInterval);
    });
  }

  /// One tour at a time. A blocked tour is not marked complete — it
  /// retries on the next surface visit.
  void _requestStart() {
    if (TourCoordinator.instance.requestStart(widget.tourId)) {
      _tourBloc.add(StartTutorialEvent());
    }
  }

  /// True when step 1 can be spotlighted: its target key has a mounted
  /// context, or it is a full-screen step with no target at all.
  bool _firstAnchorMounted() {
    final steps = widget.stepsBuilder(context);
    if (steps.isEmpty) return false;
    final key = steps.first.targetKey;
    return key == null || key.currentContext != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TutorialBloc>(
      create: (context) => _tourBloc,
      child: BlocListener<TutorialBloc, TutorialState>(
        listener: (context, state) {
          if (state.isCompleted || state.status == TutorialStatus.skipped) {
            TourCoordinator.instance.release(widget.tourId);
          }
        },
        child: TutorialOverlay(
          tourId: widget.tourId,
          stepsBuilder: widget.stepsBuilder,
          child: widget.child,
        ),
      ),
    );
  }
}
