import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Enum representing different alert types
enum AlertType {
  travel, // Proactive departure alert
  conflict, // Schedule conflicts
  extended, // All-day/extended events
  rsvp, // Pending RSVP responses
}

/// Data class representing an active alert
class ActiveAlert {
  final AlertType type;
  final int count;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isUrgent;

  const ActiveAlert({
    required this.type,
    required this.count,
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
    this.isUrgent = false,
  });
}

/// Combined alerts banner that consolidates multiple active alerts into one row
/// When only one alert is active, it displays the full banner
/// When multiple alerts are active, it shows compact icons that can be tapped
class CombinedAlertsBanner extends StatefulWidget {
  // Travel alert data
  final SubCalendarEvent? nextTileWithTravel;
  final VoidCallback? onTravelTap;
  final VoidCallback? onTravelDismiss;

  // Conflict alert data
  final List<ConflictGroup> conflictGroups;
  final VoidCallback? onConflictTap;

  // Extended tiles data
  final List<SubCalendarEvent> extendedTiles;
  final VoidCallback? onExtendedTap;

  // RSVP data
  final List<SubCalendarEvent> pendingRsvpTiles;
  final VoidCallback? onRsvpTap;
  final VoidCallback? onRsvpUpdated;

  const CombinedAlertsBanner({
    Key? key,
    this.nextTileWithTravel,
    this.onTravelTap,
    this.onTravelDismiss,
    this.conflictGroups = const [],
    this.onConflictTap,
    this.extendedTiles = const [],
    this.onExtendedTap,
    this.pendingRsvpTiles = const [],
    this.onRsvpTap,
    this.onRsvpUpdated,
  }) : super(key: key);

  /// Factory method to create from raw tile data
  static CombinedAlertsBanner fromTiles({
    Key? key,
    required List<TilerEvent> tiles,
    SubCalendarEvent? nextTileWithTravel,
    VoidCallback? onTravelTap,
    VoidCallback? onTravelDismiss,
    VoidCallback? onConflictTap,
    VoidCallback? onExtendedTap,
    VoidCallback? onRsvpTap,
    VoidCallback? onRsvpUpdated,
  }) {
    // Detect conflicts (excluding extended tiles)
    const int minDurationMs = 16 * 60 * 60 * 1000;
    final regularTiles = tiles.where((tile) {
      if (tile is SubCalendarEvent && tile.start != null && tile.end != null) {
        return (tile.end! - tile.start!) < minDurationMs;
      }
      return true;
    }).toList();

    final subCalendarEvents =
        regularTiles.whereType<SubCalendarEvent>().toList();
    final conflictGroups = ConflictGroup.detectGroups(subCalendarEvents);

    // Detect extended tiles
    final extendedTiles = ExtendedTilesBanner.detectExtendedTiles(tiles);

    // Detect pending RSVP tiles
    final pendingRsvpTiles = PendingRsvpBanner.detectPendingRsvpTiles(tiles);

    return CombinedAlertsBanner(
      key: key,
      nextTileWithTravel: nextTileWithTravel,
      onTravelTap: onTravelTap,
      onTravelDismiss: onTravelDismiss,
      conflictGroups: conflictGroups,
      onConflictTap: onConflictTap,
      extendedTiles: extendedTiles,
      onExtendedTap: onExtendedTap,
      pendingRsvpTiles: pendingRsvpTiles,
      onRsvpTap: onRsvpTap,
      onRsvpUpdated: onRsvpUpdated,
    );
  }

  @override
  State<CombinedAlertsBanner> createState() => _CombinedAlertsBannerState();
}

