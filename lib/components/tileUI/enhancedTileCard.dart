import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper function to get location icon based on address type
/// Can be used by both stateful and stateless widgets
IconData _getLocationIconForAddress(String address) {
  switch (Utility.getLocationType(address)) {
    case LocationType.videoConference:
      return Icons.videocam_outlined;
    case LocationType.onlineUrl:
      return Icons.link_outlined;
    case LocationType.physical:
    case LocationType.none:
      return Icons.location_on_outlined;
  }
}

/// RSVP status styling configuration
class RsvpStyleConfig {
  final double opacity;
  final bool useDashedBorder;
  final bool useOutlineStyle;
  final IconData? badgeIcon;
  final String? badgeText;
  final Color? badgeColor;
  final bool showStrikethrough;

  const RsvpStyleConfig({
    this.opacity = 1.0,
    this.useDashedBorder = false,
    this.useOutlineStyle = false,
    this.badgeIcon,
    this.badgeText,
    this.badgeColor,
    this.showStrikethrough = false,
  });

  /// Get style config based on RSVP status and tile source
  static RsvpStyleConfig forEvent(SubCalendarEvent event) {
    // Tiler-native tiles don't have RSVP
    if (event.isFromTiler) {
      return const RsvpStyleConfig();
    }

    switch (event.rsvp) {
      case RsvpStatus.accepted:
        return RsvpStyleConfig(
          badgeIcon: Icons.check_circle_outline,
          badgeColor: Colors.green.shade600,
        );
      case RsvpStatus.tentative:
        return RsvpStyleConfig(
          opacity: 0.7,
          useDashedBorder: true,
          badgeIcon: Icons.help_outline,
          badgeText: 'Tentative',
          badgeColor: Colors.amber.shade700,
        );
      case RsvpStatus.needsAction:
        return RsvpStyleConfig(
          opacity: 0.85,
          useOutlineStyle: true,
          badgeIcon: Icons.notifications_active_outlined,
          badgeText: 'Respond',
          badgeColor: Colors.orange.shade600,
        );
      case RsvpStatus.declined:
        return RsvpStyleConfig(
          opacity: 0.35,
          showStrikethrough: true,
          badgeIcon: Icons.cancel_outlined,
          badgeColor: Colors.grey,
        );
      case RsvpStatus.notApplicable:
      case null:
        // Third-party tile without RSVP info - show source badge
        return const RsvpStyleConfig();
    }
  }
}

/// Get icon for third-party calendar source
IconData? _getSourceIcon(TileSource? source) {
  switch (source) {
    case TileSource.google:
      return Icons.g_mobiledata; // Google icon
    case TileSource.outlook:
      return Icons.mail_outline; // Outlook icon
    case TileSource.tiler:
    case null:
      return null;
  }
}

