// Tile Detail redesign — Step 6.6: the ONE production wiring of the
// redesigned screen, and the drop-in route for the legacy push sites.
//
// D25: Edit Tile and Tile Detail ship together behind ONE flag
// (`EditTileFeatureFlags.editTileRedesignEnabled`); the redesigned Edit
// Tile always hands off here, never to the legacy `TileDetail`; every
// legacy push site goes through `TileDetailRoute`, so the flag governs
// all of them and 5.4 can delete both legacy screens in one move.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart'
    show EditTileFeatureFlags;
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/tileDetail.dart';
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
Future<void> pushTileDetailRedesign(
        BuildContext context, String calendarEventId) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (BuildContext routeContext) => buildTileDetailRedesign(
          routeContext, TileDetailTarget.calendarEvent(calendarEventId)),
    ));

typedef TileDetailLegacyBuilder = Widget Function(
    String tileId, bool loadSubEvents);
typedef TileDetailRedesignBuilder = Widget Function(
    BuildContext context, TileDetailTarget target);

Widget _legacy(String tileId, bool loadSubEvents) =>
    TileDetail(tileId: tileId, loadSubEvents: loadSubEvents);

Widget _legacyTemplate(String templateId, bool loadSubEvents) =>
    TileDetail.byDesignatedTileId(
        designatedTileTemplateId: templateId, loadSubEvents: loadSubEvents);

/// Drop-in for the legacy `TileDetail(tileId:, loadSubEvents:)`: the
/// redesign when the (shared) flag is on, the legacy screen when off.
/// `loadSubEvents` only reaches the legacy screen — the redesign lists the
/// occurrences of every Tiler-owned series.
class TileDetailRoute extends StatelessWidget {
  TileDetailRoute({
    super.key,
    required String tileId,
    this.loadSubEvents = true,
    this.legacyBuilder = _legacy,
    this.redesignBuilder = buildTileDetailRedesign,
  })  : target = TileDetailTarget.calendarEvent(tileId),
        legacyTemplateBuilder = _legacyTemplate;

  /// Drop-in for `TileDetail.byDesignatedTileId(designatedTileTemplateId:,
  /// loadSubEvents:)` — the tile-share path (2026-09-17).
  TileDetailRoute.byDesignatedTileId({
    super.key,
    required String designatedTileTemplateId,
    this.loadSubEvents = false,
    this.legacyTemplateBuilder = _legacyTemplate,
    this.redesignBuilder = buildTileDetailRedesign,
  })  : target = TileDetailTarget.designatedTile(designatedTileTemplateId),
        legacyBuilder = _legacy;

  final TileDetailTarget target;
  final bool loadSubEvents;

  /// Test seams; production uses the defaults.
  final TileDetailLegacyBuilder legacyBuilder;
  final TileDetailLegacyBuilder legacyTemplateBuilder;
  final TileDetailRedesignBuilder redesignBuilder;

  @override
  Widget build(BuildContext context) {
    if (!EditTileFeatureFlags.editTileRedesignEnabled) {
      final String? templateId = target.designatedTileTemplateId;
      return templateId != null
          ? legacyTemplateBuilder(templateId, loadSubEvents)
          : legacyBuilder(target.calendarEventId!, loadSubEvents);
    }
    return redesignBuilder(context, target);
  }
}
