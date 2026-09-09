// The Location data source for the Add Tile redesign.
//
// Extracted to its own library so the picker and the place editor can both
// depend on it without depending on each other — importing one screen from
// the other formed a cycle, which on a case-insensitive filesystem surfaced as
// the same class appearing to come from two differently-cased paths.
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';
import 'package:tiler_app/services/api/locationApi.dart';

/// The data this screen needs, behind an interface so widget tests never
/// touch the API or the platform geolocator.
abstract class AddTileLocationSource {
  /// The quick-pick named places: `home` and `work`, the two nicknames that
  /// exist by default, minus whichever is unset. Any OTHER place the user has
  /// named is reached through [search] — there is no list-all endpoint.
  Future<List<Location>> savedPlaces();

  /// Free-text place search. Covers BOTH the user's saved named places and
  /// map results, so a place named "Ashley's Home" is found by that name.
  Future<List<Location>> search(String query);

  /// The saved place with exactly this name, or `null`. Names are unique per
  /// user and the backend upserts by name, so this is how the place editor
  /// tells "creating a new place" from "moving an existing name onto a new
  /// address".
  Future<Location?> findByName(String name);
}

/// The production [AddTileLocationSource]: the real API plus the platform
/// geolocator.
///
/// [savedPlaces] issues the two nickname lookups the app actually supports and
/// drops whichever is unset, so an unconfigured place never renders an empty
/// row. A failed lookup yields "not set" rather than an error — a missing
/// saved place must not break search or the manual path.
class ApiAddTileLocationSource implements AddTileLocationSource {
  ApiAddTileLocationSource({required this.locationApi});

  final LocationApi locationApi;

  @override
  Future<List<Location>> savedPlaces() async {
    final List<Location?> resolved = await Future.wait(<Future<Location?>>[
      _byNickName(Location.homeLocationNickName),
      _byNickName(Location.workLocationNickName),
    ]);
    // Filtered on CONTENT, not on `isNotNullAndNotDefault` (D53). Home and
    // work are by definition DEFAULT places, so that predicate excluded
    // exactly the two entries this list exists to show whenever the server
    // reported them as such. An unset slot has no name and no address, so
    // content still drops it.
    return resolved.whereType<Location>().where(locationHasContent).toList();
  }

  Future<Location?> _byNickName(String nickName) async {
    try {
      return await locationApi.getSpecificLocationByNickName(nickName);
    } catch (_) {
      return null;
    }
  }

  /// `includeMapSearch: true` returns the user's saved named places AND map
  /// results in one list, which is what makes a nicknamed address findable by
  /// its name after it has been saved.
  @override
  Future<List<Location>> search(String query) =>
      locationApi.getLocationsByName(query);

  /// `getSpecificLocationByNickName` already does exactly this: it searches
  /// with `includeMapSearch: false` (the user's own places only) and filters
  /// to an exact description match.
  @override
  Future<Location?> findByName(String name) async {
    try {
      return await locationApi.getSpecificLocationByNickName(name);
    } catch (_) {
      // A failed lookup means we cannot warn; it must not block a save.
      return null;
    }
  }
}
