import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Enhanced tile card matching the Screen 2 design with:
/// - Time range display (8:00 AM - 9:30 AM)
/// - Tile name prominently displayed
/// - Location badge with icon
/// - Duration badge
/// - Shared tile avatars (if applicable)
/// - Weather icon (optional)
class EnhancedTileCard extends StatelessWidget {
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

  String _formatTimeRange(BuildContext context) {
    final startTime = subEvent.startTime;
    final endTime = subEvent.endTime;
    final startFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(startTime));
    final endFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(endTime));
    return '$startFormatted - $endFormatted';
  }

  String _formatDuration() {
    final duration = subEvent.duration;
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

  bool _isVideoMeeting() {
    final location = _getLocationText()?.toLowerCase() ?? '';
    return location.contains('zoom') ||
        location.contains('meet') ||
        location.contains('teams') ||
        location.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get tile colors
    final redColor = subEvent.colorRed ?? 127;
    final greenColor = subEvent.colorGreen ?? 127;
    final blueColor = subEvent.colorBlue ?? 127;
    final tileColor = Color.fromRGBO(redColor, greenColor, blueColor, 1);

    // Determine text color based on background brightness
    final hslColor = HSLColor.fromColor(tileColor);
    final isLightBackground = hslColor.lightness > 0.6;
    final textColor = isLightBackground ? Colors.black87 : Colors.white;
    final secondaryTextColor =
        isLightBackground ? Colors.black54 : Colors.white.withOpacity(0.8);

    final location = _getLocationText();
    final isTardy = subEvent.isTardy ?? false;
    final isVideoMeeting = _isVideoMeeting();
    final hasTravel = (subEvent.travelTimeBefore ?? 0) > 0;
    final isShared = subEvent.tileShareDesignatedId?.isNotEmpty == true;

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TileDetail(
                  tileId: subEvent.calendarEvent?.id ?? subEvent.id!,
                ),
              ),
            );
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
            child: Stack(
              children: [
                // Main content
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
                              if (showWeatherIcon && weatherIcon != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  weatherIcon,
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
                              subEvent.name ?? '',
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

                      // Bottom row: Location + Travel time
                      Row(
                        children: [
                          // Location badge
                          if (location != null)
                            Expanded(
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
                                      isVideoMeeting
                                          ? Icons.videocam_outlined
                                          : Icons.location_on_outlined,
                                      size: 14,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          fontFamily:
                                              TileTextStyles.rubikFontName,
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Travel time indicator
                          if (hasTravel) ...[
                            const SizedBox(width: 8),
                            CompactTravelIndicator(
                              travelTimeMs: subEvent.travelTimeBefore,
                              travelMode:
                                  subEvent.travelDetail?.before?.travelMedium,
                              isTardy: isTardy,
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
                if (subEvent.isRigid == true)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: textColor.withOpacity(0.6),
                    ),
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
                          Icons.location_on_outlined,
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
