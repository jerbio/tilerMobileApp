import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailHost.dart';

/// A cluster's detail, opened by cluster id, by one of its designated tile
/// templates (a shared tile on the schedule) or with the cluster in hand.
///
/// A thin router (redesign Steps 9.12, 9.17) to the one-scaffold detail
/// ([TileShareDetailHost]). The old `isOutBox` is the ownership hint, used
/// only when the signed-in user is not known.
class TileShareDetailWidget extends StatelessWidget {
  final String? tileShareId;
  final String? designatedTileShareId;
  final bool isOutBox;
  final TileShareClusterData? tileShareClusterData;

  const TileShareDetailWidget.byId(
      {super.key, required this.tileShareId, this.isOutBox = true})
      : designatedTileShareId = null,
        tileShareClusterData = null;

  const TileShareDetailWidget.byDesignatedTileShareId(
      {super.key, required this.designatedTileShareId, this.isOutBox = false})
      : tileShareId = null,
        tileShareClusterData = null;

  const TileShareDetailWidget.byTileShareData(
      {super.key,
      required TileShareClusterData this.tileShareClusterData,
      this.isOutBox = true})
      : tileShareId = null,
        designatedTileShareId = null;

  /// Where the new detail opens from.
  TileShareDetailTarget get target {
    final TileShareClusterData? data = tileShareClusterData;
    if (data != null) return TileShareDetailTarget.data(data);
    final String? designated = designatedTileShareId;
    if (designated != null)
      return TileShareDetailTarget.designatedTile(designated);
    return TileShareDetailTarget.cluster(tileShareId ?? '');
  }

  /// Whether the caller opened it as the owner's.
  bool get ownerHint => isOutBox;

  @override
  Widget build(BuildContext context) {
    return TileShareDetailHost(target: target, ownerHint: ownerHint);
  }
}
