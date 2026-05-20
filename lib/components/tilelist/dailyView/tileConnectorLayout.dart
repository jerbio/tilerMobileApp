import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// Caps tiles longer than 16h (e.g. all-day or sleep tiles) so they are
/// rendered by their respective banners instead of the main list.
const int _maxTileDurationMs = 16 * 60 * 60 * 1000;

typedef TileWidgetBuilder = Widget Function(
  TilerEvent tile, {
  required int hour,
  required bool showHourMarker,
  required bool isCurrentHour,
});

typedef ConflictGroupWidgetBuilder = Widget Function(
  ConflictGroup group, {
  required int hour,
  required bool showHourMarker,
  required bool isCurrentHour,
});

typedef ConnectorWrapper = Widget Function(Widget connector);

class TileConnectorLayoutResult {
  final List<Widget> widgets;
  final int? selectedTileIndex;
  final List<ConflictGroup> conflictGroups;

  const TileConnectorLayoutResult({
    required this.widgets,
    required this.selectedTileIndex,
    required this.conflictGroups,
  });
}

/// Builds the ordered list of widgets for a day view, emitting each travel
/// connector immediately before the tile (or conflict group) it describes.
/// This is shared between the standard daily view and the "today" view to
/// keep their connector-ordering behavior in sync.
TileConnectorLayoutResult buildTileListWithConnectors({
  required List<TilerEvent> orderedTiles,
  required bool showTravelConnectors,
  required bool showConflictAlerts,
  required bool excludeDeclinedFromConflicts,
  required DateTime now,
  String? selectedActionEntityId,
  required TileWidgetBuilder buildTile,
  required ConflictGroupWidgetBuilder buildConflictGroup,
  required ConnectorWrapper wrapConnector,
}) {
  final List<Widget> widgets = [];
  int? selectedTileIndex;
  final Set<int> displayedHours = {};

  final regularTiles = orderedTiles.where((tile) {
    if (tile is SubCalendarEvent && tile.start != null && tile.end != null) {
      return (tile.end! - tile.start!) < _maxTileDurationMs;
    }
    return true;
  }).toList();

  final subCalendarEvents = regularTiles
      .whereType<SubCalendarEvent>()
      .where((tile) =>
          !excludeDeclinedFromConflicts || tile.rsvp != RsvpStatus.declined)
      .toList();

  final conflictGroups = showConflictAlerts
      ? ConflictGroup.detectGroups(subCalendarEvents)
      : <ConflictGroup>[];

  final Set<String> tilesInConflictGroups = {
    for (final group in conflictGroups)
      for (final tile in group.tiles) tile.uniqueId,
  };

  final Set<int> renderedConflictGroups = {};

  // Track the previously rendered tile so each travel connector renders
  // immediately before its destination tile, even when a conflict group
  // appears between the source and destination.
  SubCalendarEvent? prevRenderedTile;

  void emitTravelConnectorTo(SubCalendarEvent destinationTile) {
    if (!showTravelConnectors) return;
    final source = prevRenderedTile;
    if (source == null) return;

    final travelTime = destinationTile.travelTimeBefore;
    final hasTravel = travelTime != null && travelTime > 0;

    Widget? connector;
    if (hasTravel) {
      connector = TravelConnector(
        fromTile: source,
        toTile: destinationTile,
      );
    } else if (destinationTile.address != null &&
        destinationTile.address!.isNotEmpty) {
      connector = CompactTravelIndicator(
        travelTimeMs: destinationTile.travelTimeBefore?.toDouble(),
        travelMode: destinationTile.travelDetail?.before?.travelMedium,
        startLocation: destinationTile.travelDetail?.before?.startLocation,
        endLocation: destinationTile.travelDetail?.before?.endLocation,
        destinationAddress: destinationTile.address,
      );
    }

    if (connector != null) {
      widgets.add(wrapConnector(connector));
    }
  }

  for (int i = 0; i < regularTiles.length; i++) {
    final tile = regularTiles[i];
    final tileHour = tile.startTime.hour;
    final isCurrentHour = tile.startTime.day == now.day &&
        tile.startTime.month == now.month &&
        tile.startTime.year == now.year &&
        tileHour == now.hour;

    final showHourMarker = !displayedHours.contains(tileHour);
    if (showHourMarker) {
      displayedHours.add(tileHour);
    }

    if (tile is SubCalendarEvent &&
        tilesInConflictGroups.contains(tile.uniqueId)) {
      final groupIndex = conflictGroups.indexWhere(
          (group) => group.tiles.any((t) => t.uniqueId == tile.uniqueId));

      if (groupIndex >= 0 && !renderedConflictGroups.contains(groupIndex)) {
        renderedConflictGroups.add(groupIndex);
        final group = conflictGroups[groupIndex];

        final groupTilesByStart = [...group.tiles]
          ..sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
        if (groupTilesByStart.isNotEmpty) {
          emitTravelConnectorTo(groupTilesByStart.first);
        }

        widgets.add(buildConflictGroup(
          group,
          hour: tileHour,
          showHourMarker: showHourMarker,
          isCurrentHour: isCurrentHour,
        ));

        final groupTilesByEnd = [...group.tiles]
          ..sort((a, b) => (a.end ?? 0).compareTo(b.end ?? 0));
        if (groupTilesByEnd.isNotEmpty) {
          prevRenderedTile = groupTilesByEnd.last;
        }
      }
      continue;
    }

    if (selectedActionEntityId != null &&
        tile.id?.contains(selectedActionEntityId) == true) {
      selectedTileIndex = widgets.length;
    }

    if (tile is SubCalendarEvent) {
      emitTravelConnectorTo(tile);
    }

    widgets.add(buildTile(
      tile,
      hour: tileHour,
      showHourMarker: showHourMarker,
      isCurrentHour: isCurrentHour,
    ));

    if (tile is SubCalendarEvent) {
      prevRenderedTile = tile;
    }
  }

  return TileConnectorLayoutResult(
    widgets: widgets,
    selectedTileIndex: selectedTileIndex,
    conflictGroups: conflictGroups,
  );
}
