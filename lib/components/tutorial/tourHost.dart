import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_state.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

/// Hosts one product tour on a surface
/// (product-tour-onboarding-redesign.md, Phase 1).
///
/// Extracted from `AuthorizedRoute`'s `_TutorialWrapper` and generalized per
/// tour. Start decision pipeline:
///   1. per-tour completion check ([TourPreferencesHelper] — applies the
///      legacy `hasCompletedAppTutorial` migration for the home tour);
///   2. post-frame settle delay so the surface renders first;
///   3. one-tour-at-a-time guard ([TourCoordinator]);
///   4. [StartTutorialEvent] on the per-tour [TutorialBloc].
///
/// A tour blocked from starting is never marked complete; it retries on the
/// next surface visit (a fresh mount of this host). The host owns the
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

  final Widget child;

  /// Home-tour only: opens the real add-tile bottom sheet during the tour.
  /// Receives the [TutorialBloc] so the dialog shown on top of the sheet can
  /// advance / go back. Returns a Future that completes when the sheet is
  /// dismissed.
  final Future<void> Function(TutorialBloc bloc)? onShowAddTileSheet;

  /// Home-tour only: dismisses the add-tile sheet if it is currently showing.
  final VoidCallback? onDismissAddTileSheet;

  const TourHost({
    Key? key,
    required this.tourId,
    required this.stepCount,
    required this.child,
    this.settleDelay = const Duration(milliseconds: 1200),
    this.onShowAddTileSheet,
    this.onDismissAddTileSheet,
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
    _tourBloc.close();
    super.dispose();
  }

  void _checkAndStartTour() {
    TourPreferencesHelper.hasCompletedTour(widget.tourId).then((completed) {
      if (completed || !mounted) return;
      // Delay to let the surface render first.
      Future.delayed(widget.settleDelay, () {
        if (!mounted) return;
        // One tour at a time. A blocked tour is not marked complete — it
        // retries on the next surface visit.
        if (TourCoordinator.instance.requestStart(widget.tourId)) {
          _tourBloc.add(StartTutorialEvent());
        }
      });
    });
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
          onShowAddTileSheet: widget.onShowAddTileSheet,
          onDismissAddTileSheet: widget.onDismissAddTileSheet,
          child: widget.child,
        ),
      ),
    );
  }
}
