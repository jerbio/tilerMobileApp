import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

/// Summary banner showing tiles with pending RSVP (needs action or tentative) and declined tiles
/// Auto-updates to surface the most relevant upcoming tiles
class PendingRsvpBanner extends StatefulWidget {
  final List<SubCalendarEvent> pendingTiles;
  final List<SubCalendarEvent> declinedTiles;
  final VoidCallback? onRsvpUpdated;

  const PendingRsvpBanner({
    Key? key,
    required this.pendingTiles,
    this.declinedTiles = const [],
    this.onRsvpUpdated,
  }) : super(key: key);

  /// Detect tiles with pending RSVP status (needsAction or tentative)
  /// Only includes tiles from third-party calendars (non-Tiler tiles)
  static List<SubCalendarEvent> detectPendingRsvpTiles(List<TilerEvent> tiles) {
    final now = Utility.currentTime().millisecondsSinceEpoch;

    return tiles.whereType<SubCalendarEvent>().where((tile) {
      // Only third-party tiles have RSVP
      if (tile.isFromTiler) return false;

      // Must have pending RSVP status
      final isPending = tile.rsvp == RsvpStatus.needsAction ||
          tile.rsvp == RsvpStatus.tentative;

      if (!isPending) return false;

      // Only include tiles that haven't ended yet
      if (tile.end != null && tile.end! < now) return false;

      return true;
    }).toList()
      // Sort by start time (upcoming first)
      ..sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
  }

  /// Get the most urgent pending tile (soonest upcoming)
  static SubCalendarEvent? getMostUrgentTile(
      List<SubCalendarEvent> pendingTiles) {
    if (pendingTiles.isEmpty) return null;

    final now = Utility.currentTime().millisecondsSinceEpoch;

    // First try to find a tile that's about to start (within next 2 hours)
    final urgentTiles = pendingTiles.where((tile) {
      if (tile.start == null) return false;
      final timeTilStart = tile.start! - now;
      return timeTilStart > 0 && timeTilStart <= 2 * 60 * 60 * 1000; // 2 hours
    }).toList();

    if (urgentTiles.isNotEmpty) {
      return urgentTiles.first;
    }

    // Otherwise return the soonest upcoming tile
    final upcomingTiles =
        pendingTiles.where((tile) => (tile.start ?? 0) > now).toList();
    if (upcomingTiles.isNotEmpty) {
      return upcomingTiles.first;
    }

    // Fallback to first pending tile (even if current)
    return pendingTiles.first;
  }

  @override
  State<PendingRsvpBanner> createState() => _PendingRsvpBannerState();
}

class _PendingRsvpBannerState extends State<PendingRsvpBanner> {
  Timer? _updateTimer;
  SubCalendarEvent? _mostUrgentTile;

