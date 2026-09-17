// Edit Tile redesign — Step 5.2: the one entry point.
//
// Every place that opens the editor pushes `EditTileRoute` with the legacy
// constructor's arguments. It renders the redesign when the flag is on and
// the legacy `EditTile` when it is off, so the thirteen push sites do not
// know which they got and Step 5.4 can delete the legacy screen in one move.
//
// The redesign is wired in ONE function, `buildEditTileRedesign`, shared
// with the debug route in `main.dart` — a second copy of the API and bloc
// wiring would drift.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

/// Local, dependency-free flag, as `AddTileFeatureFlags`. Off by default:
/// production entry points keep the legacy screen until the rollout
/// (plan Step 5.2); the debug ✨ entry reaches the redesign regardless.
class EditTileFeatureFlags {
  EditTileFeatureFlags._();

  static bool _enabled = false;
  static bool get editTileRedesignEnabled => _enabled;
  static set editTileRedesignEnabled(bool value) => _enabled = value;
}

typedef EditTileLegacyBuilder = Widget Function(
    String tileId, TileSource? tileSource, String? thirdPartyUserId);
typedef EditTileRedesignBuilder = Widget Function(
    BuildContext context, EditTileRedesignRouteArgs args);

/// The redesigned editor with its production wiring.
Widget buildEditTileRedesign(
    BuildContext context, EditTileRedesignRouteArgs args) {
  final SubCalendarEventApi subCalendarEventApi =
      SubCalendarEventApi(getContextCallBack: () => context);
  return EditTileRedesignScreen(
    tileId: args.tileId,
    source: args.source,
    thirdPartyUserId: args.thirdPartyUserId,
    loader: ApiEditTileLoader(
      subCalendarEventApi: subCalendarEventApi,
      calendarEventApi: CalendarEventApi(getContextCallBack: () => context),
    ),
    submission: ApiEditTileSubmission(
      subCalendarEventApi: subCalendarEventApi,
      whatIfApi: WhatIfApi(getContextCallBack: () => context),
      refresher: BlocEditTileScheduleRefresher(
        scheduleBloc: context.read<ScheduleBloc>(),
        scheduleSummaryBloc: context.read<ScheduleSummaryBloc>(),
      ),
    ),
  );
}

Widget _legacy(
        String tileId, TileSource? tileSource, String? thirdPartyUserId) =>
    EditTile(
      tileId: tileId,
      tileSource: tileSource,
      thirdPartyUserId: thirdPartyUserId,
    );

/// Drop-in for the legacy `EditTile(...)` at every push site.
class EditTileRoute extends StatelessWidget {
  const EditTileRoute({
    super.key,
    required this.tileId,
    this.tileSource,
    this.thirdPartyUserId,
    this.legacyBuilder = _legacy,
    this.redesignBuilder = buildEditTileRedesign,
  });

  final String tileId;
  final TileSource? tileSource;
  final String? thirdPartyUserId;

  /// Test seams; production uses the defaults.
  final EditTileLegacyBuilder legacyBuilder;
  final EditTileRedesignBuilder redesignBuilder;

  @override
  Widget build(BuildContext context) {
    if (!EditTileFeatureFlags.editTileRedesignEnabled) {
      return legacyBuilder(tileId, tileSource, thirdPartyUserId);
    }
    return redesignBuilder(
      context,
      EditTileRedesignRouteArgs(
        tileId: tileId,
        source: tileSource?.name,
        thirdPartyUserId: thirdPartyUserId,
      ),
    );
  }
}
