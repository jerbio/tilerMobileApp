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
