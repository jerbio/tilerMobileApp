import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/executionEnums.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rendered after the last tile in the day list.
///
/// Two visual sections stacked vertically:
///   1. **Travel section** (optional) — only when return-travel data is present.
///      Tappable: launches Google Maps for non-home destinations.
///      Consistent visual language with [TravelConnector] (gradient line + circle icon).
///   2. **End-of-day marker** (always shown) — sunset gradient icon + "End of Day"
///      label with optional time. Signals day conclusion rather than just a label.
class ReturnConnector extends StatelessWidget {
  final SubCalendarEvent lastTile;

  /// The user's configured end-of-day time.  When provided, the time is shown
  /// below the "End of Day" label in the sunset marker.
  final DateTime? endOfDayTime;

  /// Called after returning from the TilePreferencesScreen so the parent can
  /// re-fetch the latest end-of-day setting.
  final VoidCallback? onEndOfDayUpdated;

  // Sunset palette — warm amber → deep purple
  static const Color _sunsetAmber = Color(0xFFFF8F00);
  static const Color _sunsetPurple = Color(0xFF6A1B9A);

  const ReturnConnector({
    Key? key,
    required this.lastTile,
    this.endOfDayTime,
    this.onEndOfDayUpdated,
  }) : super(key: key);

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  TravelData? get _afterData => lastTile.travelDetail?.after;

  double? get _durationMs {
    final fromDetail = _afterData?.duration;
    if (fromDetail != null) return fromDetail;
    return lastTile.travelTimeAfter;
  }

  bool get _isHome {
    final desc = _afterData?.endLocation?.description;
    return desc?.toLowerCase() == Location.homeLocationNickName;
  }

  bool get _hasLocation => _afterData?.endLocation != null;

  bool get _hasTravelData =>
      lastTile.travelDetail?.after != null || lastTile.travelTimeAfter != null;

  bool get _canOpenMaps =>
      _hasLocation &&
      !_isHome &&
      (_afterData!.endLocation!.isNotNullAndNotDefault);

  TravelMedium get _travelMode =>
      TravelMediumExtension.fromString(_afterData?.travelMedium);

  String _formatDuration(double ms) {
    final minutes = (ms / 60000).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
  }

  String _formatTime(DateTime dt) => DateFormat.jm().format(dt);

  Future<void> _launchMaps() async {
    if (!_canOpenMaps) return;
    final dest = _afterData!.endLocation!;
    final origin = _afterData?.startLocation ?? lastTile.location;

    String destination;
    if (dest.address?.isNotEmpty == true) {
      destination = Uri.encodeComponent(dest.address!);
    } else {
      destination = '${dest.latitude},${dest.longitude}';
    }

    String? originParam;
    if (origin?.isNotNullAndNotDefault == true) {
      if (origin!.address?.isNotEmpty == true) {
        originParam = Uri.encodeComponent(origin.address!);
      } else {
        originParam = '${origin.latitude},${origin.longitude}';
      }
    }

    final travelMode = _travelMode.googleMapsMode;
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=$travelMode';
    if (originParam != null) {
      url += '&origin=$originParam';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasTravelData) _buildTravelSection(context),
        _buildEndOfDaySection(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Travel section
  // ---------------------------------------------------------------------------

  Widget _buildTravelSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationMs = _durationMs;
    final hasDuration = durationMs != null && durationMs > 0;

    final IconData travelIcon = _isHome ? Icons.home : _travelMode.icon;

    String destinationLabel = '';
    if (_isHome) {
      destinationLabel = AppLocalizations.of(context)!.home;
    } else if (_hasLocation) {
      final loc = _afterData!.endLocation!;
      destinationLabel = loc.description?.isNotEmpty == true
          ? loc.description!
          : (loc.address ?? '');
    }

    return GestureDetector(
      onTap: _canOpenMaps ? _launchMaps : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left connector column — consistent with TravelConnector width
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.outline.withOpacity(0.3),
                          TileColors.travel.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: TileColors.travel.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TileColors.travel.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(travelIcon, size: 16, color: TileColors.travel),
                  ),
                  Container(
                    width: 2,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          TileColors.travel.withOpacity(0.6),
                          _sunsetAmber.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Travel info card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TileColors.travel.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TileColors.travel.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (hasDuration) ...[
                      Text(
                        _formatDuration(durationMs),
                        style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TileColors.travel,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (destinationLabel.isNotEmpty)
                      Expanded(
                        child: Text(
                          destinationLabel,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (_canOpenMaps) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.navigation_outlined,
                        size: 16,
                        color: TileColors.travel,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // End-of-day section — always rendered
  // ---------------------------------------------------------------------------

  Widget _buildEndOfDaySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: connecting line from travel section → sunset icon (terminal)
          SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _hasTravelData
                            ? _sunsetAmber.withOpacity(0.4)
                            : colorScheme.outline.withOpacity(0.3),
                        _sunsetAmber.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Sunset gradient icon pill
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_sunsetAmber, _sunsetPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wb_twilight,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                // Fade-out trailing line — the day tapers off
                Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _sunsetPurple.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // "End of Day" label + optional time
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, TilePreferencesScreen.routeName)
                      .then((_) => onEndOfDayUpdated?.call()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_sunsetAmber, _sunsetPurple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: Text(
                          AppLocalizations.of(context)!.endOfDay,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            // ShaderMask paints over this; white makes the gradient visible
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (endOfDayTime != null)
                        Text(
                          _formatTime(endOfDayTime!),
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _sunsetPurple.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
