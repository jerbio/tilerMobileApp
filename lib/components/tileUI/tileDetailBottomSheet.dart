import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Show the tile detail bottom sheet (name, time range, duration, location,
/// time scrub for the active tile, and playback controls). Mirrors the
/// information the compact list tile hides, so tapping a compact tile surfaces
/// the full detail without the tall inline card.
Future<void> showTileDetailBottomSheet(
  BuildContext context,
  SubCalendarEvent subEvent, {
  bool preview = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        TileDetailBottomSheet(subEvent: subEvent, preview: preview),
  );
}

/// Slide-up detail sheet for a [SubCalendarEvent].
///
/// Surfaces the details the compact list tile collapses away: the full
/// (multi-line) name, time range + duration badge, the location badge (tap to
/// open maps/URL), the [TimeScrubWidget] when the tile is currently active
/// (`isCurrentTimeWithin` — i.e. interferes with the current time), and the
/// [PlayBack] controls (play/pause, defer, complete, delete).
class TileDetailBottomSheet extends StatelessWidget {
  final SubCalendarEvent subEvent;
  final bool preview;

  const TileDetailBottomSheet({
    Key? key,
    required this.subEvent,
    this.preview = false,
  }) : super(key: key);

  /// Test key for the sheet's tappable body (whole sheet = edit), mirroring
  /// the grid's `TileGridWidgetState.sheetEditTargetKey` so the list sheet
  /// carries the same tap-out affordance.
  static const Key sheetEditTargetKey = ValueKey('tileDetail_sheet_edit');

  /// Opens the edit flow for [subEvent] — the same `EditTile` route, with the
  /// same id / source resolution, as the list card's tap
  /// (`EnhancedTileCard`). Closes the sheet first so the edit screen comes
  /// back to the list, not to a stale sheet.
  void _openEditFlow(BuildContext sheetContext) {
    debugPrint('TDS: _openEditFlow called');
    final navigator = Navigator.of(sheetContext);
    navigator.pop();
    debugPrint('TDS: after pop, canPop=${navigator.canPop()}');
    navigator.push(
      MaterialPageRoute(
        builder: (context) => EditTile(
          tileId:
              (subEvent.isFromTiler ? subEvent.id : subEvent.thirdpartyId) ??
                  "",
          tileSource: subEvent.thirdpartyType,
          thirdPartyUserId: subEvent.thirdPartyUserId,
        ),
      ),
    );
  }

  String _formatTimeRange(BuildContext context) {
    final startTime = subEvent.startTime;
    final endTime = subEvent.endTime;
    final startFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(startTime));
    final endFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(endTime));
    return '$startFormatted - $endFormatted';
  }

  String? _getLocationText() {
    if (subEvent.addressDescription?.isNotEmpty == true) {
      return subEvent.addressDescription;
    }
    if (subEvent.address?.isNotEmpty == true) {
      return subEvent.address;
    }
    if (subEvent.searchdDescription?.isNotEmpty == true) {
      return subEvent.searchdDescription;
    }
    return null;
  }

  Future<void> _onLocationTap(
      BuildContext context, String addressLookup) async {
    String? link = Utility.getLinkFromLocation(addressLookup);
    if (link != null) {
      final Uri url = Uri.parse(link);
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
      return;
    }
    MapsLauncher.launchQuery(addressLookup);
  }

  /// Localized duration string. Falls back to the non-localized form when
  /// `AppLocalizations` is not resolvable (e.g. a widget-test harness that
  /// pushes the sheet in a context without the app's localization delegate) so
  /// the badge never crashes; in production it is always localized.
  String _durationLabel(BuildContext context) {
    return AppLocalizations.of(context) != null
        ? subEvent.duration.toHumanLocalized(context)
        : subEvent.duration.toHuman;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    final location = _getLocationText();
    final isCurrent = subEvent.isCurrentTimeWithin;
    final isTardy = subEvent.isTardy ?? false;

    final Widget body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title row: name + duration badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subEvent.name ?? '',
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _durationLabel(context),
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Time range (+ tardy cue)
            Row(
              children: [
                if (isTardy) ...[
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: TileColors.late),
                  const SizedBox(width: 6),
                ],
                Text(
                  _formatTimeRange(context),
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Location badge (tap to open maps / URL)
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _onLocationTap(context, location),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: onSurfaceVariant.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: TileTextStyles.rubikFontName,
                              fontSize: 12,
                              color: onSurfaceVariant,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Time scrub — only when the tile is currently active
            // (interferes with the current time).
            if (isCurrent) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TimeScrubWidget(
                  timeline: subEvent,
                  loadTimeScrub: true,
                  isTardy: isTardy,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Playback controls (play/pause, defer, complete, delete).
            PlayBack(subEvent, preview: preview),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // The whole sheet is the edit affordance (same as the grid's tile
      // sheet): tapping anywhere on it pops the sheet and opens the edit
      // flow. Inner controls (location badge, playback buttons) keep their
      // own taps — the deepest gesture wins. Preview (TileCast) sheets stay
      // read-only.
      child: preview
          ? body
          : GestureDetector(
              key: sheetEditTargetKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => _openEditFlow(context),
              child: body,
            ),
    );
  }
}