/// Get color for third-party calendar source
Color _getSourceColor(TileSource? source) {
  switch (source) {
    case TileSource.google:
      return const Color(0xFF4285F4); // Google Blue
    case TileSource.outlook:
      return const Color(0xFF0078D4); // Microsoft Blue
    case TileSource.tiler:
    case null:
      return Colors.grey;
  }
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

  /// Check if the tile has any playback actions to show
  /// Based on the logic in PlayBack widget
  bool _hasPlaybackActions() {
    final subEvent = widget.subEvent;

    // Complete button is shown if isFromTiler is true
    if (subEvent.isFromTiler) {
      return true;
    }

    // Procrastinate button is shown if not rigid
    if (subEvent.isRigid == null || !subEvent.isRigid!) {
      return true;
    }

    // Play/pause button is shown if not rigid and (is current or is paused)
    if ((subEvent.isRigid == null || !subEvent.isRigid!) &&
        (subEvent.isCurrent || (subEvent.isPaused ?? false))) {
      return true;
    }

    return false;
  }

  String _formatTimeRange(BuildContext context) {
    final startTime = widget.subEvent.startTime;
    final endTime = widget.subEvent.endTime;
    final startFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(startTime));
    final endFormatted = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(endTime));
    return '$startFormatted - $endFormatted';
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
    return _getLocationIconForAddress(location);
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
      String? link = Utility.getLinkFromLocation(addressLookup);
      if (link != null) {
        // It's a URL - launch it
        final Uri url = Uri.parse(link);
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

    // RSVP styling for third-party calendar events
    final rsvpStyle = RsvpStyleConfig.forEvent(widget.subEvent);
    final isThirdParty = !widget.subEvent.isFromTiler;
    final effectiveOpacity = rsvpStyle.opacity;

    // For outline style (needsAction), use tile color for text since background is surface
    final Color textColor;
    final Color secondaryTextColor;
    if (rsvpStyle.useOutlineStyle) {
      // Outline style has surface background, so use tile color or dark text
      final surfaceIsLight = colorScheme.brightness == Brightness.light;
      textColor = surfaceIsLight ? tileColor : tileColor;
      secondaryTextColor = surfaceIsLight
          ? tileColor.withOpacity(0.7)
          : tileColor.withOpacity(0.8);
    } else {
      textColor = isLightBackground ? Colors.black87 : Colors.white;
      secondaryTextColor =
          isLightBackground ? Colors.black54 : Colors.white.withOpacity(0.8);
    }

    final location = _getLocationText();
    final isTardy = widget.subEvent.isTardy ?? false;
    final hasTravel = (widget.subEvent.travelTimeBefore ?? 0) > 0;
    final isShared = widget.subEvent.tileShareDesignatedId?.isNotEmpty == true;
    final isCurrent = widget.subEvent.isCurrentTimeWithin;
    final isPaused = widget.subEvent.isPaused ?? false;

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            // Always allow navigation to EditTile - it handles read-only tiles properly
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
          },
      child: Opacity(
        opacity: effectiveOpacity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: rsvpStyle.useDashedBorder || rsvpStyle.useOutlineStyle
                ? Border.all(
                    color: tileColor,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : null,
            boxShadow: rsvpStyle.useOutlineStyle
                ? [] // No shadow for outline style
                : [
                    BoxShadow(
                      color: tileColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: rsvpStyle.useDashedBorder
                  ? DashedBorderPainter(
                      color: tileColor,
                      strokeWidth: 2,
                      dashWidth: 8,
                      dashSpace: 4,
                      borderRadius: 16,
                    )
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  gradient: rsvpStyle.useOutlineStyle
                      ? null // No gradient for outline style
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            hslColor
                                .withLightness(
                                    (hslColor.lightness + 0.05).clamp(0, 1))
                                .toColor(),
                            tileColor,
                            hslColor
                                .withLightness(
                                    (hslColor.lightness - 0.05).clamp(0, 1))
                                .toColor(),
                          ],
                        ),
                  color: rsvpStyle.useOutlineStyle
                      ? colorScheme.surface // White/surface for outline style
                      : null,
                ),
                child: Column(
                  children: [
                    // Main content
                    Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            // Add extra top padding if RSVP badge is shown
                            (isThirdParty &&
                                    rsvpStyle.badgeText != null &&
                                    !isPaused)
                                ? 28
                                : 16,
                            // Add extra right padding if source indicator is shown
                            isThirdParty ? 32 : 16,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Time range + Weather + Duration
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Time range
                                  Row(
                                    children: [
                                      Text(
                                        _formatTimeRange(context),
                                        style: TextStyle(
                                          fontFamily:
                                              TileTextStyles.rubikFontName,
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
                                  // Duration badge with optional lock icon
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rsvpStyle.useOutlineStyle
                                              ? tileColor.withOpacity(0.15)
                                              : Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.subEvent.duration
                                              .toHumanLocalized(context),
                                          style: TextStyle(
                                            fontFamily:
                                                TileTextStyles.rubikFontName,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      // Rigid/locked indicator next to duration
                                      if (widget.subEvent.isRigid == true) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.lock_outline,
                                          size: 14,
                                          color: textColor.withOpacity(0.6),
                                        ),
                                      ],
                                    ],
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
                                        fontFamily:
                                            TileTextStyles.rubikFontName,
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TileShareDetailWidget
                                                    .byDesignatedTileShareId(
                                              designatedTileShareId: widget
                                                  .subEvent
                                                  .tileShareDesignatedId!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
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
                                            color: rsvpStyle.useOutlineStyle
                                                ? tileColor.withOpacity(0.1)
                                                : Colors.white
                                                    .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor: textColor
                                                        .withOpacity(0.5),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.open_in_new,
                                                size: 12,
                                                color:
                                                    textColor.withOpacity(0.7),
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
                                      startLocation: widget.subEvent
                                          .travelDetail?.before?.startLocation,
                                      endLocation: widget.subEvent.travelDetail
                                          ?.before?.endLocation,
                                      destinationAddress:
                                          widget.subEvent.address,
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

                        // Paused indicator
                        if (isPaused)
                          Positioned(
                            top: 12,
                            right: 12,
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

                        // RSVP status badge (for third-party events) - positioned in top-left
                        if (isThirdParty &&
                            rsvpStyle.badgeText != null &&
                            !isPaused)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    rsvpStyle.badgeColor?.withOpacity(0.95) ??
                                        Colors.orange.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (rsvpStyle.badgeIcon != null) ...[
                                    Icon(
                                      rsvpStyle.badgeIcon,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    rsvpStyle.badgeText!,
                                    style: TextStyle(
                                      fontFamily: TileTextStyles.rubikFontName,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Third-party source indicator (top-right, small circle)
                        if (isThirdParty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getSourceColor(
                                    widget.subEvent.thirdpartyType),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _getSourceIcon(
                                          widget.subEvent.thirdpartyType) ??
                                      Icons.calendar_today,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Expand/collapse button (only show if there are actions)
                    if (_hasPlaybackActions())
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
                                _isExpanded
                                    ? AppLocalizations.of(context)!.hideActions
                                    : AppLocalizations.of(context)!.actions,
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

                    // Expandable playback controls (only show if there are actions)
                    if (_hasPlaybackActions())
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

/// Custom painter for dashed border effect (used for tentative RSVP status)
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashSpace = 4,
    this.borderRadius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    // Draw dashed border
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
