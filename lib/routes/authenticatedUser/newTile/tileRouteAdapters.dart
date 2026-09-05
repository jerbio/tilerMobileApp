// Phase 2.2 — Typed adapters for the legacy map-based Location and Repeat
// routes.
//
// The legacy `/LocationRoute` and `/RepetitionRoute` are driven through a
// shared `Map` argument: the parent pushes `arguments: <map>`, the route
// mutates that SAME map instance in place (by-reference), and the parent
// reads the result back after pop. These adapters wrap those legacy
// `Navigator.pushNamed` calls and translate the results into typed values:
//
//   * [openLocationRoute] -> `Future<Location?>`
//     The legacy contract is preserved exactly: args are
//     `{ 'location': holder }` (+ optional `'defaults': List<Location>`).
//     `LocationRoute.onProceed` is the ONLY code path that writes the
//     `'location'` key (cancel never writes it), so the args map is wrapped
//     in [_LocationRouteArgs] to observe that write:
//       proceed -> returns the written Location (applied via
//                  AddTileDraft.setLocation by the caller)
//       cancel  -> returns null (no-op; the draft is left untouched)
//
//   * [openRepeatRoute] -> `Future<RepeatRouteResult>`
//     Args mirror the legacy parent exactly: `{ 'repetitionData': clone,
//     'tileTimeline': today 00:00 -> endTime ?? today 23:59 }`. The legacy
//     result keys are `'updatedRepetition'` (proceed only) and
//     `'isRepetitionEndValid'` (proceed AND cancel — on cancel it is the
//     route's deadline validity at pop time). The legacy parent semantics
//     are preserved verbatim:
//       proceed + enabled + valid      -> apply (the updated repetition)
//       proceed + enabled + invalid    -> clear the draft's repetition
//       proceed + disabled + valid     -> unchanged (legacy left it alone)
//       cancel  + valid                -> unchanged
//       cancel  + invalid deadline     -> clear (legacy cleared here too)
//
// No legacy route file is modified — the adapters add no keys to the
// argument maps (only the legacy keys are ever present), and a push to an
// unregistered route (e.g. the test harness) resolves to a no-op, matching
// the shell's existing duration-picker convention. Analytics signals are
// intentionally NOT sent here: the legacy callers keep their own signals
// and the redesigned flow carries its own (flow_version) telemetry.
library;

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/util.dart';

/// What a `/RepetitionRoute` result means for the draft.
enum RepeatRouteAction {
  /// Store [RepeatRouteResult.repetition] (the route-confirmed data).
  apply,

  /// Clear the draft's repetition (invalid repeat end — legacy behavior on
  /// both the proceed and the cancel path).
  clear,

  /// The draft's repetition is left untouched (cancel with a valid end, or
  /// a proceed with a disabled/`none` selection).
  unchanged,
}

/// A typed `/RepetitionRoute` outcome: what to do, plus the repetition to
/// store when the action is [RepeatRouteAction.apply].
class RepeatRouteResult {
  const RepeatRouteResult(this.action, [this.repetition]);

  final RepeatRouteAction action;

  /// Only meaningful for [RepeatRouteAction.apply].
  final RepetitionData? repetition;
}

/// The pure decision core of [openRepeatRoute], kept separate from
/// `Navigator` so the legacy semantics are unit-testable.
///
/// Mirrors the legacy parent's `whenComplete` block in `addTile.dart`
/// verbatim, including its ordering: an enabled repetition is stored only
/// when the end is valid, and an INVALID end clears the draft on both the
/// proceed and the cancel path (the legacy code ran that second `if`
/// unconditionally).
///
/// [isRepetitionEndValid] defaults to `true` for a missing key, matching the
/// legacy `bool isRepetitionEndValid = true;` initializer.
RepeatRouteResult resolveRepeatRouteResult({
  required RepetitionData? updatedRepetition,
  required bool isRepetitionEndValid,
}) {
  if (!isRepetitionEndValid) {
    // Legacy cleared here regardless of how the route was dismissed.
    return const RepeatRouteResult(RepeatRouteAction.clear);
  }
  if (updatedRepetition != null && updatedRepetition.isEnabled) {
    return RepeatRouteResult(RepeatRouteAction.apply, updatedRepetition);
  }
  // Cancel, or a proceed with a disabled/`none` selection: legacy left the
  // parent's repetition untouched.
  return const RepeatRouteResult(RepeatRouteAction.unchanged);
}

/// Applies a [RepeatRouteResult] to [draft].
///
/// [RepeatRouteAction.unchanged] is a true no-op: it must not touch the
/// draft, so a cancelled picker never marks the draft dirty.
void applyRepeatRouteResult(AddTileDraft draft, RepeatRouteResult result) {
  switch (result.action) {
    case RepeatRouteAction.apply:
      draft.setRepetitionData(result.repetition);
    case RepeatRouteAction.clear:
      draft.setRepetitionData(null);
    case RepeatRouteAction.unchanged:
      break;
  }
}

