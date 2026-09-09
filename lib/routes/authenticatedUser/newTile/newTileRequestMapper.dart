// Behavior-preserving extraction of the Add Tile request mapping.
//
// The legacy `AddTileState.onSubmitButtonTap()` built a `NewTile` inline from
// ~15 mutable widget fields. This file extracts ONLY that pure mapping into an
// explicit `LegacyAddTileDraft` snapshot + a pure `NewTileRequestMapper.build`,
// so the wire values can be characterized/tested without a live widget, blocs,
// or API calls. It does NOT change request semantics: the mapping is a faithful
// line-for-line port of the original inline code.
//
// `buildFromSnapshot(AddTileDraftSnapshot)` proves wire parity with the
// widget-independent model by delegating to the same mapping code.
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
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';

/// Immutable snapshot of the legacy Add Tile form state relevant to request
/// mapping. Mirrors the fields the legacy widget read at submit time.
/// `now` is the "current time" the legacy mapping used for the Flexible-Tile
/// start (midnight-of-submit-day); it is a parameter so tests are deterministic.
///
/// Named `LegacyAddTileDraft` to disambiguate from the new widget-independent
/// model of the same conceptual name (`AddTileDraft` in addTileDraft.dart).
/// This class is the legacy isAppointment snapshot kept as the reference
/// mapping until the old inline builder is removed.
class LegacyAddTileDraft {
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

  const LegacyAddTileDraft({
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
  static NewTile build(LegacyAddTileDraft d, {Random? randomizer}) {
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
      // `RepeatType` is the NUMERIC frequency and `RepeatFrequency` the name;
      // the web client sends both (`"RepeatType":"1"` with
      // `"RepeatFrequency":"Weekly"`). Legacy mobile sent the name for both,
      // so `RepeatType` went up as "weekly" (D27).
      //
      // The number is the enum's declaration index — `{daily, weekly, monthly,
      // yearly, none}` puts weekly at 1, which is what the captured payload
      // carries. Only weekly is confirmed against real data; the others follow
      // from the ordering and are pinned in add_tile_repeat_payload_test.dart.
      //
      // DELIBERATE DIVERGENCE from the legacy inline builder in addTile.dart,
      // which still sends the name here.
      tile.RepeatType = d.repetitionData!.frequency.index.toString();
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

    // A location with neither a name nor an address is NOT a location, so
    // nothing location-shaped is sent for it (D55). That is the backend's own
    // contract — both fields absent means a null location — and it is
    // reachable from the UI by clearing the name of a place that never had an
    // address.
    if (d.location != null && locationHasContent(d.location)) {
      // Empty strings are PRESENT on the wire, which is not the same as
      // absent: the backend copies whichever field is supplied into the other
      // and upserts places by name, so a blank tag would create a place
      // called "". Deleting the name in the editor used to do exactly that.
      final String tag = (d.location!.description ?? '').trim();
      final String address = (d.location!.address ?? '').trim();

      if (address.isNotEmpty) {
        tile.LocationAddress = address;
      }
      // `LocationTag` IS the backend Name, and the backend upserts places by
      // name (D20). Shipping a provider's business name therefore makes every
      // "Walmart Supercenter" overwrite the last one, leaving a single saved
      // place pointing at whichever branch was used most recently.
      //
      // So the name is sent when it is the USER'S — which is true either
      // because the place is not provider-sourced, OR because the user
      // renamed it. D20 tested only the first and dropped the second: a
      // Google-resolved address given a nickname in the place editor lost
      // that nickname entirely, which is exactly the flow D19 exists for.
      // The web client sends the tag in that case (captured payload,
      // 2026-09-09) and so do we now (D54).
      //
      // DELIBERATE DIVERGENCE from the legacy mapping, which sent the tag
      // unconditionally. Encoded in add_tile_location_name_ownership_test.dart.
      if (tag.isNotEmpty &&
          (locationNameIsUserOwned(d.location!) || d.location!.userRenamed)) {
        tile.LocationTag = tag;
      }

      // `LocationId` identifies a TILER record to update. It is sent only
      // when there is one and it still describes what is being sent:
      //
      //   * a provider pick's `id` is a `thirdPartyId`, not a Tiler id, so it
      //     would be meaningless here;
      //   * once the user edits the name or the address, the record no longer
      //     matches what is being sent, and the backend should upsert by name
      //     rather than mutate the old row.
      //
      // Legacy sent it unconditionally (D54).
      if (!locationIsProviderSourced(d.location!) &&
          !d.location!.userRenamed &&
          !d.location!.userEditedAddress) {
        tile.LocationId = d.location!.id;
      }

      // `source` reports where the ADDRESS came from; the place editor sets
      // it to 'none' when the user types one (D54).
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

  /// Builds a [NewTile] from the new-model [AddTileDraftSnapshot] by converting
  /// to a [LegacyAddTileDraft] and delegating to [build]. This guarantees wire
  /// parity with the legacy path by construction — the same mapping code is
  /// executed. `now` is the submit-time used for the Flexible-Tile start
  /// (midnight-of-submit-day), exactly as the legacy widget computed it from
  /// `Utility.currentTime()`.
  ///
  /// Privacy: this method never serializes the request body or user-entered
  /// content; failure diagnostics (type + reason code) are the caller's
  /// responsibility.
  static NewTile buildFromSnapshot(
    AddTileDraftSnapshot s, {
    required DateTime now,
    Random? randomizer,
  }) {
    final LegacyAddTileDraft legacy = LegacyAddTileDraft(
      isAppointment: s.type == AddTileType.fixed,
      name: s.name,
      duration: s.duration,
      endTime: s.endTime,
      startTime: s.startTime,
      repetitionData: s.repetitionData,
      location: s.location,
      restrictionProfile: s.restrictionProfile,
      isAutoRevisable: s.isAutoRevisable,
      priority: s.priority,
      color: s.color,
      splitCount: s.splitCount.toString(),
      now: now,
    );
    return build(legacy, randomizer: randomizer);
  }
}
