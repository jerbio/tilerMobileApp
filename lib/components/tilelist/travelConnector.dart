import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Travel connector widget displayed between tiles showing travel time and route info
/// Matches the design: "🚗 15 min drive to Office" with vertical connectors
class TravelConnector extends StatelessWidget {
  final SubCalendarEvent fromTile;
  final SubCalendarEvent toTile;
  final bool showWarning;
  final String? warningMessage;
  final VoidCallback? onTap;

  const TravelConnector({
    Key? key,
    required this.fromTile,
    required this.toTile,
    this.showWarning = false,
    this.warningMessage,
    this.onTap,
  }) : super(key: key);

  IconData _getTravelModeIcon(String? travelMode) {
    switch (travelMode?.toLowerCase()) {
      case 'driving':
        return Icons.directions_car;
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      case 'transit':
        return Icons.directions_transit;
      default:
        return Icons.directions_car;
    }
  }

  String _formatDuration(BuildContext context, double? durationMs) {
    if (durationMs == null || durationMs <= 0) return '';
    final l10n = AppLocalizations.of(context)!;
    final minutes = (durationMs / 60000).round();
    if (minutes < 60) {
      return l10n.travelDurationMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return l10n.travelDurationHours(hours);
    }
    return l10n.travelDurationHoursMinutes(hours, remainingMinutes);
  }

  String _getDestinationName() {
    if (toTile.addressDescription?.isNotEmpty == true) {
      return toTile.addressDescription!;
    }
    if (toTile.address?.isNotEmpty == true) {
      return toTile.address!;
    }
    return toTile.name ?? '';
  }

  String? _getRouteName(BuildContext context) {
    final travelDetail = toTile.travelDetail;
    if (travelDetail?.before?.travelLegs?.isNotEmpty == true) {
      // Try to find a route description from travel legs
      final mainLeg = travelDetail!.before!.travelLegs!.firstWhere(
        (leg) => leg.description?.isNotEmpty == true,
        orElse: () => TravelLeg(),
      );
      if (mainLeg.description?.isNotEmpty == true) {
        return AppLocalizations.of(context)!
            .travelViaRoute(mainLeg.description!);
      }
    }
    return null;
  }

  DateTime? _getLeaveByTime() {
    final travelTime = toTile.travelTimeBefore;
    if (travelTime == null || travelTime <= 0) return null;
    final tileStart = toTile.start;
    if (tileStart == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (tileStart - travelTime).toInt(),
    );
  }

