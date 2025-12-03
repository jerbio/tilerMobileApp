import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper function to get location icon based on address type
/// Can be used by both stateful and stateless widgets
IconData _getLocationIconForAddress(String address) {
  final lowerAddress = address.toLowerCase();

  // Check if it's a video meeting link
  if (lowerAddress.contains('zoom') ||
      lowerAddress.contains('meet.google') ||
      lowerAddress.contains('teams.microsoft') ||
      lowerAddress.contains('webex') ||
      lowerAddress.contains('skype') ||
      lowerAddress.contains('hangout')) {
    return Icons.videocam_outlined;
  }

  // Check if it's a URL
  if (lowerAddress.startsWith('http://') ||
      lowerAddress.startsWith('https://') ||
      lowerAddress.startsWith('www.')) {
    return Icons.link_outlined;
  }

  // Default to location icon for physical addresses
  return Icons.location_on_outlined;
}

/// Enhanced tile card matching the Screen 2 design with:
/// - Time range display (8:00 AM - 9:30 AM)
/// - Tile name prominently displayed
/// - Location badge with icon
/// - Duration badge
/// - Shared tile avatars (if applicable)
/// - Weather icon (optional)
/// - Expandable sliver with playback controls (pause, resume, defer, complete)
class EnhancedTileCard extends StatefulWidget {
  final SubCalendarEvent subEvent;
  final bool showWeatherIcon;
  final IconData? weatherIcon;
  final VoidCallback? onTap;

  const EnhancedTileCard({
    Key? key,
    required this.subEvent,
    this.showWeatherIcon = false,
    this.weatherIcon,
    this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedTileCard> createState() => _EnhancedTileCardState();
}

class _EnhancedTileCardState extends State<EnhancedTileCard> {
  bool _isExpanded = false;

  String _formatTimeRange(BuildContext context) {
    final startTime = widget.subEvent.startTime;
    final endTime = widget.subEvent.endTime;
    final startFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(startTime));
    final endFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(endTime));
    return '$startFormatted - $endFormatted';
  }

  String _formatDuration() {
    final duration = widget.subEvent.duration;
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }

  String? _getLocationText() {
    if (widget.subEvent.addressDescription?.isNotEmpty == true) {
      return widget.subEvent.addressDescription;
    }
    if (widget.subEvent.address?.isNotEmpty == true) {
      return widget.subEvent.address;
    }
    if (widget.subEvent.searchdDescription?.isNotEmpty == true) {
      return widget.subEvent.searchdDescription;
    }
    return null;
  }

  /// Get the appropriate icon for the location type
  IconData _getLocationIcon(String location) {
    final lowerLocation = location.toLowerCase();

    // Check if it's a video meeting link
    if (lowerLocation.contains('zoom') ||
        lowerLocation.contains('meet.google') ||
        lowerLocation.contains('teams.microsoft') ||
        lowerLocation.contains('webex') ||
        lowerLocation.contains('skype') ||
        lowerLocation.contains('hangout')) {
      return Icons.videocam_outlined;
    }

    // Check if it's a URL
    if (_isStringUrl(location).item1) {
      return Icons.link_outlined;
    }

    // Default to location icon for physical addresses
    return Icons.location_on_outlined;
  }

  /// Check if a string is a URL
  Tuple2<bool, String> _isStringUrl(String url) {
    try {
      bool retValue = Uri.parse(url).isAbsolute;
      return Tuple2(retValue, url);
    } catch (err) {
      List<String> eachUrlComponent = url.split(" ");
      if (eachUrlComponent.isNotEmpty) {
        for (var element in eachUrlComponent) {
          Tuple2<bool, String> isStringUrlTuple = _isStringUrl(element);
          if (isStringUrlTuple.item1) {
            return isStringUrlTuple;
          }
        }
      }
    }
    return Tuple2(false, url);
  }

