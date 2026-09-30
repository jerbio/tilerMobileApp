import 'package:tiler_app/data/tileShareActivity.dart';

/// One row of the activity feed: a single event, or several fan-out events
/// collapsed together (redesign T18).
class ActivityRow {
  /// Newest first, as the feed delivers them. Never empty.
  final List<TileShareActivity> events;

  const ActivityRow(this.events);

  /// The newest event — what the row's sentence and time come from.
  TileShareActivity get first => events.first;

  /// A stable id for keys: the newest event's id.
  String get id => first.eventId;

  int get count => events.length;

  /// How many different tasks the row spans ("added to 4 tasks").
  int get distinctTilettes =>
      events.map((e) => e.tiletteId).whereType<String>().toSet().length;

  /// How many different affected participants ("2 people added").
  int get distinctTargets =>
      events.map((e) => e.targetUserId).whereType<String>().toSet().length;
}

/// Collapses fan-out into single rows. A Class creates one event per task, so
/// "Participant added" would otherwise read four times in a row.
abstract final class ActivityRows {
  static const Duration defaultWindow = Duration(seconds: 60);

  /// Groups **neighbouring** events (input is newest first) that share the
  /// same actor, event type and cluster and are at most [window] apart — the
  /// gap is measured between neighbours, so a steady chain collapses into one
  /// row. Order is preserved.
  static List<ActivityRow> group(
    List<TileShareActivity> items, {
    Duration window = defaultWindow,
  }) {
    final List<List<TileShareActivity>> groups = <List<TileShareActivity>>[];
    for (final TileShareActivity event in items) {
      if (groups.isNotEmpty && _joins(groups.last.last, event, window)) {
        groups.last.add(event);
      } else {
        groups.add(<TileShareActivity>[event]);
      }
    }
    return groups
        .map((events) => ActivityRow(List<TileShareActivity>.unmodifiable(events)))
        .toList();
  }

  static bool _joins(
      TileShareActivity previous, TileShareActivity next, Duration window) {
    if (previous.eventType != next.eventType) return false;
    if (previous.clusterId != next.clusterId) return false;
    if (previous.actorId != next.actorId) return false;
    final Duration gap = previous.occurredAt.difference(next.occurredAt).abs();
    return gap <= window;
  }
}