  /// Clean HTML tags from route description text
  String _cleanRouteText(String text) {
    // Remove HTML tags like <b>, </b>, etc.
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Get localized travel mode text for display
  String _getLocalizedTravelMode(BuildContext context, String? travelMode) {
    final l10n = AppLocalizations.of(context)!;
    switch (travelMode?.toLowerCase()) {
      case 'driving':
        return l10n.travelModeDriving;
      case 'walking':
        return l10n.travelModeWalking;
      case 'bicycling':
        return l10n.travelModeBicycling;
      case 'transit':
        return l10n.travelModeTransitLower;
      default:
        return l10n.travelModeDriving;
    }
  }

  /// Get the travel mode parameter for Google Maps directions URL
  String _getDirectionsTravelMode(String? travelMode) {
    switch (travelMode?.toLowerCase()) {
      case 'walking':
        return 'walking';
      case 'bicycling':
        return 'bicycling';
      case 'transit':
        return 'transit';
      case 'driving':
      default:
        return 'driving';
    }
  }

  /// Convert Location to lat,lng string for Google Maps URL
  String _longLatString(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  /// Launch Google Maps directions (similar to TileWidgetState._launchGoogleMaps)
  Future<void> _launchGoogleMaps(
    Location? originLocation,
    Location? destinationLocation,
    String travelMode,
  ) async {
    // Check if we have valid locations
    final hasValidOrigin = originLocation?.isNotNullAndNotDefault ?? false;
    final hasValidDestination =
        destinationLocation?.isNotNullAndNotDefault ?? false;

    if (!hasValidDestination) return;

    // Build destination - prioritize address over coordinates
    String destination;
    if (destinationLocation!.address?.isNotEmpty == true) {
      destination = Uri.encodeComponent(destinationLocation.address!);
    } else {
      destination = _longLatString(destinationLocation);
    }

    // Build origin if available - prioritize address over coordinates
    String? origin;
    if (hasValidOrigin) {
      if (originLocation!.address?.isNotEmpty == true) {
        origin = Uri.encodeComponent(originLocation.address!);
      } else {
        origin = _longLatString(originLocation);
      }
    }

    // Build Google Maps directions URL
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=$travelMode';
    if (origin != null) {
      url += '&origin=$origin';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch Google Maps directions to the destination
  Future<void> _launchDirections() async {
    final travelDetail = toTile.travelDetail?.before;
    final travelMode = _getDirectionsTravelMode(travelDetail?.travelMedium);

    // Get origin and destination locations from travel detail
    final originLocation = travelDetail?.startLocation ?? fromTile.location;
    final destinationLocation = travelDetail?.endLocation ?? toTile.location;

    await _launchGoogleMaps(originLocation, destinationLocation, travelMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final travelTime = toTile.travelTimeBefore;
    if (travelTime == null || travelTime <= 0) {
      return const SizedBox.shrink();
    }

    final travelMode = toTile.travelDetail?.before?.travelMedium ?? 'driving';
    final isTardy = toTile.isTardy ?? false;
    final durationText = _formatDuration(context, travelTime);
    final destination = _getDestinationName();
    final routeName = _getRouteName(context);
    final leaveByTime = _getLeaveByTime();
    final localizedTravelMode = _getLocalizedTravelMode(context, travelMode);

    final primaryColor = isTardy ? TileColors.late : TileColors.travel;

    return GestureDetector(
      onTap: onTap ?? _launchDirections,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Left connector line and icon
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.outline.withOpacity(0.3),
                          primaryColor.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getTravelModeIcon(travelMode),
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(0.5),
                          colorScheme.outline.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Travel info content
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main travel info row
                    Row(
                      children: [
                        Text(
                          durationText,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          l10n.travelModeToDestination(localizedTravelMode),
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            destination,
                            style: TextStyle(
                              fontFamily: TileTextStyles.rubikFontName,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Navigation icon to indicate directions are available
                        const SizedBox(width: 8),
                        Icon(
                          Icons.navigation_outlined,
                          size: 16,
                          color: primaryColor,
                        ),
                      ],
                    ),

                    // Route name and leave by time
                    if (routeName != null || leaveByTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (routeName != null) ...[
                              Icon(
                                Icons.route,
                                size: 12,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _cleanRouteText(routeName),
                                  style: TextStyle(
                                    fontFamily: TileTextStyles.rubikFontName,
                                    fontSize: 12,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (routeName != null && leaveByTime != null)
                              const SizedBox(width: 12),
                            if (leaveByTime != null) ...[
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: isTardy
                                    ? TileColors.late
                                    : colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.leaveByTime(MaterialLocalizations.of(
                                        context)
                                    .formatTimeOfDay(
                                        TimeOfDay.fromDateTime(leaveByTime))),
                                style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 12,
                                  fontWeight: isTardy
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isTardy
                                      ? TileColors.late
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Warning message (e.g., traffic alert)
                    if (showWarning && warningMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: TileColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: TileColors.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: TileColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                warningMessage!,
                                style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

/// Simple travel indicator for compact view (just shows icon and duration)
/// Tappable to open Google Directions
class CompactTravelIndicator extends StatelessWidget {
  final double? travelTimeMs;
  final String? travelMode;
  final bool isTardy;
  final Location? startLocation;
  final Location? endLocation;
  final String? destinationAddress;

  const CompactTravelIndicator({
    Key? key,
    this.travelTimeMs,
    this.travelMode,
    this.isTardy = false,
    this.startLocation,
    this.endLocation,
    this.destinationAddress,
  }) : super(key: key);

  IconData _getTravelModeIcon() {
    switch (travelMode?.toLowerCase()) {
      case 'driving':
        return Icons.directions_car;
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      case 'transit':
        return Icons.directions_transit;
      default:
        return Icons.directions_car;
    }
  }

  String _formatDuration(BuildContext context) {
    if (travelTimeMs == null || travelTimeMs! <= 0) return '';
    final minutes = (travelTimeMs! / 60000).round();
    return AppLocalizations.of(context)!.travelDurationCompact(minutes);
  }

  /// Get the travel mode parameter for Google Maps directions URL
  String _getDirectionsTravelMode() {
    switch (travelMode?.toLowerCase()) {
      case 'walking':
        return 'walking';
      case 'bicycling':
        return 'bicycling';
      case 'transit':
        return 'transit';
      case 'driving':
      default:
        return 'driving';
    }
  }

  /// Convert Location to lat,lng string for Google Maps URL
  String _longLatString(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  /// Launch Google Maps directions (similar to TileWidgetState._launchGoogleMaps)
  Future<void> _launchGoogleMaps(
    Location? originLocation,
    Location? destinationLocation,
    String travelMode,
  ) async {
    // Check if we have valid locations
    final hasValidOrigin = originLocation?.isNotNullAndNotDefault ?? false;
    final hasValidDestination =
        destinationLocation?.isNotNullAndNotDefault ?? false;

    if (!hasValidDestination) return;

    // Build destination - prioritize address over coordinates
    String destination;
    if (destinationLocation!.address?.isNotEmpty == true) {
      destination = Uri.encodeComponent(destinationLocation.address!);
    } else {
      destination = _longLatString(destinationLocation);
    }

    // Build origin if available - prioritize address over coordinates
    String? origin;
    if (hasValidOrigin) {
      if (originLocation!.address?.isNotEmpty == true) {
        origin = Uri.encodeComponent(originLocation.address!);
      } else {
        origin = _longLatString(originLocation);
      }
    }

    // Build Google Maps directions URL
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=$travelMode';
    if (origin != null) {
      url += '&origin=$origin';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch Google Maps directions
  Future<void> _launchDirections() async {
    final mode = _getDirectionsTravelMode();
    await _launchGoogleMaps(startLocation, endLocation, mode);
  }

  @override
  Widget build(BuildContext context) {
    if (travelTimeMs == null || travelTimeMs! <= 0) {
      return const SizedBox.shrink();
    }

    final color = isTardy ? TileColors.late : TileColors.travel;
    final hasValidDestination = endLocation?.isNotNullAndNotDefault ?? false;

    return GestureDetector(
      onTap: hasValidDestination ? _launchDirections : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTravelModeIcon(),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(context),
              style: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            // Show directions arrow if tappable
            if (hasValidDestination) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.navigation_outlined,
                size: 12,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
