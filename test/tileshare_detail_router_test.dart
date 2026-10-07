// TileShare redesign Step 9.12: `TileShareDetailWidget` keeps its three entry
// points (cluster id, designated tile template, data in hand) and becomes a
// thin router over the new detail (the old screens are retired in 9.17). Each entry point maps to the new detail's target, and the old
// `isOutBox` becomes the ownership hint used only when the signed-in user is
// not known.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';

import 'helpers/tileshare_fixtures.dart';

void main() {
  test('by cluster id', () {
    final w = TileShareDetailWidget.byId(tileShareId: 'c1');
    expect(w.target.clusterId, 'c1');
    expect(w.target.designatedTileId, isNull);
    expect(w.ownerHint, isTrue, reason: 'byId defaulted to the outbox');
    expect(TileShareDetailWidget.byId(tileShareId: 'c1', isOutBox: false)
        .ownerHint, isFalse);
  });

  test('by designated tile template', () {
    final w =
        TileShareDetailWidget.byDesignatedTileShareId(designatedTileShareId: 'd1');
    expect(w.target.designatedTileId, 'd1');
    expect(w.target.clusterId, isNull);
    expect(w.ownerHint, isFalse,
        reason: 'a shared tile on my schedule is someone else\'s share');
  });

  test('with data in hand', () {
    final cluster = tsCluster('c9', name: 'Launch Prep');
    final w = TileShareDetailWidget.byTileShareData(tileShareClusterData: cluster);
    expect(w.target.data, same(cluster));
    expect(w.target.clusterId, 'c9');
    expect(w.ownerHint, isTrue);
  });
}
