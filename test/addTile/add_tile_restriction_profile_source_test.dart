// Step 6.2 — the named-profile source seam behind the Time restrictions
// screen: the API mapping of `work` / `personal`, saving a shared profile by
// type (D67), and the per-session cache that makes the load single-flight and
// lets Retry re-fetch after a failure (D73).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

import 'restriction_hours_draft_test.dart' as fx;

class FakeSettingsApi extends SettingsApi {
  FakeSettingsApi() : super(getContextCallBack: () => null);

  Map<String, RestrictionProfile> loaded = <String, RestrictionProfile>{};
  Object? loadFailure;
  int loads = 0;

  final List<(RestrictionProfile, String?)> saves =
      <(RestrictionProfile, String?)>[];
  RestrictionProfile? saveAnswer;
  Object? saveFailure;

  @override
  Future<Map<String, RestrictionProfile>> getUserRestrictionProfile() async {
    loads++;
    final Object? f = loadFailure;
    if (f != null) throw f;
    return loaded;
  }

  @override
  Future<RestrictionProfile> updateRestrictionProfile(
      RestrictionProfile restrictionProfile,
      {String? restrictionProfileType}) async {
    saves.add((restrictionProfile, restrictionProfileType));
    final Object? f = saveFailure;
    if (f != null) throw f;
    return saveAnswer ?? restrictionProfile;
  }
}

/// A source whose [load] completes when the test says so.
class GatedSource implements AddTileRestrictionProfileSource {
  int loads = 0;
  Completer<NamedRestrictionProfiles> gate =
      Completer<NamedRestrictionProfiles>();

  @override
  Future<NamedRestrictionProfiles> load() {
    loads++;
    return gate.future;
  }

  @override
  Future<RestrictionProfile> save(
          RestrictionProfile profile, NamedRestrictionProfileType type) async =>
      profile;
}

void main() {
  group('ApiAddTileRestrictionProfileSource', () {
    test('maps the server keys to work and personal, case-insensitively',
        () async {
      final FakeSettingsApi api = FakeSettingsApi()
        ..loaded = <String, RestrictionProfile>{
          'Work': fx.weekdays(id: 'w'),
          'PERSONAL': fx.weekdays(id: 'p'),
          'other': fx.weekdays(id: 'o'),
        };
      final NamedRestrictionProfiles named =
          await ApiAddTileRestrictionProfileSource(settingsApi: api).load();
      expect(named.work?.id, 'w');
      expect(named.personal?.id, 'p');
      expect(named[NamedRestrictionProfileType.work]?.id, 'w');
      expect(named[NamedRestrictionProfileType.personal]?.id, 'p');
    });

    test('either profile may be missing', () async {
      final FakeSettingsApi api = FakeSettingsApi()
        ..loaded = <String, RestrictionProfile>{'work': fx.weekdays(id: 'w')};
      final NamedRestrictionProfiles named =
          await ApiAddTileRestrictionProfileSource(settingsApi: api).load();
      expect(named.work, isNotNull);
      expect(named.personal, isNull);
    });

    test('a load failure propagates (the screen shows the callout, D73)',
        () async {
      final FakeSettingsApi api = FakeSettingsApi()
        ..loadFailure = TilerError(Message: 'down');
      expect(ApiAddTileRestrictionProfileSource(settingsApi: api).load(),
          throwsA(isA<TilerError>()));
    });

    test('save posts the profile under its wire type and returns the copy',
        () async {
      final RestrictionProfile serverCopy = fx.weekdays(id: 'w-2');
      final FakeSettingsApi api = FakeSettingsApi()..saveAnswer = serverCopy;
      final ApiAddTileRestrictionProfileSource source =
          ApiAddTileRestrictionProfileSource(settingsApi: api);
      final RestrictionProfile edited = fx.weekdays(id: 'w');
      final RestrictionProfile out =
          await source.save(edited, NamedRestrictionProfileType.work);
      expect(identical(out, serverCopy), isTrue);
      expect(api.saves.single.$1, same(edited));
      // The same strings Tile Preferences' bloc sends.
      expect(api.saves.single.$2, 'work');
      await source.save(edited, NamedRestrictionProfileType.personal);
      expect(api.saves.last.$2, 'personal');
    });

    test('a save failure propagates', () async {
      final FakeSettingsApi api = FakeSettingsApi()
        ..saveFailure = TilerError(Message: 'no');
      expect(
          ApiAddTileRestrictionProfileSource(settingsApi: api)
              .save(fx.weekdays(), NamedRestrictionProfileType.work),
          throwsA(isA<TilerError>()));
    });
  });

  group('CachedRestrictionProfileSource', () {
    test('concurrent loads share ONE request; later loads reuse the answer',
        () async {
      final GatedSource inner = GatedSource();
      final CachedRestrictionProfileSource cached =
          CachedRestrictionProfileSource(inner);
      final Future<NamedRestrictionProfiles> a = cached.load();
      final Future<NamedRestrictionProfiles> b = cached.load();
      expect(inner.loads, 1, reason: 'single-flight');
      inner.gate.complete(NamedRestrictionProfiles(work: fx.weekdays(id: 'w')));
      expect((await a).work?.id, 'w');
      expect((await b).work?.id, 'w');
      final NamedRestrictionProfiles again = await cached.load();
      expect(again.work?.id, 'w');
      expect(inner.loads, 1, reason: 'cached for the session');
      expect(cached.current?.work?.id, 'w',
          reason: 'synchronous read for the chip label');
    });

    test('a failure is not cached: the next load (Retry) asks again', () async {
      final GatedSource inner = GatedSource();
      final CachedRestrictionProfileSource cached =
          CachedRestrictionProfileSource(inner);
      final Future<NamedRestrictionProfiles> first = cached.load();
      inner.gate.completeError(TilerError(Message: 'down'));
      await expectLater(first, throwsA(isA<TilerError>()));
      expect(cached.current, isNull);
      inner.gate = Completer<NamedRestrictionProfiles>();
      final Future<NamedRestrictionProfiles> second = cached.load();
      expect(inner.loads, 2);
      inner.gate.complete(const NamedRestrictionProfiles());
      expect((await second).work, isNull);
    });

    test('a save replaces that profile in the cache', () async {
      final GatedSource inner = GatedSource();
      final CachedRestrictionProfileSource cached =
          CachedRestrictionProfileSource(inner);
      inner.gate.complete(NamedRestrictionProfiles(
          work: fx.weekdays(id: 'w'), personal: fx.weekdays(id: 'p')));
      await cached.load();
      final RestrictionProfile edited = fx.weekdays(id: 'w', start: fx.ten);
      await cached.save(edited, NamedRestrictionProfileType.work);
      expect(cached.current?.work, same(edited));
      expect(cached.current?.personal?.id, 'p', reason: 'the other is kept');
      expect(inner.loads, 1);
    });
  });
}
