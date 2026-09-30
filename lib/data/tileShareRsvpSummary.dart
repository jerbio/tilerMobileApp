import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

/// How many people / tilettes have accepted, declined or not yet answered —
/// the “3 of 5 accepted” line on cards and headers (redesign T13).
///
/// This is RSVP **status**, not progress. The server reports completion only
/// per assignment (one recipient on one tilette) and no cluster-level progress
/// ships (owner decision, 2026-09-29); completion is shown per tilette /
/// assignment and is never rolled up here.
///
/// What is counted depends on the mode ([forCluster]):
/// * Broadcast ([fromUsers]) — assignments.
/// * Class ([fromClass]) — **people**, matched across tasks by identity; a
///   person is accepted only when accepted on every task they hold, declined
///   only when declined on every one, otherwise still pending.
/// * Project ([fromTilettes]) — **tilettes**: accepted when anyone accepted it,
///   declined when everyone assigned declined, otherwise pending.
class TileShareRsvpSummary {
  /// People ([fromClass]), assignments ([fromUsers]) or tilettes
  /// ([fromTilettes]) counted.
  final int total;
  final int accepted;
  final int declined;
  final int pending;

  const TileShareRsvpSummary({
    required this.total,
    required this.accepted,
    required this.declined,
    required this.pending,
  });

  static const TileShareRsvpSummary empty =
      TileShareRsvpSummary(total: 0, accepted: 0, declined: 0, pending: 0);

  static bool _isAccepted(DesignatedUser user) =>
      user.rsvpStatus == InvitationStatus.accepted;

  static bool _isDeclined(DesignatedUser user) =>
      user.rsvpStatus == InvitationStatus.declined;

  /// The counting rule for [mode] over the cluster's [tilettes].
  static TileShareRsvpSummary forCluster(
    TileShareMode mode,
    Iterable<TileShareTemplate> tilettes,
  ) {
    switch (mode) {
      case TileShareMode.broadcast:
        return fromUsers(tilettes.expand(
            (t) => t.designatedUsers ?? const <DesignatedUser>[]));
      case TileShareMode.class_:
        return fromClass(tilettes);
      case TileShareMode.project:
        return fromTilettes(tilettes);
    }
  }

  /// Broadcast: one count per assignment.
  static TileShareRsvpSummary fromUsers(Iterable<DesignatedUser> users) {
    int total = 0, accepted = 0, declined = 0, pending = 0;
    for (final DesignatedUser user in users) {
      total++;
      if (_isAccepted(user)) {
        accepted++;
      } else if (_isDeclined(user)) {
        declined++;
      } else {
        pending++;
      }
    }
    if (total == 0) return empty;
    return TileShareRsvpSummary(
        total: total, accepted: accepted, declined: declined, pending: pending);
  }

  /// Class: one count per **person**, each judged on the tasks they hold.
  /// People are matched across tasks by identity ([ClassFanout]); an
  /// assignment with no usable identity counts as its own person.
  static TileShareRsvpSummary fromClass(Iterable<TileShareTemplate> tilettes) {
    final List<Set<String>> keys = <Set<String>>[];
    final List<List<DesignatedUser>> people = <List<DesignatedUser>>[];
    for (final TileShareTemplate tilette in tilettes) {
      for (final DesignatedUser user
          in tilette.designatedUsers ?? const <DesignatedUser>[]) {
        final contact = ClassFanout.contactOfUser(user);
        final Set<String> own =
            contact == null ? <String>{} : ClassFanout.identityKeys(contact);
        if (own.isEmpty) own.add('assignment:${user.id}:${people.length}');
        final int found = keys.indexWhere((known) => known.any(own.contains));
        if (found >= 0) {
          keys[found].addAll(own);
          people[found].add(user);
        } else {
          keys.add(<String>{...own});
          people.add(<DesignatedUser>[user]);
        }
      }
    }
    if (people.isEmpty) return empty;

    int accepted = 0, declined = 0, pending = 0;
    for (final List<DesignatedUser> held in people) {
      if (held.every(_isAccepted)) {
        accepted++;
      } else if (held.every(_isDeclined)) {
        declined++;
      } else {
        pending++;
      }
    }
    return TileShareRsvpSummary(
        total: people.length,
        accepted: accepted,
        declined: declined,
        pending: pending);
  }

  /// Project: one count per **tilette**.
  static TileShareRsvpSummary fromTilettes(
      Iterable<TileShareTemplate> tilettes) {
    int total = 0, accepted = 0, declined = 0, pending = 0;
    for (final TileShareTemplate tilette in tilettes) {
      total++;
      final List<DesignatedUser> users =
          tilette.designatedUsers ?? const <DesignatedUser>[];
      if (users.any(_isAccepted)) {
        accepted++;
      } else if (users.isNotEmpty && users.every(_isDeclined)) {
        declined++;
      } else {
        pending++;
      }
    }
    if (total == 0) return empty;
    return TileShareRsvpSummary(
        total: total, accepted: accepted, declined: declined, pending: pending);
  }
}
