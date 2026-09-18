// Tile Detail redesign — Step 6.6: the ONE production wiring of the
// redesigned screen, and the drop-in route for the legacy push sites.
//
// D25: Edit Tile and Tile Detail shipped together behind ONE flag; 5.4
// deleted both legacy screens and the flag. Every push site goes through
// `TileDetailRoute`, now unconditional.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/services/api/locationApi.dart';

/// Builds the redesigned Tile Detail for [calendarEventId] with the real
/// APIs and the bloc-backed schedule refresher. Every entry point uses this.
Widget buildTileDetailRedesign(BuildContext context, TileDetailTarget target) {
  final CalendarEventApi calendarEventApi =
      CalendarEventApi(getContextCallBack: () => context);
  return TileDetailRedesignScreen(
    calendarEventId: target.calendarEventId,
    designatedTileTemplateId: target.designatedTileTemplateId,
    loader: ApiTileDetailLoader(
      calendarEventApi: calendarEventApi,
      locationApi: LocationApi(getContextCallBack: () => context),
    ),
    submission: ApiTileDetailSubmission(
      calendarEventApi: calendarEventApi,
      refresher: BlocEditTileScheduleRefresher(
        scheduleBloc: context.read<ScheduleBloc>(),
        scheduleSummaryBloc: context.read<ScheduleSummaryBloc>(),
      ),
    ),
    occurrences: ApiTileDetailOccurrences(calendarEventApi: calendarEventApi),
    locationSource: ApiAddTileLocationSource(
        locationApi: LocationApi(getContextCallBack: () => context)),
  );
}

/// Pushes the redesigned Tile Detail. The blocs are read from the PUSHING
/// context (the route's own builder context sits above the providers only
/// when the app wires them at the root, which it does — but reading them
/// here keeps the dependency explicit).
Future<Object?> pushTileDetailRedesign(
        BuildContext context, String calendarEventId) =>
    Navigator.of(context).push<Object?>(MaterialPageRoute<Object?>(
      builder: (BuildContext routeContext) => buildTileDetailRedesign(
          routeContext, TileDetailTarget.calendarEvent(calendarEventId)),
    ));

typedef TileDetailRedesignBuilder = Widget Function(
    BuildContext context, TileDetailTarget target);

/// The one way to open Tile details, with the arguments the legacy
/// `TileDetail(tileId:, loadSubEvents:)` took (5.4: the legacy screen is
/// gone; the route stays so the push sites keep one API). `loadSubEvents`
/// is accepted and ignored — the redesign lists the occurrences of every
/// Tiler-owned series.
class TileDetailRoute extends StatelessWidget {
  TileDetailRoute({
    super.key,
    required String tileId,
    this.loadSubEvents = true,
    this.redesignBuilder = buildTileDetailRedesign,
  }) : target = TileDetailTarget.calendarEvent(tileId);

  /// Drop-in for `TileDetail.byDesignatedTileId(designatedTileTemplateId:,
  /// loadSubEvents:)` — the tile-share path (2026-09-17).
  TileDetailRoute.byDesignatedTileId({
    super.key,
    required String designatedTileTemplateId,
    this.loadSubEvents = false,
    this.redesignBuilder = buildTileDetailRedesign,
  }) : target = TileDetailTarget.designatedTile(designatedTileTemplateId);

  final TileDetailTarget target;
  final bool loadSubEvents;

  /// Test seam; production uses the default.
  final TileDetailRedesignBuilder redesignBuilder;

  @override
  Widget build(BuildContext context) => redesignBuilder(context, target);
}