/// Opens the legacy `/RepetitionRoute` and returns the typed outcome.
///
/// Legacy argument contract (preserved exactly): a CLONE of the current
/// repetition under `'repetitionData'`, plus a `'tileTimeline'` running from
/// today's start to [deadline] — or to today 23:59 when there is no
/// deadline. Cloning matters: the route mutates the object it is handed, so
/// passing the draft's own instance would edit the draft even on cancel.
///
/// An unregistered route (test harness) resolves to
/// [RepeatRouteAction.unchanged], matching the duration picker's convention.
Future<RepeatRouteResult> openRepeatRoute(
  BuildContext context, {
  RepetitionData? current,
  DateTime? deadline,
}) async {
  final Timeline today = Utility.todayTimeline();
  final DateTime start = today.startTime;
  final Timeline tileTimeline = Timeline.fromDateTime(
    start,
    deadline ?? DateTime(start.year, start.month, start.day, 23, 59),
  );
  final Map<String, dynamic> args = <String, dynamic>{
    'repetitionData': current?.clone(),
    'tileTimeline': tileTimeline,
  };
  try {
    await Navigator.of(context).pushNamed('/RepetitionRoute', arguments: args);
  } catch (_) {
    return const RepeatRouteResult(RepeatRouteAction.unchanged);
  }
  return resolveRepeatRouteResult(
    updatedRepetition: args['updatedRepetition'] as RepetitionData?,
    // Legacy: absent key => true; a present null => false.
    isRepetitionEndValid: args.containsKey('isRepetitionEndValid')
        ? (args['isRepetitionEndValid'] as bool? ?? false)
        : true,
  );
}

/// Opens the legacy `/LocationRoute` and returns the confirmed location.
///
/// Legacy argument contract (preserved exactly):
///   `{ 'location': holder }` where holder is [currentLocation] or a fresh
///   `Location.fromDefault()` (the legacy `_location ?? Location.fromDefault()`),
///   plus `'defaults': List<Location>` only when [defaults] is non-empty
///   (the legacy home/work quick-pick list).
///
/// Returns the route-written `Location` on confirm, or `null` on cancel /
/// an unregistered route — the caller must treat `null` as a no-op and not
/// touch the draft.
Future<Location?> openLocationRoute(
  BuildContext context, {
  Location? currentLocation,
  List<Location>? defaults,
}) async {
  final _LocationRouteArgs args = _LocationRouteArgs(<String, dynamic>{
    'location': currentLocation ?? Location.fromDefault(),
    if (defaults != null && defaults.isNotEmpty) 'defaults': defaults,
  });
  try {
    await Navigator.of(context).pushNamed('/LocationRoute', arguments: args);
  } catch (_) {
    return null; // route not registered (test harness) — no crash, no change.
  }
  // [LocationRoute.onProceed] is the only path that writes 'location' —
  // cancel (or any other pop) leaves the flag unset.
  return args.locationWritten ? (args['location'] as Location?) : null;
}

/// A [Map] that records when the Location route's proceed path writes the
/// legacy `'location'` result key.
///
/// `LocationRoute.build` receives THIS map (the `arguments` we pushed is
/// the same instance `ModalRoute.settings.arguments` resolves to) and its
/// `onProceed` writes `locationArgs['location'] = selectedLocation` — the
/// ONLY write to that key; `onCancel` never writes it. Because the route
/// may write back the very same holder instance it was given (the user
/// pressed confirm without changing anything), an identity check cannot
/// distinguish confirm from cancel; the `[]=` observation can.
///
/// All other map behavior (reads, `containsKey`, the template's
/// `cancelAndProceedData` bookkeeping key) is unchanged, so the legacy
/// route and any legacy consumer see exactly the same contract.
class _LocationRouteArgs extends MapMixin<String, dynamic> {
  _LocationRouteArgs(Map<String, dynamic> initial) : _data = Map.of(initial);

  final Map<String, dynamic> _data;
  bool _locationWritten = false;

  /// True once the route's proceed path has written the `'location'` key.
  bool get locationWritten => _locationWritten;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, dynamic value) {
    if (key == 'location') _locationWritten = true;
    _data[key] = value;
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  int get length => _data.length;

  // `MapMixin` requires both mutators. They delegate straight through so the
  // legacy route (and the shared cancel/proceed template's bookkeeping key)
  // sees an ordinary map; only the `'location'` write is observed above.
  @override
  dynamic remove(Object? key) => _data.remove(key);

  @override
  void clear() => _data.clear();
}
