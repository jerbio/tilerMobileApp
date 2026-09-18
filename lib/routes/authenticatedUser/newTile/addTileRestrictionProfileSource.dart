// The named restriction profiles (Work hours / Personal hours) behind the
// Time restrictions screen (Step 6.2, D67, D73).
//
// The legacy Add Tile fetched `SettingsApi.getUserRestrictionProfile()` on
// open and handed the result to the legacy time-restriction route; the redesign's
// adapter never did, which is how Work and Personal vanished from the add
// flow. This seam brings them back behind an interface widget tests can fake,
// and adds the one thing the mockup asks for that legacy never had: saving an
// edited profile back under its type — the SHARED profile, the same call Tile
// Preferences makes (D67).
import 'dart:async';

import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

/// The two profiles the server names. The wire strings are the ones Tile
/// Preferences' bloc sends (`Constants.workProfileNickName` /
/// `homeProfileNickName`).
enum NamedRestrictionProfileType {
  work,
  personal;

  String get wireName => switch (this) {
        work => Constants.workProfileNickName,
        personal => Constants.homeProfileNickName,
      };
}

/// What [AddTileRestrictionProfileSource.load] answers. Either may be
/// missing: a user who never set one up has no row to select (D73).
class NamedRestrictionProfiles {
  const NamedRestrictionProfiles({this.work, this.personal});

  final RestrictionProfile? work;
  final RestrictionProfile? personal;

  RestrictionProfile? operator [](NamedRestrictionProfileType type) =>
      switch (type) {
        NamedRestrictionProfileType.work => work,
        NamedRestrictionProfileType.personal => personal,
      };

  NamedRestrictionProfiles withProfile(
          NamedRestrictionProfileType type, RestrictionProfile? profile) =>
      switch (type) {
        NamedRestrictionProfileType.work =>
          NamedRestrictionProfiles(work: profile, personal: personal),
        NamedRestrictionProfileType.personal =>
          NamedRestrictionProfiles(work: work, personal: profile),
      };
}

/// The data the Time restrictions screen and the Custom hours editor need,
/// behind an interface so widget tests never touch the API.
abstract class AddTileRestrictionProfileSource {
  /// The user's named profiles. Throws on failure; the screen shows a callout
  /// with Retry and keeps Anytime and Custom usable (D73).
  Future<NamedRestrictionProfiles> load();

  /// Saves an edited profile as the user's [type] profile and returns the
  /// server's copy (D67). Throws on failure.
  Future<RestrictionProfile> save(
      RestrictionProfile profile, NamedRestrictionProfileType type);
}

/// The production source over [SettingsApi].
class ApiAddTileRestrictionProfileSource
    implements AddTileRestrictionProfileSource {
  ApiAddTileRestrictionProfileSource({required this.settingsApi});

  final SettingsApi settingsApi;

  @override
  Future<NamedRestrictionProfiles> load() async {
    final Map<String, RestrictionProfile> byType =
        await settingsApi.getUserRestrictionProfile();
    RestrictionProfile? find(NamedRestrictionProfileType type) {
      for (final MapEntry<String, RestrictionProfile> e in byType.entries) {
        if (e.key.toLowerCase() == type.wireName) return e.value;
      }
      return null;
    }

    return NamedRestrictionProfiles(
        work: find(NamedRestrictionProfileType.work),
        personal: find(NamedRestrictionProfileType.personal));
  }

  @override
  Future<RestrictionProfile> save(
          RestrictionProfile profile, NamedRestrictionProfileType type) =>
      settingsApi.updateRestrictionProfile(profile,
          restrictionProfileType: type.wireName);
}

/// One load per Add Tile session, single-flight: concurrent callers share the
/// pending request, later callers get the answer, and a failure is NOT kept
/// so Retry asks again. A save replaces that profile in the cache, so the
/// screen's row and the form's chip label read the edited hours without a
/// second fetch.
class CachedRestrictionProfileSource
    implements AddTileRestrictionProfileSource {
  CachedRestrictionProfileSource(this._inner);

  final AddTileRestrictionProfileSource _inner;
  Future<NamedRestrictionProfiles>? _pending;
  NamedRestrictionProfiles? _current;

  /// The last successful answer, for synchronous reads (the chip label).
  NamedRestrictionProfiles? get current => _current;

  @override
  Future<NamedRestrictionProfiles> load() {
    final NamedRestrictionProfiles? have = _current;
    if (have != null) return Future<NamedRestrictionProfiles>.value(have);
    final Future<NamedRestrictionProfiles>? inFlight = _pending;
    if (inFlight != null) return inFlight;
    final Future<NamedRestrictionProfiles> request =
        _inner.load().then((NamedRestrictionProfiles named) {
      _current = named;
      _pending = null;
      return named;
    }, onError: (Object e, StackTrace st) {
      _pending = null;
      throw e;
    });
    _pending = request;
    return request;
  }

  @override
  Future<RestrictionProfile> save(
      RestrictionProfile profile, NamedRestrictionProfileType type) async {
    final RestrictionProfile saved = await _inner.save(profile, type);
    _current =
        (_current ?? const NamedRestrictionProfiles()).withProfile(type, saved);
    return saved;
  }
}
