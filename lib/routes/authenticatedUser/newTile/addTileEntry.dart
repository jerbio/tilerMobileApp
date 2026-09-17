// Add Tile — Step 5.2: the one entry point (D65).
//
// Every place that opens Add Tile goes through `AddTileEntry`: the `/AddTile`
// route, and the two sites that used to construct the legacy screen
// directly. It renders the redesign when `AddTileFeatureFlags` says so and
// the legacy `AddTile` otherwise, so one flag governs every entry point and
// a rollback is a flag flip, not a code change.
//
// The redesign's production wiring lives in ONE function,
// `buildAddTileRedesign`, shared with the direct `/AddTileRedesign` route in
// `main.dart` — a second copy of the API wiring would drift.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePredictionSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileSubmission.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';

/// What a push site handed over, in one shape.
///
/// The sites disagree on how to say "prefill" and "result slot":
///
///   * the preview sheet pushes a bare [PreTile];
///   * the empty-day and forecast-preview sites push a `{newTile}` map the
///     created tile is written back into;
///   * the Edit Tile suggestions push that map with a `preTile` inside it;
///   * the free-slot and auto-tile sites construct the screen with a
///     `preTile` and an `autoDeadline`.
///
/// Both screens read from here, so they cannot disagree about a prefill.
class AddTileRouteArgs {
  const AddTileRouteArgs({this.preTile, this.newTileParams, this.autoDeadline});

  final PreTile? preTile;

  /// The legacy result slot, kept by identity: the caller reads the created
  /// tile back out of the very map it pushed.
  final Map<String, dynamic>? newTileParams;

  /// Legacy `AddTile` takes the deadline beside the prefill; kept for it.
  final DateTime? autoDeadline;

  /// Folds route [arguments] and constructor [preTile] / [autoDeadline].
  ///
  /// [autoDeadline] becomes the prefill's `endTime`, which is where the
  /// redesign reads a deadline from. The caller's [PreTile] is never
  /// mutated: a copy carries the fold.
  static AddTileRouteArgs from(
    Object? arguments, {
    PreTile? preTile,
    DateTime? autoDeadline,
  }) {
    final Map<String, dynamic>? slot =
        arguments is Map<String, dynamic> ? arguments : null;
    final Object? fromRoute =
        arguments is PreTile ? arguments : slot?['preTile'];
    final PreTile? source =
        preTile ?? (fromRoute is PreTile ? fromRoute : null);

    PreTile? folded = source;
    if (autoDeadline != null && source?.endTime != autoDeadline) {
      folded = SimpleAdditionTile(
        description: source?.description,
        duration: source?.duration,
        location: source?.location,
        endTime: autoDeadline,
      )..startTime = source?.startTime;
    }

    return AddTileRouteArgs(
      preTile: folded,
      newTileParams: slot,
      autoDeadline: autoDeadline,
    );
  }
}

typedef AddTileRedesignBuilder = Widget Function(
    BuildContext context, AddTileRouteArgs args);
typedef AddTileLegacyBuilder = Widget Function(
    BuildContext context, AddTileRouteArgs args);

/// The redesigned screen with its production wiring.
Widget buildAddTileRedesign(BuildContext context, AddTileRouteArgs args) {
  final ScheduleApi scheduleApi =
      ScheduleApi(getContextCallBack: () => context);
  return AddTileRedesignScreen(
    preTile: args.preTile,
    locationSource: ApiAddTileLocationSource(
      locationApi: LocationApi(getContextCallBack: () => context),
    ),
    predictionSource: ApiAddTilePredictionSource(scheduleApi: scheduleApi),
    submission: ApiAddTileSubmission(scheduleApi: scheduleApi),
    newTileParams: args.newTileParams,
  );
}

/// The legacy screen. It reads its result slot from the route itself.
Widget buildAddTileLegacy(BuildContext context, AddTileRouteArgs args) =>
    AddTile(preTile: args.preTile, autoDeadline: args.autoDeadline);

/// The legacy screen's result slot, read tolerantly.
///
/// `AddTile.build` cast `settings.arguments as Map?`; with the preview sheet
/// now pushing a bare [PreTile] through `/AddTile`, that cast threw whenever
/// the flag was off.
Map? readLegacyResultSlot(Object? arguments) =>
    arguments is Map ? arguments : null;

class AddTileEntry extends StatelessWidget {
  const AddTileEntry({
    super.key,
    this.preTile,
    this.autoDeadline,
    this.redesignBuilder = buildAddTileRedesign,
    this.legacyBuilder = buildAddTileLegacy,
  });

  /// Constructor-time prefill, for sites that push a `MaterialPageRoute`
  /// rather than the named route.
  final PreTile? preTile;
  final DateTime? autoDeadline;

  /// Test seams; production uses the defaults.
  final AddTileRedesignBuilder redesignBuilder;
  final AddTileLegacyBuilder legacyBuilder;

  @override
  Widget build(BuildContext context) {
    final AddTileRouteArgs args = AddTileRouteArgs.from(
      ModalRoute.of(context)?.settings.arguments,
      preTile: preTile,
      autoDeadline: autoDeadline,
    );
    if (!AddTileFeatureFlags.addTileRedesignEnabled) {
      return legacyBuilder(context, args);
    }
    return redesignBuilder(context, args);
  }
}
