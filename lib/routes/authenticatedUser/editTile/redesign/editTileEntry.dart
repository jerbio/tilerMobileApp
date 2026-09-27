// Edit Tile redesign — Step 5.2 / 5.4: the one entry point.
//
// Every place that opens the editor pushes `EditTileRoute` with the
// arguments the legacy constructor took. Until 5.4 it chose between the
// legacy `EditTile` and the redesign by a flag; the legacy screen is gone
// and the route is unconditional — kept so the push sites keep one API.
//
// The redesign is wired in ONE function, `buildEditTileRedesign`, shared
// with the named route in `main.dart` — a second copy of the API and bloc
// wiring would drift.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

/// The builder the route renders; a seam for tests.
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

class EditTileRoute extends StatelessWidget {
  const EditTileRoute({
    super.key,
    required this.tileId,
    this.tileSource,
    this.thirdPartyUserId,
    this.redesignBuilder = buildEditTileRedesign,
  });

  final String tileId;
  final TileSource? tileSource;
  final String? thirdPartyUserId;

  /// Test seam; production uses the default.
  final EditTileRedesignBuilder redesignBuilder;

  @override
  Widget build(BuildContext context) {
    return redesignBuilder(
      context,
      EditTileRedesignRouteArgs(
        tileId: tileId,
        // The server's spelling (`microsoft`), not the enum's (`outlook`).
        source: tileSource?.wireName,
        thirdPartyUserId: thirdPartyUserId,
      ),
    );
  }
}
