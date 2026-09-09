// Who named a place: the user, or a map provider?
//
// This one question drives two things, so it lives in a small neutral library
// both can depend on:
//   * the Location picker groups results into "Your places" vs "Suggestions";
//   * the request mapper decides whether to ship `LocationTag`.
//
// It matters on the wire because `LocationTag` IS the backend Name, and the
// backend upserts places by name. Shipping a provider's business name means
// every "Walmart Supercenter" a user visits overwrites the previous one.
import 'package:tiler_app/data/location.dart';

/// Sources that name places on the PROVIDER's terms rather than the user's.
///
/// From a real API response: `source: 'google'` is a direct provider lookup
/// (its `id` is the `thirdPartyId`, `userId` is null), while `source: 'none'`
/// is one of the user's own saved places.
///
/// Membership is an allow-list of KNOWN providers rather than "anything that
/// is not none". An unrecognised source — `custom`, say, which is a
/// user-created location — must default to the user, because the cost of
/// guessing wrong in that direction is merely a slightly odd saved name,
/// whereas guessing the other way silently discards a name the user chose.
const Set<String> providerLocationSources = <String>{'google'};

/// Whether [location] came from a map provider rather than the user.
bool locationIsProviderSourced(Location location) =>
    providerLocationSources.contains(
      (location.source ?? '').trim().toLowerCase(),
    );

/// Whether [location]'s name belongs to the USER.
///
/// True for saved places, hand-created places, and anything whose source we do
/// not recognise. False only for a known provider lookup, whose `description`
/// is a business name shared by every branch of the chain.
bool locationNameIsUserOwned(Location location) =>
    !locationIsProviderSourced(location);

/// Whether [location] carries something the user actually chose.
///
/// NOT `isNotNullAndNotDefault` (D53). Those flags describe the location's
/// RESOLUTION state on the backend — `isNull` means no location value was
/// set, `isDefault` means it is an entity's default place — and neither
/// answers the only question the form asks, which is whether the user picked
/// something. Gating on them was wrong in both directions:
///
///   * a saved place with a NAME but no resolved address read as absent, so
///     the row said "Not set" while the draft was holding it, and the rename
///     affordance disappeared. D18 already made name-only places a
///     first-class choice — typing "bike shop" stores the name for the
///     backend to resolve later;
///   * home and work ARE default places, so `isDefault` filtered them out of
///     the quick-pick list whose whole purpose is to offer them.
///
/// Content is the honest test, and it still rejects the absent sentinel:
/// `Location.fromDefault()` has neither a name nor an address. It also does
/// not depend on the server sending two booleans — `Location.fromJson`
/// leaves both at their `true` defaults when the keys are missing, which
/// made EVERY such result read as absent regardless of what it contained.
bool locationHasContent(Location? location) {
  if (location == null) return false;
  final String description = (location.description ?? '').trim();
  final String address = (location.address ?? '').trim();
  return description.isNotEmpty || address.isNotEmpty;
}
