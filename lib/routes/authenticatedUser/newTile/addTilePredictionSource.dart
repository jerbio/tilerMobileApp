// Name-driven prediction for the Add Tile redesign (legacy parity).
//
// The legacy flow calls `GET api/Schedule/NewTilePrediction` as the user
// types the tile name and pre-populates duration, location and the
// preferred-time restriction profile from the answer — `addTile.dart`'s
// `onTileNameInput` -> `generateSuggestionCallToServer`. It is easy to miss
// because none of it is visible until it fires, but it is the reason a user
// can type "gym" and get 45 minutes without touching Duration.
//
// This library is the redesign's equivalent, split so the policy is pure and
// testable without a network:
//
//   * [shouldRequestPrediction]  — the trigger rule (character threshold);
//   * [predictionFromAutoResult] — the translation of the API's Tuple4 into
//     a value object, including the legacy scrubbing rules;
//   * [AddTilePredictionSource]  — the seam widget tests inject.
//
// WHAT IS DELIBERATELY NOT HERE. Debouncing and the "is this response still
// current?" check live in the caller, next to the state they protect —
// exactly where the Location picker keeps its own generation guard.
//
// This library speaks plain domain values (`Duration`, `Location`,
// `RestrictionProfile`) and knows nothing about `AddTileDraft`, so the
// edit-tile flow can reuse it (D29).
import 'package:flutter/foundation.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tuple/tuple.dart';

/// What the backend predicts from a tile name. Every field is optional: the
/// endpoint answers with whatever it is confident about, and an empty
/// prediction is a normal outcome, not an error.
@immutable
class AddTilePrediction {
  const AddTilePrediction({
    this.duration,
    this.location,
    this.restrictionProfile,
  });

  final Duration? duration;
  final Location? location;
  final RestrictionProfile? restrictionProfile;

  static const AddTilePrediction empty = AddTilePrediction();

  bool get isEmpty =>
      duration == null && location == null && restrictionProfile == null;

  @override
  bool operator ==(Object other) =>
      other is AddTilePrediction &&
      other.duration == duration &&
      other.location == location &&
      other.restrictionProfile == restrictionProfile;

  @override
  int get hashCode => Object.hash(duration, location, restrictionProfile);
}

/// Whether [name] is worth asking about.
///
/// Legacy compares the RAW controller text length against
/// `autoCompleteTriggerCharacterCount` (3), strictly greater — so "gym" does
/// not trigger but "gyms" does. Kept verbatim rather than trimmed: changing
/// it would change which keystroke fires the first request, and the threshold
/// is a product tuning value, not an implementation detail to quietly
/// improve.
bool shouldRequestPrediction(String name) =>
    name.length > Constants.autoCompleteTriggerCharacterCount;

/// The debounce legacy applies between keystroke and request.
const Duration predictionDebounce =
    Duration(milliseconds: Constants.onTextChangeDelayInMs);

/// Translates the prediction endpoint's tuple into an [AddTilePrediction],
/// applying the legacy selection and scrubbing rules.
///
/// The rules, each carried over deliberately:
///
///   * **Duration is the LAST of the list.** `getAutoResult` sorts durations
///     ascending, so `.last` is the LONGEST predicted duration — legacy's
///     choice, and the safer one: an under-booked tile gets rescheduled,
///     an over-booked one merely finishes early.
///   * **Location is the LAST of the list**, matching legacy.
///   * **Placeholder locations are dropped.** A prediction whose address or
///     description is one of `Constants.invalidLocationNames` ("anywhere")
///     means "no particular place" — storing it would put a meaningless
///     string on the wire and in the user's saved places.
///   * **A disabled restriction profile is no profile.** `getAutoResult`
///     returns `RestrictionProfile.noRestriction()` as its "nothing to say"
///     value, which is exactly the draft's absent state.
AddTilePrediction predictionFromAutoResult(
  Tuple4<List<Duration>, List<Location>, RestrictionProfile, List<String>>
      result,
) {
  final Duration? duration = result.item1.isEmpty ? null : result.item1.last;

  Location? location = result.item2.isEmpty ? null : result.item2.last;
  if (location != null && _isPlaceholderLocation(location)) location = null;

  final RestrictionProfile? profile =
      result.item3.isEnabled ? result.item3 : null;

  return AddTilePrediction(
    duration: duration,
    location: location,
    restrictionProfile: profile,
  );
}

/// True when the predicted place is a stand-in for "no particular place".
///
/// Legacy checks the address and the description independently, and only when
/// BOTH are non-null; reproduced here so a prediction carrying just one of
/// them behaves the same way it does today.
bool _isPlaceholderLocation(Location location) {
  final String? address = location.address;
  final String? description = location.description;
  if (address == null || description == null) return false;
  final String lowerAddress = address.toLowerCase();
  final String lowerDescription = description.toLowerCase();
  return Constants.invalidLocationNames.any(
    (name) => name == lowerAddress || name == lowerDescription,
  );
}

/// The prediction seam, so widget tests never touch the network.
abstract class AddTilePredictionSource {
  Future<AddTilePrediction> predict(String name);
}

/// The production source: the real `NewTilePrediction` endpoint.
///
/// A failure yields [AddTilePrediction.empty] rather than propagating. A
/// prediction is a convenience layered on top of a form the user can always
/// fill in themselves, so a failed one must be invisible — never an error
/// state on a screen where nothing has gone wrong.
class ApiAddTilePredictionSource implements AddTilePredictionSource {
  ApiAddTilePredictionSource({required this.scheduleApi});

  final ScheduleApi scheduleApi;

  @override
  Future<AddTilePrediction> predict(String name) async {
    try {
      return predictionFromAutoResult(await scheduleApi.getAutoResult(name));
    } catch (_) {
      return AddTilePrediction.empty;
    }
  }
}