class _CombinedAlertsBannerState extends State<CombinedAlertsBanner>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  int _minutesUntilLeave = -1;
  bool _travelAlertActive = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _calculateTimeToLeave();
    _startUpdateTimer();
  }

  @override
  void didUpdateWidget(CombinedAlertsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextTileWithTravel != widget.nextTileWithTravel) {
      _calculateTimeToLeave();
    }
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _calculateTimeToLeave();
    });
  }

  void _calculateTimeToLeave() {
    if (widget.nextTileWithTravel == null) {
      if (mounted && _travelAlertActive) {
        setState(() {
          _travelAlertActive = false;
          _minutesUntilLeave = -1;
        });
      }
      return;
    }

    final tile = widget.nextTileWithTravel!;
    final travelTimeBefore = tile.travelTimeBefore ?? 0;

    if (travelTimeBefore <= 0) {
      if (mounted && _travelAlertActive) {
        setState(() {
          _travelAlertActive = false;
          _minutesUntilLeave = -1;
        });
      }
      return;
    }

    final now = Utility.msCurrentTime;
    final tileStart = tile.start ?? 0;
    final leaveTime = tileStart - travelTimeBefore.toInt();
    final msUntilLeave = leaveTime - now;
    final minutesUntilLeave = (msUntilLeave / 60000).round();

    // Show alert if user needs to leave within 30 minutes
    if (minutesUntilLeave > 0 && minutesUntilLeave <= 30) {
      if (mounted) {
        setState(() {
          _minutesUntilLeave = minutesUntilLeave;
          _travelAlertActive = true;
        });
      }
    } else if (minutesUntilLeave <= 0 && minutesUntilLeave > -5) {
      // Show "Leave now!" for up to 5 minutes after optimal leave time
      if (mounted) {
        setState(() {
          _minutesUntilLeave = 0;
          _travelAlertActive = true;
        });
      }
    } else {
      if (mounted && _travelAlertActive) {
        setState(() {
          _travelAlertActive = false;
          _minutesUntilLeave = -1;
        });
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Get all active alerts
  List<ActiveAlert> _getActiveAlerts(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<ActiveAlert> alerts = [];

    // 1. Travel alert (highest priority)
    if (_travelAlertActive && widget.nextTileWithTravel != null) {
      final isUrgent = _minutesUntilLeave <= 5;
      String label;
      if (_minutesUntilLeave <= 0) {
        label = l10n.leaveNow;
      } else {
        label = l10n.leaveInMinutes(_minutesUntilLeave);
      }

      alerts.add(ActiveAlert(
        type: AlertType.travel,
        count: 1,
        color: isUrgent ? TileColors.warning : TileColors.travel,
        icon: isUrgent ? Icons.warning_amber_rounded : Icons.directions_car,
        label: label,
        onTap: widget.onTravelTap,
        isUrgent: isUrgent,
      ));
    }

    // 2. Conflict alert
    if (widget.conflictGroups.isNotEmpty) {
      final conflictCount = widget.conflictGroups
          .fold(0, (sum, group) => sum + group.tiles.length);

      alerts.add(ActiveAlert(
        type: AlertType.conflict,
        count: conflictCount,
        color: Colors.orange.shade500,
        icon: Icons.warning_rounded,
        label: conflictCount == 1
            ? l10n.oneScheduleConflict
            : l10n.countScheduleConflicts(conflictCount),
        onTap: widget.onConflictTap,
      ));
    }

    // 3. Extended tiles alert
    if (widget.extendedTiles.isNotEmpty) {
      alerts.add(ActiveAlert(
        type: AlertType.extended,
        count: widget.extendedTiles.length,
        color: Colors.blue.shade500,
        icon: Icons.calendar_today_rounded,
        label: widget.extendedTiles.length == 1
            ? l10n.extendedEventSingular
            : l10n.extendedEventsPlural(widget.extendedTiles.length),
        onTap: widget.onExtendedTap,
      ));
    }

    // 4. RSVP alert
    if (widget.pendingRsvpTiles.isNotEmpty) {
      final hasNeedsAction =
          widget.pendingRsvpTiles.any((t) => t.rsvp == RsvpStatus.needsAction);

      alerts.add(ActiveAlert(
        type: AlertType.rsvp,
        count: widget.pendingRsvpTiles.length,
        color: _getRsvpUrgencyColor(),
        icon: hasNeedsAction
            ? Icons.pending_actions_rounded
            : Icons.help_outline_rounded,
        label: widget.pendingRsvpTiles.length == 1
            ? l10n.pendingRsvpSingular
            : l10n.pendingRsvpPlural(widget.pendingRsvpTiles.length),
        onTap: widget.onRsvpTap,
      ));
    }

    return alerts;
  }

  Color _getRsvpUrgencyColor() {
    if (widget.pendingRsvpTiles.isEmpty) return Colors.orange.shade400;

    final mostUrgent =
        PendingRsvpBanner.getMostUrgentTile(widget.pendingRsvpTiles);
    if (mostUrgent == null) return Colors.orange.shade400;

    final now = Utility.currentTime().millisecondsSinceEpoch;
    final tileStart = mostUrgent.start ?? now;
    final timeTilStart = tileStart - now;

    if (timeTilStart <= 0) {
      return Colors.red.shade500;
    } else if (timeTilStart <= 30 * 60 * 1000) {
      return Colors.orange.shade600;
    } else if (timeTilStart <= 60 * 60 * 1000) {
      return Colors.amber.shade600;
    }

    return Colors.orange.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _getActiveAlerts(context);

    if (alerts.isEmpty) return const SizedBox.shrink();

    // Animate in
    if (_animationController.status != AnimationStatus.completed &&
        _animationController.status != AnimationStatus.forward) {
      _animationController.forward();
    }

    // If only one alert, show full banner style
    if (alerts.length == 1) {
      return _buildSingleAlertBanner(context, alerts.first);
    }

    // Multiple alerts: show combined compact row
    return _buildCombinedAlertRow(context, alerts);
  }

  /// Build a full-width banner for a single alert (same as original banners)
  Widget _buildSingleAlertBanner(BuildContext context, ActiveAlert alert) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: alert.onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                alert.color,
                alert.color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: alert.color.withAlpha(77),
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
                  alert.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.label,
                  style: const TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              if (alert.onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a combined row with multiple alert chips
  Widget _buildCombinedAlertRow(
      BuildContext context, List<ActiveAlert> alerts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sort alerts by urgency (travel first if urgent, then by type priority)
    alerts.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return a.type.index.compareTo(b.type.index);
    });

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Alert chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: alerts.map((alert) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAlertChip(context, alert),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build an individual alert chip
  Widget _buildAlertChip(BuildContext context, ActiveAlert alert) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alert.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: alert.color.withOpacity(alert.isUrgent ? 1.0 : 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: alert.isUrgent
                ? [
                    BoxShadow(
                      color: alert.color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                alert.icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              // Always show descriptive label with count
              Text(
                _getChipLabel(context, alert),
                style: const TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get descriptive label for chip display
  String _getChipLabel(BuildContext context, ActiveAlert alert) {
    final l10n = AppLocalizations.of(context)!;

    switch (alert.type) {
      case AlertType.travel:
        if (_minutesUntilLeave <= 0) {
          return l10n.alertChipLeaveNow;
        }
        return l10n.alertChipLeaveIn(_minutesUntilLeave);
      case AlertType.conflict:
        return l10n.alertChipConflicts(alert.count);
      case AlertType.extended:
        return l10n.alertChipAllDay(alert.count);
      case AlertType.rsvp:
        return l10n.alertChipRsvp(alert.count);
    }
  }
}

/// Extension to easily show the appropriate modal/action for each alert type
extension CombinedAlertsBannerHelpers on CombinedAlertsBanner {
  /// Show the extended tiles modal
  static void showExtendedTilesModal(
      BuildContext context, List<SubCalendarEvent> extendedTiles) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtendedTilesModal(extendedTiles: extendedTiles),
    );
  }

  /// Show the pending RSVP modal
  static void showPendingRsvpModal(
    BuildContext context,
    List<SubCalendarEvent> pendingTiles, {
    VoidCallback? onRsvpUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PendingRsvpModal(
        pendingTiles: pendingTiles,
        onRsvpUpdated: onRsvpUpdated,
      ),
    );
  }
}
