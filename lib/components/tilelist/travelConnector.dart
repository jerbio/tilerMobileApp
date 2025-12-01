import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

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

  String _formatDuration(double? durationMs) {
    if (durationMs == null || durationMs <= 0) return '';
    final minutes = (durationMs / 60000).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
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

  String? _getRouteName() {
    final travelDetail = toTile.travelDetail;
    if (travelDetail?.before?.travelLegs?.isNotEmpty == true) {
      // Try to find a route description from travel legs
      final mainLeg = travelDetail!.before!.travelLegs!.firstWhere(
        (leg) => leg.description?.isNotEmpty == true,
        orElse: () => TravelLeg(),
      );
      if (mainLeg.description?.isNotEmpty == true) {
        return 'via ${mainLeg.description}';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final travelTime = toTile.travelTimeBefore;
    if (travelTime == null || travelTime <= 0) {
      return const SizedBox.shrink();
    }

    final travelMode = toTile.travelDetail?.before?.travelMedium ?? 'driving';
    final isTardy = toTile.isTardy ?? false;
    final durationText = _formatDuration(travelTime);
    final destination = _getDestinationName();
    final routeName = _getRouteName();
    final leaveByTime = _getLeaveByTime();

    final primaryColor = isTardy ? TileColors.late : TileColors.travel;

    return GestureDetector(
      onTap: onTap,
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
                          ' ${travelMode.toLowerCase()} to ',
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
                              Text(
                                routeName,
                                style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.6),
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
                                'Leave by ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(leaveByTime))}',
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
class CompactTravelIndicator extends StatelessWidget {
  final double? travelTimeMs;
  final String? travelMode;
  final bool isTardy;

  const CompactTravelIndicator({
    Key? key,
    this.travelTimeMs,
    this.travelMode,
    this.isTardy = false,
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

  String _formatDuration() {
    if (travelTimeMs == null || travelTimeMs! <= 0) return '';
    final minutes = (travelTimeMs! / 60000).round();
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (travelTimeMs == null || travelTimeMs! <= 0) {
      return const SizedBox.shrink();
    }

    final color = isTardy ? TileColors.late : TileColors.travel;

    return Container(
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
            _formatDuration(),
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
