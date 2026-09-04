// Phase 0 / Step 0.1 — behavior-preserving extraction of the request mapping.
//
// The legacy `AddTileState.onSubmitButtonTap()` built a `NewTile` inline from
// ~15 mutable widget fields. This file extracts ONLY that pure mapping into an
// explicit `AddTileDraft` snapshot + a pure `NewTileRequestMapper.build`, so
// the wire values can be characterized/tested without a live widget, blocs, or
// API calls. It does NOT change request semantics: the mapping is a faithful
// line-for-line port of the original inline code.
//
// Submission orchestration (API call, bloc refresh, analytics, newTileParams
// return) remains in the widget — this file is a pure mapper.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// Immutable snapshot of the Add Tile form state relevant to request mapping.
///
/// Mirrors the fields the legacy widget read at submit time. `now` is the
/// "current time" the legacy mapping used for the Flexible-Tile start
/// (midnight-of-submit-day); it is a parameter so tests are deterministic.
class AddTileDraft {
  final bool isAppointment;
  final String name;
  final Duration? duration;
  final DateTime? endTime;
  final DateTime? startTime;
  final RepetitionData? repetitionData;
  final Location? location;
  final RestrictionProfile? restrictionProfile;
  final bool isAutoRevisable;
  final TilePriority priority;
  final Color? color;
  final String splitCount;
  final DateTime now;

  const AddTileDraft({
    required this.isAppointment,
    required this.name,
    required this.duration,
    this.endTime,
    this.startTime,
    this.repetitionData,
    this.location,
    this.restrictionProfile,
    this.isAutoRevisable = true,
    this.priority = TilePriority.medium,
    this.color,
    this.splitCount = '1',
    required this.now,
  });
}

/// Pure, behavior-preserving port of the legacy inline `NewTile` construction.
class NewTileRequestMapper {
  static NewTile build(AddTileDraft d, {Random? randomizer}) {
    final Random rng = randomizer ?? Random();
    final NewTile tile = NewTile();
    tile.Name = d.name;
    if (d.duration != null) {
      tile.DurationMinute = d.duration!.inMinutes.toString();
    }

    DateTime? endTime = d.endTime;
    bool isAutoRevisable = false;
    if (d.isAutoRevisable) {
      isAutoRevisable = d.isAutoRevisable;
    }

    if (d.repetitionData != null) {
      tile.RepeatFrequency = d.repetitionData!.frequency.name;
      if (d.repetitionData!.repetitionEnd != null) {
        tile.RepeatEndYear = d.repetitionData!.repetitionEnd!.year.toString();
        tile.RepeatEndMonth = d.repetitionData!.repetitionEnd!.month.toString();
        tile.RepeatEndDay = d.repetitionData!.repetitionEnd!.day.toString();
        endTime = d.repetitionData!.repetitionEnd;
        isAutoRevisable = false;
      }

      if (d.repetitionData!.weeklyRepetition != null &&
          d.repetitionData!.weeklyRepetition!.length > 0) {
        tile.RepeatWeeklyData = d.repetitionData!.weeklyRepetition!
            .map((dayIndex) => dayIndex % 7)
            .join(',');
      }
      tile.RepeatData = d.repetitionData!.isForever.toString();
      tile.RepeatType = d.repetitionData!.frequency.name;
    }

    DateTime startTime = d.now;
    startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0);

    if (d.isAppointment) {
      tile.Rigid = true.toString();
      if (d.startTime != null) {
        startTime = d.startTime!;
        if (d.duration != null) {
          endTime = d.startTime!.add(d.duration!);
        }
      }
    }

    tile.EndYear = endTime?.year.toString();
    tile.EndMonth = endTime?.month.toString();
    tile.EndDay = endTime?.day.toString();
    tile.EndHour = endTime?.hour.toString();
    tile.EndMinute = endTime?.minute.toString();

    tile.StartYear = startTime.year.toString();
    tile.StartMonth = startTime.month.toString();
    tile.StartDay = startTime.day.toString();
    tile.StartHour = startTime.hour.toString();
    tile.StartMinute = startTime.minute.toString();
    tile.isEveryDay = false.toString();
    tile.isRestricted = false.toString();
    tile.isWorkWeek = false.toString();
    tile.AutoReviseDeadline = isAutoRevisable.toString();
    tile.Priority = d.priority.name.toString().toLowerCase();

    final Color randomColor = d.color ??
        HSLColor.fromAHSL(1, (rng.nextDouble() * 360), rng.nextDouble(),
                (1 - (rng.nextDouble() * 0.45)))
            .toColor();

    double colorConst = 255;
    tile.BColor = (randomColor.b * colorConst).toInt().toString();
    tile.GColor = (randomColor.g * colorConst).toInt().toString();
    tile.RColor = (randomColor.r * colorConst).toInt().toString();

    tile.ColorSelection = (-1).toString();

    if (d.location != null) {
      tile.LocationAddress = d.location!.address;
      tile.LocationTag = d.location!.description;
      tile.LocationId = d.location!.id;
      tile.LocationSource = d.location!.source;
      tile.LocationIsVerified = d.location!.isVerified.toString();
    }

    if (d.restrictionProfile != null &&
        d.restrictionProfile!.isAnyDayNotNull &&
        d.restrictionProfile!.isEnabled) {
      tile.RestrictiveWeek = d.restrictionProfile!.toRestrictionWeekConfig();
      tile.isRestricted = true.toString();
      tile.RestrictionProfileId = d.restrictionProfile!.id;
    }

    tile.Count = d.splitCount;

    return tile;
  }
}
