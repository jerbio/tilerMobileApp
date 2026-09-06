// Phase 4.1 — Location picker for the Add Tile redesign.
//
// Contract settled with the user on 2026-09-05 after reviewing a real API
// response (plan D16/D17/D18).
//
// THE MODEL. A location is an address plus a NICKNAME, and the nickname is how
// a user names a place: 532 Wylie Street becomes "Ashley's Home". `home` and
// `work` are the two nicknames that exist BY DEFAULT; a user may name any
// number of places. There is no list-all endpoint, so other named places are
// found by SEARCH — `getLocationsByName` returns the user's saved places
// alongside provider results in one list.
//
// TYPING THE RESULTS. `source` tells the two apart:
//   * `'none'` (or absent) — the user's own saved place. It also carries a
//     `userId` and a Tiler GUID `id`.
//   * anything else, in practice `'google'` — a provider lookup, whose `id` is
//     its `thirdPartyId`.
// The screen groups on that, so "somewhere I already named" is visually
// distinct from "somewhere Tiler found".
//
// A RESULT WITH NO STREET ADDRESS IS STILL VALID. Typing "bike shop" when no
// such business is found is a supported flow: the generic name is stored and
// the backend resolves it later. Those rows are shown, not filtered, and the
// "Use what you typed" action is a first-class path rather than a fallback.
//
// TAP COMMITS. Tapping a row returns it immediately. This supersedes D10's
// select-then-confirm, so there is no bottom CTA — an earlier revision made
// every pick a two-step transaction for the sake of the rare rename. Naming
// moved to the Add form, where it is an affordance on the chosen value.
//
// Search is proximity-ranked: `getLocationsByName` defaults to
// `includeLocationParams: true`, which sends the device position and can
// trigger the location-permission flow. That is intended (D17) — the picker
// itself offers no "current location" row.
//
// RELATIONSHIP TO `locationRoute.dart`. This screen SUPERSEDES that one for
// the redesign flow: the legacy route is an address field wrapped in the same
// search, plus a nickname field, plus home/work buttons. It is left untouched
// because five OTHER callers still use it (legacy Add Tile, the new-tile
// sheet, auto-add, tile detail, settings integration). Those callers migrate
// and the file is deleted at Phase 5.3 — that is when the duplication ends.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Applies a new nickname to [location], preserving the legacy wire rule.
///
/// `LocationRoute.onProceed` ends with
/// `if (selectedLocation.description != nickNameText) selectedLocation.id = ''`
/// — the backend reads a cleared id as "create a NEW named place" rather than
/// "rename the saved one". Renaming must therefore never rewrite the record
/// the user picked. Returns the same instance, mutated, matching legacy.
Location applyLocationName(Location location, String name) {
  final String trimmed = name.trim();
  if (trimmed == (location.description ?? '').trim()) return location;
  location.description = trimmed;
  location.id = '';
  if (trimmed.isNotEmpty) {
    location.isDefault = false;
    location.isNull = false;
  }
  return location;
}

/// Whether [location] is one of the user's OWN saved places rather than a
/// provider lookup.
///
/// `source` is the discriminator the API gives us:
///   * `'none'` (or absent/empty) — a place the user saved. It also carries a
///     `userId` and a Tiler GUID `id`.
///   * anything else, in practice `'google'` — a provider lookup, whose `id`
///     is the `thirdPartyId`.
///
/// Delegates to [locationNameIsUserOwned] so the picker's grouping and the
/// request mapper's decision about shipping `LocationTag` can never disagree
/// about who owns a place's name — a row shown under "Your places" is exactly
/// a row whose name we will send.
bool isSavedPlace(Location location) => locationNameIsUserOwned(location);

/// True when [value] reads as a machine identifier rather than a place name.
///
/// The search API sometimes returns a bare GUID in `description` — a device
/// run produced a row titled `59b9b29c-0678-476f-bea2-a187a9b0ced6`. Such a
/// value is never shown to the user as a name.
bool _looksLikeIdentifier(String value) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value.trim());
}

/// Human label for a location row.
///
/// The two stored places are keyed by the lowercase nicknames `home` and
/// `work`; those two are TRANSLATED, because they are fixed wire keys rather
/// than text a user chose. Every other description is shown verbatim — a name
/// the user typed is already in their language, and translating it would
/// rename their place. An absent or machine-identifier description falls back
/// to the address, then to a generic label.
///
/// Takes [AppLocalizations] rather than reading a `BuildContext` so it stays
/// pure and unit-testable (D29).
String locationDisplayName(AppLocalizations l10n, Location location) {
  final String raw = (location.description ?? '').trim();
  final String address = (location.address ?? '').trim();
  if (raw.isEmpty || _looksLikeIdentifier(raw)) {
    return address.isNotEmpty ? address : l10n.addTileLocationFallbackName;
  }
  if (raw.toLowerCase() == Location.homeLocationNickName) return l10n.home;
  if (raw.toLowerCase() == Location.workLocationNickName) return l10n.work;
  return raw;
}

