// Saved-place lookups must run one at a time (D59).
//
// Reported on device as "why is it always on Work". `LocationApi` is
// SINGLE-FLIGHT WITH LAST-WINS COALESCING: while a request is pending, later
// requests are queued, the drain re-issues only the LAST of them, and every
// waiter is handed that one result. It is a search-as-you-type debounce, and it
// is correct for that.
//
// `savedPlaces()` fired `home` and `work` concurrently. `work` was queued
// behind `home`, the drain answered both with the work list, and the home
// lookup filtered that list for a description of "home" — found nothing, and
// returned null. Only Work ever survived. Legacy chains the two lookups
// sequentially for exactly this reason.
//
// The fake below reproduces the coalescing faithfully rather than stubbing
// answers, so the test fails on the real defect and not on a detail of the
// fake.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/services/api/locationApi.dart';

Location _place(String nickname) => Location.fromJson(<String, dynamic>{
      'id': 'guid-$nickname',
      'userId': 'user-1',
      'description': nickname,
      'address': '$nickname street',
      'source': 'none',
      'isNull': false,
      'isDefault': true,
    });

/// A `LocationApi` with the production client's coalescing semantics.
///
/// The first call in flight owns the request. Calls arriving while it is
/// pending are queued; when the first completes, only the LAST queued name is
/// actually answered, and EVERY waiter receives that answer.
class CoalescingLocationApi extends LocationApi {
  CoalescingLocationApi() : super(getContextCallBack: () => null);

  Completer<Location?>? _inFlight;
  String? _lastRequested;
  final List<String> issued = <String>[];

  @override
  Future<Location?> getSpecificLocationByNickName(String name) async {
    if (_inFlight != null) {
      // Queued behind the pending request: the drain will answer with
      // whichever name was queued last, to everyone.
      _lastRequested = name;
      final Location? shared = await _inFlight!.future;
      return _filter(shared, name);
    }
    _inFlight = Completer<Location?>();
    _lastRequested = name;
    await Future<void>.delayed(Duration.zero); // let concurrent calls queue
    issued.add(_lastRequested!);
    final Location? answer = _place(_lastRequested!);
    final Completer<Location?> done = _inFlight!;
    _inFlight = null;
    done.complete(answer);
    return _filter(answer, name);
  }

  /// `getSpecificLocationByNickName` filters the shared list for an exact
  /// description match, so a caller handed the wrong place gets nothing.
  Location? _filter(Location? shared, String wanted) =>
      shared != null && shared.description == wanted ? shared : null;
}

void main() {
  test('both saved places are found, not just the last one requested',
      () async {
    final api = CoalescingLocationApi();
    final source = ApiAddTileLocationSource(locationApi: api);

    final List<Location> places = await source.savedPlaces();

    expect(
      places.map((p) => p.description).toList(),
      containsAll(<String>['home', 'work']),
      reason: 'concurrent lookups collapse to the last one issued, so home '
          'is silently lost and the list is always just Work',
    );
  });

  test('the lookups are issued one at a time', () async {
    // The mechanism, not just the outcome: each nickname must be its own
    // request, which only happens when the second waits for the first.
    final api = CoalescingLocationApi();
    await ApiAddTileLocationSource(locationApi: api).savedPlaces();

    expect(api.issued, <String>['home', 'work']);
  });
}
