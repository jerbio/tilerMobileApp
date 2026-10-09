import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// A copy of a moving tile drawn over the list, flying from its old row to
/// its new one while the real row stays hidden.
class ListFlight {
  final String tileId;
  final Rect from;
  final int toStartMs;
  Rect? to;
  bool lifted = false;
  bool moving = false;

  ListFlight(this.tileId, this.from, this.toStartMs);
}

/// The outline left at a moving tile's old row.
class ListFlightGhost {
  final Rect rect;
  final int toStartMs;
  bool fading = false;

  ListFlightGhost(this.rect, this.toStartMs);
}

/// Plays the flights for one schedule change in the daily list.
///
/// [prepare] runs before the new rows are built: the moving tiles' rows are
/// hidden from that frame on and a copy holds each at its old spot. Once
/// the new rows are laid out, [launch] gives each copy its destination and
/// plays the batches (lift, fly, land); a tile whose new row is not on
/// screen just reappears in place. Landing reveals the real row.
class ListFlightPlayer {
  ListFlightPlayer({required this.apply});

  /// Runs a state change and rebuilds the owner (its `setState`).
  final void Function(VoidCallback change) apply;

  /// The longest a prepared flight may wait for [launch] before the rows
  /// are revealed anyway.
  static const Duration launchTimeout = Duration(seconds: 2);

  final Map<String, ListFlight> _flights = <String, ListFlight>{};
  final Map<String, ListFlightGhost> _ghosts = <String, ListFlightGhost>{};
  final List<Timer> _timers = <Timer>[];
  Timer? _launchTimeout;

  Iterable<ListFlight> get flights => _flights.values;
  Iterable<MapEntry<String, ListFlightGhost>> get ghosts => _ghosts.entries;
  bool get isActive => _flights.isNotEmpty || _ghosts.isNotEmpty;

  /// The tile's real row is hidden while its copy is in the air.
  bool isHidden(String tileId) => _flights.containsKey(tileId);

  /// Holds [movers] (old row rect and new start, by tile id) at their old
  /// spot. Called from the owner's build, so it changes state directly.
  void prepare(Map<String, (Rect, int)> movers) {
    stop(notify: false);
    movers.forEach((id, value) {
      _flights[id] = ListFlight(id, value.$1, value.$2);
    });
    if (_flights.isNotEmpty) {
      _launchTimeout = Timer(launchTimeout, () {
        if (_flights.values.any((f) => f.to == null)) stop();
      });
    }
  }

  /// Gives the prepared copies their destinations and plays [steps].
  /// Copies without a destination on screen are dropped at once.
  void launch(Map<String, Rect> targets, GridChoreography steps) {
    _launchTimeout?.cancel();
    _launchTimeout = null;
    apply(() {
      _flights.removeWhere((id, _) => !targets.containsKey(id));
      targets.forEach((id, rect) => _flights[id]?.to = rect);
    });
    if (_flights.isEmpty) return;
    for (final batch in steps.batches) {
      final ids = batch.ids.where(_flights.containsKey).toList();
      if (ids.isEmpty) continue;
      _after(batch.liftAt, () {
        for (final id in ids) {
          final flight = _flights[id];
          if (flight == null) continue;
          flight.lifted = true;
          _ghosts[id] = ListFlightGhost(flight.from, flight.toStartMs);
        }
      });
      _after(batch.moveAt, () {
        for (final id in ids) {
          _flights[id]?.moving = true;
        }
      });
      _after(batch.landAt, () {
        for (final id in ids) {
          _flights.remove(id);
          _ghosts[id]?.fading = true;
        }
      });
    }
    _after(steps.end, () {
      _flights.clear();
      _ghosts.clear();
    });
  }

  /// Ends everything at once: every row visible at its real place.
  /// [notify] rebuilds the owner; pass false from build or dispose.
  void stop({bool notify = true}) {
    _launchTimeout?.cancel();
    _launchTimeout = null;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    if (_flights.isEmpty && _ghosts.isEmpty) return;
    void clear() {
      _flights.clear();
      _ghosts.clear();
    }

    notify ? apply(clear) : clear();
  }

  void _after(Duration delay, VoidCallback change) {
    _timers.add(Timer(delay, () => apply(change)));
  }
}

/// Draws a [ListFlightPlayer]'s ghosts and flying copies over the list.
/// Sits in a Stack above the list, in the same coordinates the rects were
/// measured in.
class ListFlightOverlay extends StatelessWidget {
  final ListFlightPlayer player;

  /// Builds the copy of a tile's row (as it is now) for its flight.
  final Widget Function(String tileId) rowBuilder;
  final bool animate;

  const ListFlightOverlay({
    super.key,
    required this.player,
    required this.rowBuilder,
    required this.animate,
  });

  static Key flightKey(String tileId) => Key('list_flight_$tileId');
  static Key ghostKey(String tileId) => Key('list_flight_ghost_$tileId');

  @override
  Widget build(BuildContext context) {
    if (!player.isActive) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final entry in player.ghosts)
            Positioned.fromRect(
              key: ghostKey(entry.key),
              rect: entry.value.rect.deflate(2),
              child: AnimatedOpacity(
                opacity: entry.value.fading ? 0.0 : 1.0,
                duration:
                    animate ? GridChoreography.ghostLinger : Duration.zero,
                child: _Ghost(ghost: entry.value, colorScheme: colorScheme),
              ),
            ),
          for (final flight in player.flights)
            AnimatedPositioned.fromRect(
              key: flightKey(flight.tileId),
              rect:
                  flight.moving && flight.to != null ? flight.to! : flight.from,
              duration: animate && flight.moving
                  ? GridChoreography.move
                  : Duration.zero,
              curve: Curves.easeInOutCubic,
              child: AnimatedScale(
                scale: flight.lifted ? 1.03 : 1.0,
                duration: animate ? GridChoreography.lift : Duration.zero,
                child: AnimatedContainer(
                  duration: animate ? GridChoreography.lift : Duration.zero,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(TileDimensions.borderRadius),
                    boxShadow: flight.lifted
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: rowBuilder(flight.tileId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ghost extends StatelessWidget {
  final ListFlightGhost ghost;
  final ColorScheme colorScheme;

  const _Ghost({required this.ghost, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(Utility.localDateTimeFromMs(ghost.toStartMs)),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
        border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Text(
        AppLocalizations.of(context)!.scheduleChangeMovedTo(time),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}