/// The address to show BENEATH the name, or `null` when it would merely
/// repeat it. A device run showed a row reading "Walmart" over "Walmart".
String? locationSubtitle(AppLocalizations l10n, Location location) {
  final String address = (location.address ?? '').trim();
  if (address.isEmpty) return null;
  if (address.toLowerCase() ==
      locationDisplayName(l10n, location).toLowerCase()) {
    return null;
  }
  return address;
}

/// Icon for a stored place; other rows fall back to a generic pin.
IconData locationIcon(Location location) {
  switch ((location.description ?? '').trim().toLowerCase()) {
    case Location.homeLocationNickName:
      return Icons.home_outlined;
    case Location.workLocationNickName:
      return Icons.work_outline;
    default:
      return Icons.place_outlined;
  }
}

class AddTileLocationScreen extends StatefulWidget {
  const AddTileLocationScreen({
    super.key,
    required this.source,
    this.initialLocation,
    this.onSelected,
  });

  final AddTileLocationSource source;

  /// Pre-selects a row when the draft already carries a location.
  final Location? initialLocation;

  /// Invoked by the CTA with the confirmed selection. Injected by tests;
  /// in the app the screen pops with the value.
  final void Function(Location)? onSelected;

  @override
  State<AddTileLocationScreen> createState() => _AddTileLocationScreenState();
}

