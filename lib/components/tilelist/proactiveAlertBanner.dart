import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Proactive alert banner that shows "Leave in X min to arrive on time"
/// Displayed at the top of the timeline when user needs to leave soon
class ProactiveAlertBanner extends StatefulWidget {
  final SubCalendarEvent? nextTileWithTravel;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ProactiveAlertBanner({
    Key? key,
    this.nextTileWithTravel,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<ProactiveAlertBanner> createState() => _ProactiveAlertBannerState();
}

class _ProactiveAlertBannerState extends State<ProactiveAlertBanner>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  int _minutesUntilLeave = 0;
  bool _isVisible = false;
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
    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _calculateTimeToLeave();
    _startUpdateTimer();
  }

  @override
  void didUpdateWidget(ProactiveAlertBanner oldWidget) {
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
      _hideAlert();
      return;
    }

    final tile = widget.nextTileWithTravel!;
    final travelTimeBefore = tile.travelTimeBefore ?? 0;

    if (travelTimeBefore <= 0) {
      _hideAlert();
      return;
    }

    final now = Utility.msCurrentTime;
    final tileStart = tile.start ?? 0;
    final leaveTime = tileStart - travelTimeBefore.toInt();
    final msUntilLeave = leaveTime - now;
    final minutesUntilLeave = (msUntilLeave / 60000).round();

    // Show alert if user needs to leave within 30 minutes
    if (minutesUntilLeave > 0 && minutesUntilLeave <= 30) {
      setState(() {
        _minutesUntilLeave = minutesUntilLeave;
        _isVisible = true;
      });
      _animationController.forward();
    } else if (minutesUntilLeave <= 0 && minutesUntilLeave > -5) {
      // Show "Leave now!" for up to 5 minutes after optimal leave time
      setState(() {
        _minutesUntilLeave = 0;
        _isVisible = true;
      });
      _animationController.forward();
    } else {
      _hideAlert();
    }
  }

  void _hideAlert() {
    if (_isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getAlertMessage(BuildContext context) {
    if (_minutesUntilLeave <= 0) {
      // Use youNeedToLeaveIn which already exists
      return 'Leave now to arrive on time!';
    }
    // Use existing localization key youNeedToLeaveInDuration
    final durationStr = '$_minutesUntilLeave min';
    return AppLocalizations.of(context)
            ?.youNeedToLeaveInDuration(durationStr) ??
        'Leave in $_minutesUntilLeave min to arrive on time';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible && !_animationController.isAnimating) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUrgent = _minutesUntilLeave <= 5;

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
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUrgent
                  ? [
                      TileColors.warning.withOpacity(0.9),
                      TileColors.travel.withOpacity(0.9),
                    ]
                  : [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.8),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUrgent
                        ? Icons.warning_amber_rounded
                        : Icons.directions_car,
                    color: isUrgent
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getAlertMessage(context),
                        style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isUrgent
                              ? Colors.white
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (widget.nextTileWithTravel?.name != null)
                        Text(
                          widget.nextTileWithTravel!.name!,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 12,
                            color: (isUrgent
                                    ? Colors.white
                                    : colorScheme.onPrimaryContainer)
                                .withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (widget.onDismiss != null)
                  IconButton(
                    onPressed: () {
                      _hideAlert();
                      widget.onDismiss?.call();
                    },
                    icon: Icon(
                      Icons.close,
                      color: isUrgent
                          ? Colors.white
                          : colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
