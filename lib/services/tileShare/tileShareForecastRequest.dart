import 'package:tiler_app/data/designatedTile.dart';

/// The what-if forecast request (`POST /api/WhatIf/NewTile`) for a shared task:
/// from now to its deadline, for its duration.
///
/// The server builds the end from separate Day / Month / Year / **Hour /
/// Minute** fields and fills a missing hour or minute with 0. A request with
/// only the date therefore ended at midnight at the *start* of the deadline's
/// day — already past for a task due later today, which the server rejected
/// ("End time has to be later than start"), and ignoring the deadline's time of
/// day for any other. So the deadline's hour and minute are always sent.
abstract final class TileShareForecastRequest {
  /// A pending task whose deadline has passed: it cannot be forecast (the
  /// forecast runs from now to the deadline), so the tile says so instead of
  /// offering the button.
  static bool isOverdue(DesignatedTile tile, int nowMs) {
    final int? end = tile.tileTemplate?.end;
    return tile.invitationStatus != InvitationStatus.accepted.name &&
        end != null &&
        end <= nowMs;
  }

  /// Why the invitation tile shows no forecast button (the binoculars), or
  /// `null` when it shows one. Exactly the screen's rule - not accepted (the
  /// raw status compared with "accepted"), a template with a duration and a
  /// deadline after [nowMs] - so a log of it is what the screen did.
  static String? hiddenReason(DesignatedTile tile, int nowMs) {
    final List<String> reasons = <String>[
      if (tile.invitationStatus == InvitationStatus.accepted.name)
        'already accepted',
      if (tile.tileTemplate == null) 'no template',
      if (tile.tileTemplate != null && tile.tileTemplate!.durationInMs == null)
        'no duration',
      if (tile.tileTemplate != null && tile.tileTemplate!.end == null)
        'no deadline',
      if (tile.tileTemplate?.end != null && tile.tileTemplate!.end! <= nowMs)
        'deadline passed (${DateTime.fromMillisecondsSinceEpoch(tile.tileTemplate!.end!)})',
    ];
    return reasons.isEmpty ? null : reasons.join(', ');
  }

  /// `null` when there is nothing to forecast: no duration, no deadline, or a
  /// deadline that is not after [now].
  static Map<String, Object>? forTask({
    required int? durationMs,
    required int? endMs,
    required DateTime now,
  }) {
    if (durationMs == null || endMs == null) return null;
    if (endMs <= now.millisecondsSinceEpoch) return null;
    final Duration duration = Duration(milliseconds: durationMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);
    return <String, Object>{
      'StartMinute': now.minute.toString(),
      'StartHour': now.hour.toString(),
      'StartDay': now.day.toString(),
      'StartMonth': now.month.toString(),
      'StartYear': now.year.toString(),
      'EndMinute': end.minute.toString(),
      'EndHour': end.hour.toString(),
      'EndDay': end.day.toString(),
      'EndMonth': end.month.toString(),
      'EndYear': end.year.toString(),
      'DurationHours': duration.inHours.toString(),
      'DurationInMs': duration.inMilliseconds.toString(),
    };
  }
}
