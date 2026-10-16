import 'package:tiler_app/services/scheduleDelta.dart';

/// One group of Tiles that lift, move and land together.
class GridChoreographyBatch {
  final List<String> ids;

  /// When the batch lifts, from the start of the sequence.
  final Duration liftAt;

  /// Tiles in this batch whose travel changed and pushed the rest: their
  /// travel is shown changing first, [GridChoreography.causeLead] before
  /// the lift.
  final List<String> causeIds;

  const GridChoreographyBatch(
      {required this.ids, required this.liftAt, this.causeIds = const []});

  /// When this batch's cause is shown (its lift when it has none).
  Duration get causeAt =>
      causeIds.isEmpty ? liftAt : liftAt - GridChoreography.causeLead;

  /// When the lifted Tiles start sliding to their new times.
  Duration get moveAt => liftAt + GridChoreography.lift;

  /// When they arrive and drop back down.
  Duration get landAt => moveAt + GridChoreography.move;
}

/// The timing of a step-by-step schedule change in the day grid.
///
/// Moved Tiles play in batches of up to [ScheduleDelta.batchSize], in the
/// delta's cause-first order. Each batch lifts, slides and lands; the next
/// batch lifts as the previous one lands, so a 3-batch change still
/// finishes in under two seconds.
class GridChoreography {
  static const Duration lift = Duration(milliseconds: 150);
  static const Duration move = Duration(milliseconds: 350);

  /// The time a cause (a travel change) is shown on its own before the
  /// tiles it pushed lift.
  static const Duration causeLead = Duration(milliseconds: 250);

  /// How long a ghost lingers after its Tile lands before it fades.
  static const Duration ghostLinger = Duration(milliseconds: 200);

  final List<GridChoreographyBatch> batches;

  const GridChoreography._(this.batches);

  /// Every Tile the sequence moves.
  Set<String> get ids => {for (final batch in batches) ...batch.ids};

  /// When the last ghost has faded and everything is back to rest.
  Duration get end => batches.last.landAt + ghostLinger;

  /// Kinds that slide within the grid. Tiles arriving from or leaving for
  /// another day enter and exit instead.
  static const Set<TileChangeKind> _sliding = {
    TileChangeKind.moved,
    TileChangeKind.resized,
    TileChangeKind.movedAndResized,
  };

  /// The sequence for [delta], or null when the change should use the
  /// plain transition: nothing slides, too many Tiles moved to step
  /// through, or the day was emptied or filled.
  ///
  /// [subjectId] is the Tile the user moved themselves; it settles straight
  /// away and only the Tiles it pushed are stepped through.
  static GridChoreography? plan(ScheduleDelta delta, {String? subjectId}) {
    switch (delta.tier) {
      case ScheduleDeltaTier.single:
      case ScheduleDeltaTier.batched:
        break;
      case ScheduleDeltaTier.none:
      case ScheduleDeltaTier.compressed:
      case ScheduleDeltaTier.dayEmptied:
      case ScheduleDeltaTier.dayFilled:
        return null;
    }
    final ordered = <String>[
      for (final batch in delta.batches)
        for (final change in batch.tiles)
          if (_sliding.contains(change.kind) && change.id != subjectId)
            change.id,
    ];
    if (ordered.isEmpty) return null;

    final causes = {
      for (final batch in delta.batches)
        for (final cause in batch.causes) cause.id,
    };
    const size = ScheduleDelta.batchSize;
    final batches = <GridChoreographyBatch>[];
    var at = Duration.zero;
    for (var start = 0; start < ordered.length; start += size) {
      final ids =
          ordered.sublist(start, (start + size).clamp(0, ordered.length));
      final causeIds = ids.where(causes.contains).toList();
      // Cause first: a batch pushed by a travel change waits for it.
      if (causeIds.isNotEmpty) at += causeLead;
      batches
          .add(GridChoreographyBatch(ids: ids, liftAt: at, causeIds: causeIds));
      at += lift + move;
    }
    return GridChoreography._(batches);
  }
}
