// Add Tile — the one entry point (Step 5.2, D65; legacy removed in 5.3, D66).
//
// Every place that opens Add Tile goes through `AddTileEntry`: the `/AddTile`
// route, and the two sites that push a `MaterialPageRoute` with a prefill.
// Until 5.3 it chose between the legacy `AddTile` and the redesign by a
// flag; the legacy screen is gone and the entry is unconditional — kept so
// the push sites keep one API and one argument shape.
//
// The redesign's production wiring lives in ONE function,
// `buildAddTileRedesign` — a second copy of the API wiring would drift.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
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
///   * the free-slot and auto-tile sites construct the entry with a
///     `preTile` and an `autoDeadline`.
class AddTileRouteArgs {
  const AddTileRouteArgs({this.preTile, this.newTileParams});

  final PreTile? preTile;

  /// The legacy result slot, kept by identity: the caller reads the created
  /// tile back out of the very map it pushed.
  final Map<String, dynamic>? newTileParams;

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

    return AddTileRouteArgs(preTile: folded, newTileParams: slot);
  }
}

typedef AddTileRedesignBuilder = Widget Function(
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

class AddTileEntry extends StatelessWidget {
  const AddTileEntry({
    super.key,
    this.preTile,
    this.autoDeadline,
    this.redesignBuilder = buildAddTileRedesign,
  });

  /// Constructor-time prefill, for sites that push a `MaterialPageRoute`
  /// rather than the named route.
  final PreTile? preTile;
  final DateTime? autoDeadline;

  /// Test seam; production uses the default.
  final AddTileRedesignBuilder redesignBuilder;

  @override
  Widget build(BuildContext context) {
    final AddTileRouteArgs args = AddTileRouteArgs.from(
      ModalRoute.of(context)?.settings.arguments,
      preTile: preTile,
      autoDeadline: autoDeadline,
    );
    return redesignBuilder(context, args);
  }
}
