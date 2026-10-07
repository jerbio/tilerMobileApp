import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/hub/tileShareHubHost.dart';

/// The pushed `/TileShare` route: the TileShare hub (Attention | Clusters).
class TileShareRoute extends StatelessWidget {
  /// Builds the hub; the live one unless a test supplies its own.
  final WidgetBuilder? hubBuilder;

  const TileShareRoute({super.key, this.hubBuilder});

  @override
  Widget build(BuildContext context) =>
      (hubBuilder ?? (_) => const TileShareHubHost())(context);
}