  @override
  void initState() {
    super.initState();
    _updateMostUrgentTile();
    // Update every minute to surface most relevant tile
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateMostUrgentTile();
    });
  }

  @override
  void didUpdateWidget(PendingRsvpBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingTiles != widget.pendingTiles ||
        oldWidget.declinedTiles != widget.declinedTiles) {
      _updateMostUrgentTile();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateMostUrgentTile() {
    if (mounted) {
      setState(() {
        _mostUrgentTile =
            PendingRsvpBanner.getMostUrgentTile(widget.pendingTiles);
      });
    }
  }

  String _getBannerTitle(AppLocalizations l10n, int totalCount) {
    final pendingCount = widget.pendingTiles.length;
    final declinedCount = widget.declinedTiles.length;

    if (pendingCount > 0 && declinedCount > 0) {
      // Both pending and declined
      if (pendingCount == 1 && declinedCount == 1) {
        return l10n.rsvpMixedOneDeclined(1);
      } else if (pendingCount == 1) {
        return l10n.rsvpMixedOnePending(declinedCount);
      } else if (declinedCount == 1) {
        return l10n.rsvpMixedOneDeclined(pendingCount);
      } else {
        return l10n.rsvpMixed(pendingCount, declinedCount);
      }
    } else if (pendingCount > 0) {
      // Only pending
      return totalCount == 1
          ? l10n.pendingRsvpSingular
          : l10n.pendingRsvpPlural(totalCount);
    } else {
      // Only declined
      return totalCount == 1
          ? l10n.declinedRsvpSingular
          : l10n.declinedRsvpPlural(declinedCount);
    }
  }

  void _showPendingRsvpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PendingRsvpModal(
        pendingTiles: widget.pendingTiles,
        declinedTiles: widget.declinedTiles,
        onRsvpUpdated: widget.onRsvpUpdated,
      ),
    );
  }

  String _getUrgencyText(BuildContext context) {
    if (_mostUrgentTile == null) return '';

    final l10n = AppLocalizations.of(context)!;
    final now = Utility.currentTime().millisecondsSinceEpoch;
    final tileStart = _mostUrgentTile!.start ?? now;
    final timeTilStart = tileStart - now;

    if (timeTilStart <= 0) {
      // Currently happening
      return l10n.pendingRsvpHappeningNow;
    } else if (timeTilStart <= 30 * 60 * 1000) {
      // Within 30 minutes
      return l10n.pendingRsvpStartingSoon;
    } else if (timeTilStart <= 60 * 60 * 1000) {
      // Within 1 hour
      return l10n.pendingRsvpWithinHour;
    } else if (timeTilStart <= 2 * 60 * 60 * 1000) {
      // Within 2 hours
      return l10n.pendingRsvpUpcoming;
    }

    return l10n.pendingRsvpTapToReview;
  }

  Color _getUrgencyColor() {
    if (_mostUrgentTile == null) return Colors.orange.shade400;

    final now = Utility.currentTime().millisecondsSinceEpoch;
    final tileStart = _mostUrgentTile!.start ?? now;
    final timeTilStart = tileStart - now;

    if (timeTilStart <= 0) {
      // Currently happening - red/urgent
      return Colors.red.shade500;
    } else if (timeTilStart <= 30 * 60 * 1000) {
      // Within 30 minutes - orange/warning
      return Colors.orange.shade600;
    } else if (timeTilStart <= 60 * 60 * 1000) {
      // Within 1 hour - amber
      return Colors.amber.shade600;
    }

    return Colors.orange.shade400;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingTiles.isEmpty && widget.declinedTiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    final urgencyColor = _getUrgencyColor();
    final hasNeedsAction =
        widget.pendingTiles.any((t) => t.rsvp == RsvpStatus.needsAction);
    final totalCount = widget.pendingTiles.length + widget.declinedTiles.length;

    return GestureDetector(
      onTap: () => _showPendingRsvpModal(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              urgencyColor,
              urgencyColor.withRed((urgencyColor.red * 0.8).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: urgencyColor.withAlpha(77),
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
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasNeedsAction
                    ? Icons.pending_actions_rounded
                    : Icons.help_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getBannerTitle(l10n, totalCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  if (_mostUrgentTile != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getUrgencyText(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal showing list of pending RSVP tiles with actions
class PendingRsvpModal extends StatelessWidget {
  final List<SubCalendarEvent> pendingTiles;
  final List<SubCalendarEvent> declinedTiles;
  final VoidCallback? onRsvpUpdated;

  const PendingRsvpModal({
    Key? key,
    required this.pendingTiles,
    this.declinedTiles = const [],
    this.onRsvpUpdated,
  }) : super(key: key);

  void _navigateToEditTile(BuildContext context, SubCalendarEvent tile) {
    Navigator.pop(context); // Close modal first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTile(
          tileId: (tile.isFromTiler ? tile.id : tile.thirdpartyId) ?? "",
          tileSource: tile.thirdpartyType,
          thirdPartyUserId: tile.thirdPartyUserId,
        ),
      ),
    ).then((_) {
      onRsvpUpdated?.call();
    });
  }

  /// Get icon for third-party calendar source
  IconData _getSourceIcon(TileSource? source) {
    switch (source) {
      case TileSource.google:
        return Icons.g_mobiledata;
      case TileSource.outlook:
        return Icons.mail_outline;
      case TileSource.tiler:
      case null:
        return Icons.event;
    }
  }

  /// Get the appropriate icon for the location type
  IconData _getLocationIcon(String? address) {
    if (address == null || address.isEmpty) return Icons.location_off_outlined;
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

  /// Launch URL in browser or maps
  Future<void> _openLocation(BuildContext context, String? address) async {
    if (address == null || address.isEmpty) return;

    final link = Utility.getLinkFromLocation(address);
    if (link != null) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.unableToOpenLinkError(link),
              ),
            ),
          );
        }
      }
    } else {
      // Physical address - open in maps
      MapsLauncher.launchQuery(address);
    }
  }

  String _getRsvpStatusText(BuildContext context, RsvpStatus? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case RsvpStatus.needsAction:
        return l10n.rsvpNeedsAction;
      case RsvpStatus.tentative:
        return l10n.rsvpTentative;
      case RsvpStatus.accepted:
        return l10n.rsvpAccepted;
      case RsvpStatus.declined:
        return l10n.rsvpDeclined;
      default:
        return '';
    }
  }

  Color _getRsvpStatusColor(RsvpStatus? status, ColorScheme colorScheme) {
    switch (status) {
      case RsvpStatus.needsAction:
        return Colors.orange;
      case RsvpStatus.tentative:
        return Colors.amber.shade700;
      case RsvpStatus.accepted:
        return Colors.green;
      case RsvpStatus.declined:
        return Colors.red;
      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final now = Utility.currentTime().millisecondsSinceEpoch;

    // Separate tiles into urgent (within 2 hours) and upcoming
    final urgentTiles = pendingTiles.where((tile) {
      final timeTilStart = (tile.start ?? 0) - now;
      return timeTilStart <= 2 * 60 * 60 * 1000; // 2 hours
    }).toList();

    final upcomingTiles = pendingTiles.where((tile) {
      final timeTilStart = (tile.start ?? 0) - now;
      return timeTilStart > 2 * 60 * 60 * 1000;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pendingRsvpTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.pendingRsvpSubtitle(
                            pendingTiles.length + declinedTiles.length),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of pending tiles
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Urgent section
                if (urgentTiles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.priority_high_rounded,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pendingRsvpUrgent,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...urgentTiles
                      .map((tile) => _buildTileItem(context, tile, true)),
                  if (upcomingTiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        l10n.pendingRsvpLater,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ),
                ],
                // Upcoming section
                ...upcomingTiles
                    .map((tile) => _buildTileItem(context, tile, false)),

                // Declined section
                if (declinedTiles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.declinedRsvp,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${declinedTiles.length})',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...declinedTiles
                      .map((tile) => _buildTileItem(context, tile, false)),
                ],
              ],
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildTileItem(
      BuildContext context, SubCalendarEvent tile, bool isUrgent) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDeclined = tile.rsvp == RsvpStatus.declined;

    final startTime = tile.startTime;
    final endTime = tile.endTime;
    final hasLocation = tile.address?.isNotEmpty == true ||
        tile.addressDescription?.isNotEmpty == true;
    final locationAddress = tile.address ?? tile.addressDescription;
    final isVideoConference = Utility.getLocationType(locationAddress) ==
        LocationType.videoConference;

    return Opacity(
      opacity: isDeclined ? 0.5 : 1.0,
      child: InkWell(
        onTap: () => _navigateToEditTile(context, tile),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: isUrgent
              ? BoxDecoration(
                  color: Colors.red.withAlpha(15),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Color indicator and source icon
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tile.color ?? colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tile info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with source icon
                        Row(
                          children: [
                            Icon(
                              _getSourceIcon(tile.thirdpartyType),
                              size: 16,
                              color: colorScheme.onSurface.withAlpha(153),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tile.name ?? l10n.untitledEvent,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Time and duration
                        Text(
                          '${DateFormat('EEE, MMM d • h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RSVP status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRsvpStatusColor(tile.rsvp, colorScheme)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRsvpStatusColor(tile.rsvp, colorScheme)
                            .withAlpha(100),
                      ),
                    ),
                    child: Text(
                      _getRsvpStatusText(context, tile.rsvp),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getRsvpStatusColor(tile.rsvp, colorScheme),
                      ),
                    ),
                  ),
                ],
              ),

              // Quick actions row
              if (hasLocation || isVideoConference)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      // Join meeting button (if video conference)
                      if (isVideoConference)
                        _buildQuickAction(
                          context,
                          icon: Icons.videocam_rounded,
                          label: l10n.joinMeeting,
                          color: Colors.blue,
                          onTap: () => _openLocation(context, locationAddress),
                        ),

                      // Open location button (if has location)
                      if (hasLocation && !isVideoConference)
                        _buildQuickAction(
                          context,
                          icon: _getLocationIcon(locationAddress),
                          label: l10n.openLink,
                          color: Colors.green,
                          onTap: () => _openLocation(context, locationAddress),
                        ),

                      const Spacer(),

                      // Edit tile button
                      _buildQuickAction(
                        context,
                        icon: Icons.edit_outlined,
                        label: l10n.editTile,
                        color: colorScheme.primary,
                        onTap: () => _navigateToEditTile(context, tile),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