class _AddTileLocationScreenState extends State<AddTileLocationScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Location> _saved = const <Location>[];
  bool _loadingSaved = true;

  List<Location>? _results;
  bool _searching = false;
  bool _searchFailed = false;
  String _query = '';

  Timer? _debounce;

  /// Guards against a slow search landing after a newer one (or after the
  /// field was cleared) and overwriting fresher results.
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final List<Location> places = await widget.source.savedPlaces();
      if (!mounted) return;
      setState(() {
        _saved = _dedupeByNickname(places);
        _loadingSaved = false;
      });
    } catch (_) {
      if (!mounted) return;
      // A failed quick-pick load must not block search or the typed path.
      setState(() => _loadingSaved = false);
    }
  }

  /// Quick-pick rows are keyed by nickname, so the list must not contain two
  /// entries sharing one. Enforced here rather than trusting the source: the
  /// widget owns the key-uniqueness invariant, and the equivalent assumption
  /// about same-named search results crashed on device (2026-09-05).
  static List<Location> _dedupeByNickname(List<Location> places) {
    final Set<String> seen = <String>{};
    return places
        .where((p) => seen.add((p.description ?? '').trim().toLowerCase()))
        .toList();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      _searchGeneration++; // discard anything still in flight
      setState(() {
        _query = '';
        _results = null;
        _searching = false;
        _searchFailed = false;
      });
      return;
    }
    setState(() => _query = trimmed);
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    final int generation = ++_searchGeneration;
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    try {
      final List<Location> found = await widget.source.search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = found;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searching = false;
        _searchFailed = true;
        _results = null;
      });
    }
  }

  /// Tapping a row COMMITS it. There is no select-then-confirm step and no
  /// bottom CTA — picking a place is the whole interaction. Naming happens
  /// afterwards on the Add form, for the minority of places worth naming.
  void _commit(Location location) {
    if (widget.onSelected != null) {
      widget.onSelected!(location);
      return;
    }
    Navigator.of(context).pop(location);
  }

  /// Opens the place editor seeded with the raw query, so an unfound place can
  /// be given a name AND an address in one pass (D19) — "my Walmart near work"
  /// at a specific street is what distinguishes it from another Walmart.
  ///
  /// The query seeds the ADDRESS: the backend copies whichever field is present
  /// into the other, so an address-only save still yields a name, and typing
  /// "bike shop" therefore behaves exactly as it did before this editor existed.
  Future<void> _openPlaceEditor() async {
    final Location? created = await Navigator.of(context).push<Location>(
      MaterialPageRoute<Location>(
        builder: (_) => AddTilePlaceEditorScreen(
          source: widget.source,
          initialAddress: _query,
        ),
      ),
    );
    if (created == null || !mounted) return;
    _commit(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bool isSearching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.location),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SearchField(
              controller: _searchController,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (isSearching)
                  ..._buildSearchArea(l10n, tokens, textTheme)
                else
                  ..._buildBrowseArea(l10n, tokens, textTheme),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: tokens.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.addTileLocationHelper,
                        style: textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeading(String text, TodayStatusTokens tokens, TextTheme t) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          text,
          style: t.labelSmall
              ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6),
        ),
      );

  List<Widget> _buildSearchArea(
      AppLocalizations l10n, TodayStatusTokens tokens, TextTheme textTheme) {
    if (_searching) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_searchFailed) {
      return [
        _Notice(
          key: const ValueKey('locationSearchError'),
          icon: Icons.cloud_off,
          title: l10n.addTileLocationSearchFailed,
          body: l10n.addTileLocationSearchFailedHelper,
        ),
        const SizedBox(height: 12),
        _typedTextSection(l10n),
      ];
    }

    final List<Location> results = _results ?? const <Location>[];
    // `source` types each result: 'none' (or absent) is one of the user's own
    // saved places; anything else — in practice 'google' — is a provider
    // lookup. Grouping on it is what lets a user tell "somewhere I already
    // named" apart from "somewhere Tiler found".
    final List<Location> mine = results.where(isSavedPlace).toList();
    final List<Location> suggestions =
        results.where((l) => !isSavedPlace(l)).toList();

    return [
      if (mine.isNotEmpty) ...[
        _groupHeading(l10n.addTileLocationYourPlaces, tokens, textTheme),
        AddTileSection(
          children: [
            for (final (int index, Location result) in mine.indexed)
              LocationOptionRow(
                // Keyed by POSITION: search legitimately returns several
                // results sharing a name, and a name-based key collides.
                key: ValueKey('savedResult_$index'),
                icon: locationIcon(result),
                title: locationDisplayName(l10n, result),
                subtitle: locationSubtitle(l10n, result),
                onTap: () => _commit(result),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
      if (suggestions.isNotEmpty) ...[
        _groupHeading(l10n.addTileLocationSuggestions, tokens, textTheme),
        AddTileSection(
          children: [
            for (final (int index, Location result) in suggestions.indexed)
              LocationOptionRow(
                key: ValueKey('suggestion_$index'),
                icon: locationIcon(result),
                title: locationDisplayName(l10n, result),
                subtitle: locationSubtitle(l10n, result),
                onTap: () => _commit(result),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
      if (results.isEmpty)
        _Notice(
          key: const ValueKey('locationSearchEmpty'),
          icon: Icons.search_off,
          title: l10n.addTileLocationNoResults,
          body: l10n.addTileLocationNoResultsHelper,
        ),
      if (results.isEmpty) const SizedBox(height: 12),
      // Offered whether or not there were results: naming a generic place is
      // a first-class flow, not just a fallback for an empty list.
      _typedTextSection(l10n),
    ];
  }

  List<Widget> _buildBrowseArea(
      AppLocalizations l10n, TodayStatusTokens tokens, TextTheme textTheme) {
    return [
      _groupHeading(l10n.addTileLocationYourPlaces, tokens, textTheme),
      if (_loadingSaved)
        const Padding(
          key: ValueKey('savedPlacesLoading'),
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_saved.isEmpty)
        _Notice(
          icon: Icons.place_outlined,
          title: l10n.addTileLocationNoneSaved,
          body: l10n.addTileLocationNoneSavedHelper,
        )
      else
        AddTileSection(
          children: [
            for (final Location place in _saved)
              () {
                final String nickname =
                    (place.description ?? '').trim().toLowerCase();
                return LocationOptionRow(
                  key: ValueKey('savedPlace_$nickname'),
                  icon: locationIcon(place),
                  title: locationDisplayName(l10n, place),
                  subtitle: locationSubtitle(l10n, place),
                  onTap: () => _commit(place),
                );
              }(),
          ],
        ),
    ];
  }

  /// Saves the raw query as a named place. See [_commitTypedText].
  Widget _typedTextSection(AppLocalizations l10n) => AddTileSection(
        children: [
          AddTileNavRow(
            key: const ValueKey('useTypedAddress'),
            icon: Icons.add_location_alt_outlined,
            title: l10n.addTileLocationUseTyped(_query),
            subtitle: l10n.addTileLocationUseTypedHelper,
            onTap: _openPlaceEditor,
          ),
        ],
      );
}

/// The rounded search field at the top of the picker.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    return TextField(
      key: const ValueKey('locationSearchField'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.addTileLocationSearchHint,
        prefixIcon: Icon(Icons.search, color: tokens.textSecondary),
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.brand, width: 1.5),
        ),
      ),
    );
  }
}

/// One location row. Tapping it COMMITS that place and closes the screen, so
/// the row carries no selected state — there is nothing to confirm afterwards.
class LocationOptionRow extends StatelessWidget {
  const LocationOptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    AddTileIconChip(icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty)
                            Text(
                              subtitle!,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    // Tapping the row returns to the Add form, so a chevron is
                    // the honest affordance here (§7.1): it goes somewhere.
                    Icon(Icons.chevron_right, color: tokens.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An explanatory empty / error / permission state.
class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