  /// Launch URL in browser
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Handle location tap - opens maps or URL
  Future<void> _onLocationTap() async {
    String? addressLookup = widget.subEvent.address;
    addressLookup ??= widget.subEvent.addressDescription;
    addressLookup ??= widget.subEvent.searchdDescription;

    if (addressLookup != null) {
      var isStringUrlResult = _isStringUrl(addressLookup);
      if (isStringUrlResult.item1) {
        // It's a URL - launch it
        final Uri url = Uri.parse(isStringUrlResult.item2);
        await _launchUrl(url);
        return;
      }
      // It's an address - launch maps
      MapsLauncher.launchQuery(addressLookup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get tile colors
    final redColor = widget.subEvent.colorRed ?? 127;
    final greenColor = widget.subEvent.colorGreen ?? 127;
    final blueColor = widget.subEvent.colorBlue ?? 127;
    final tileColor = Color.fromRGBO(redColor, greenColor, blueColor, 1);

    // Determine text color based on background brightness
    final hslColor = HSLColor.fromColor(tileColor);
    final isLightBackground = hslColor.lightness > 0.6;
    final textColor = isLightBackground ? Colors.black87 : Colors.white;
    final secondaryTextColor =
        isLightBackground ? Colors.black54 : Colors.white.withOpacity(0.8);

    final location = _getLocationText();
    final isTardy = widget.subEvent.isTardy ?? false;
    final hasTravel = (widget.subEvent.travelTimeBefore ?? 0) > 0;
    final isShared = widget.subEvent.tileShareDesignatedId?.isNotEmpty == true;
    final isCurrent = widget.subEvent.isCurrentTimeWithin;
    final isPaused = widget.subEvent.isPaused ?? false;

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            if (!(widget.subEvent.isReadOnly ?? true)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTile(
                    tileId: (widget.subEvent.isFromTiler
                            ? widget.subEvent.id
                            : widget.subEvent.thirdpartyId) ??
                        "",
                    tileSource: widget.subEvent.thirdpartyType,
                    thirdPartyUserId: widget.subEvent.thirdPartyUserId,
                  ),
                ),
              );
            }
          },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tileColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hslColor
                      .withLightness((hslColor.lightness + 0.05).clamp(0, 1))
                      .toColor(),
                  tileColor,
                  hslColor
                      .withLightness((hslColor.lightness - 0.05).clamp(0, 1))
                      .toColor(),
                ],
              ),
            ),
            child: Column(
              children: [
                // Main content
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Time range + Weather + Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Time range
                              Row(
                                children: [
                                  Text(
                                    _formatTimeRange(context),
                                    style: TextStyle(
                                      fontFamily: TileTextStyles.rubikFontName,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  if (widget.showWeatherIcon &&
                                      widget.weatherIcon != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      widget.weatherIcon,
                                      size: 16,
                                      color: secondaryTextColor,
                                    ),
                                  ],
                                ],
                              ),
                              // Duration badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDuration(),
                                  style: TextStyle(
                                    fontFamily: TileTextStyles.rubikFontName,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Tile name
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.subEvent.name ?? '',
                                  style: TextStyle(
                                    fontFamily: TileTextStyles.rubikFontName,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Shared tile avatars
                              if (isShared)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  child: Row(
                                    children: [
                                      _buildAvatar(colorScheme),
                                      Transform.translate(
                                        offset: const Offset(-8, 0),
                                        child: _buildAvatar(colorScheme),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Time scrub for current tile
                          if (isCurrent) ...[
                            TimeScrubWidget(
                              timeline: widget.subEvent,
                              loadTimeScrub: true,
                              isTardy: isTardy,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Bottom row: Location + Travel time
                          Row(
                            children: [
                              // Location badge - tappable to open maps/URL
                              if (location != null)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _onLocationTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getLocationIcon(location),
                                            size: 14,
                                            color: textColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              location,
                                              style: TextStyle(
                                                fontFamily: TileTextStyles
                                                    .rubikFontName,
                                                fontSize: 12,
                                                color: textColor,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    textColor.withOpacity(0.5),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.open_in_new,
                                            size: 12,
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Travel time indicator - tappable for Google Directions
                              if (hasTravel) ...[
                                const SizedBox(width: 8),
                                CompactTravelIndicator(
                                  travelTimeMs:
                                      widget.subEvent.travelTimeBefore,
                                  travelMode: widget.subEvent.travelDetail
                                      ?.before?.travelMedium,
                                  isTardy: isTardy,
                                  startLocation: widget.subEvent.travelDetail
                                      ?.before?.startLocation,
                                  endLocation: widget.subEvent.travelDetail
                                      ?.before?.endLocation,
                                  destinationAddress: widget.subEvent.address,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tardy indicator strip
                    if (isTardy)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: TileColors.late,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    // Rigid/locked indicator
                    if (widget.subEvent.isRigid == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),

                    // Paused indicator
                    if (isPaused)
                      Positioned(
                        top: 12,
                        right: widget.subEvent.isRigid == true ? 30 : 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pause,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                'Paused',
                                style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Expand/collapse button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isExpanded ? 'Hide actions' : 'Actions',
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 11,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expandable playback controls
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                    ),
                    child: PlayBack(widget.subEvent),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: 16,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

/// Lunch/break tile with special styling (yellow background with fork icon)
class LunchTileCard extends StatelessWidget {
  final SubCalendarEvent subEvent;
  final VoidCallback? onTap;

  const LunchTileCard({
    Key? key,
    required this.subEvent,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD), // Warm yellow
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 20,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subEvent.name ?? 'Lunch',
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown[800],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${subEvent.duration.inMinutes}m',
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Focus time tile with special green styling
class FocusTimeTileCard extends StatelessWidget {
  final SubCalendarEvent subEvent;
  final VoidCallback? onTap;

  const FocusTimeTileCard({
    Key? key,
    required this.subEvent,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // Light green
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.self_improvement,
                size: 20,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subEvent.name ?? 'Focus Time',
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[900],
                    ),
                  ),
                  if (subEvent.address?.isNotEmpty == true)
                    Row(
                      children: [
                        Icon(
                          _getLocationIconForAddress(subEvent.address!),
                          size: 12,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subEvent.address!,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
