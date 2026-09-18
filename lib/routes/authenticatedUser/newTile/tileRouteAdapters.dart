// Typed adapter for the one legacy map-based secondary route still in use:
// `/TimeRestrictionRoute`, the ADVANCED preferred-time profile editor.
//
// The legacy route is driven through a shared `Map` argument: the parent
// pushes `arguments: <map>`, the route mutates that SAME map instance in
// place (by-reference), and the parent reads the result back after pop.
// This adapter wraps that `Navigator.pushNamed` and translates the result
// into a typed value.
//
// The Location, Repeat and Color adapters that used to live beside it were
// removed in Step 5.3 (D66): the redesign has its own pickers for all three
// (`addTileLocationScreen.dart`, `addTileRepeatScreen.dart`,
// `addTileColorScreen.dart`) and the legacy routes they wrapped are gone.
//
// A push to an unregistered route (e.g. the test harness) resolves to a
// no-op. Analytics signals are intentionally NOT sent here: the redesigned
// flow carries its own (flow_version) telemetry.
library;

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/restrictionProfile.dart';

/// Opens the legacy `/TimeRestrictionRoute` for the ADVANCED preferred-time
/// profile (named work/personal hours, custom per-day windows) — the cases
/// the four simple day parts cannot express.
///
/// Legacy argument contract: `'routeRestrictionProfile'` is an in/out slot
/// seeded with the current profile, plus `'stackRouteHistory'` and the
/// optional `'namedRestrictionProfiles'` list.
///
/// A confirmed `null` is meaningful (it means Anytime), so the write itself is
/// observed rather than the value: the result is
/// [AdvancedRestrictionResult.written] only when the route actually wrote the
/// slot. This is a deliberate, payload-neutral divergence from the legacy
/// parent, which re-applied the seeded value on cancel too — identical wire
/// output, but the draft is no longer marked dirty by a cancelled picker.
Future<AdvancedRestrictionResult> openAdvancedRestrictionRoute(
  BuildContext context, {
  RestrictionProfile? current,
  List<Object>? namedProfiles,
  String? parentRouteName,
}) async {
  final _ObservedArgs args = _ObservedArgs(
    <String, dynamic>{
      'routeRestrictionProfile': current,
      // A `List<String>`, never `List<String?>`: the legacy route assigns
      // this straight into a `List<String>` local, so a nullable element
      // type throws before it can read anything (D57).
      'stackRouteHistory': <String>[
        if (parentRouteName != null) parentRouteName,
      ],
      if (namedProfiles != null && namedProfiles.isNotEmpty)
        'namedRestrictionProfiles': namedProfiles,
    },
    watchKey: 'routeRestrictionProfile',
  );
  try {
    await Navigator.of(context)
        .pushNamed('/TimeRestrictionRoute', arguments: args);
  } catch (_) {
    return const AdvancedRestrictionResult.unchanged();
  }
  return args.written
      ? AdvancedRestrictionResult.written(
          args['routeRestrictionProfile'] as RestrictionProfile?)
      : const AdvancedRestrictionResult.unchanged();
}

/// Outcome of the advanced preferred-time route. Distinguishes "the route
/// confirmed a value (possibly `null`, meaning Anytime)" from "the route was
/// dismissed without choosing".
class AdvancedRestrictionResult {
  const AdvancedRestrictionResult.written(this.profile) : didWrite = true;
  const AdvancedRestrictionResult.unchanged()
      : profile = null,
        didWrite = false;

  final RestrictionProfile? profile;
  final bool didWrite;
}

/// A [Map] that records when a route's proceed path writes [watchKey].
///
/// The legacy route uses a by-reference argument map whose result slot is
/// seeded with the CURRENT value, so an identity or equality check cannot
/// tell "confirmed unchanged" from "cancelled" — and a written `null` is
/// itself a meaningful answer. Observing the `[]=` call can.
///
/// `TimeRestrictionRoute` receives THIS map (the `arguments` we pushed is
/// the same instance `ModalRoute.settings.arguments` resolves to) and its
/// proceed path writes `params['routeRestrictionProfile']`; cancel never
/// writes it.
///
/// All other map behavior (reads, `containsKey`, the template's
/// `cancelAndProceedData` bookkeeping key) is unchanged, so the legacy
/// route sees exactly the same contract.
class _ObservedArgs extends MapMixin<String, dynamic> {
  _ObservedArgs(Map<String, dynamic> initial, {required this.watchKey})
      : _data = Map.of(initial);

  final Map<String, dynamic> _data;

  /// The legacy result key whose write signals "the route confirmed".
  final String watchKey;

  bool _written = false;

  /// True once the route's proceed path has written [watchKey].
  bool get written => _written;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, dynamic value) {
    if (key == watchKey) _written = true;
    _data[key] = value;
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  int get length => _data.length;

  // `MapMixin` requires both mutators. They delegate straight through so the
  // legacy route (and the shared cancel/proceed template's bookkeeping key)
  // sees an ordinary map; only the [watchKey] write is observed above.
  @override
  dynamic remove(Object? key) => _data.remove(key);

  @override
  void clear() => _data.clear();
}
