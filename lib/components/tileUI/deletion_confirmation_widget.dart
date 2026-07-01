import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class DeletionConfirmationWidget extends StatefulWidget {
  final bool isRigid;
  final TileSource? tileSource;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeletionConfirmationWidget({
    required this.isRigid,
    required this.tileSource,
    required this.onCancel,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  DeletionConfirmationWidgetState createState() =>
      DeletionConfirmationWidgetState();
}

class DeletionConfirmationWidgetState extends State<DeletionConfirmationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownController;
  late Timer _countdownTimer;
  int _remainingSeconds = 3;
  bool _isDone = false;
  final int _totalSeconds = 3;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      duration: Duration(seconds: _totalSeconds),
      vsync: this,
    )
      ..addListener(() {
        // Rebuild every vsync frame for smooth progress bar
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _confirmDeletion();
        }
      })
      ..forward();

    // Update the displayed integer independently of the animation
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isDone) {
        setState(() {
          _remainingSeconds =
              (_totalSeconds - timer.tick).clamp(0, _totalSeconds);
        });
      }
    });
  }

  void _cancelDeletion() {
    if (_isDone) return;
    _isDone = true;
    _countdownTimer.cancel();
    _countdownController.stop();
    widget.onCancel();
  }

  void _confirmDeletion() {
    if (_isDone) return;
    _isDone = true;
    _countdownTimer.cancel();
    _countdownController.stop();
    widget.onConfirm();
  }

  String get _getMessage {
    if (widget.isRigid) {
      return AppLocalizations.of(context)?.deleteBlockConfirming ??
          'Deleting this block...';
    } else {
      return AppLocalizations.of(context)?.deleteTileConfirming ??
          'Deleting this tile...';
    }
  }

  String get _getThirdPartyWarning {
    switch (widget.tileSource) {
      case TileSource.google:
        return '⚠️ This will also delete from Google Calendar';
      case TileSource.outlook:
        return '⚠️ This will also delete from Outlook';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warning = _getThirdPartyWarning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main message
          Text(
            _getMessage,
            style: TextStyle(
              fontSize: 16,
              fontFamily: TileTextStyles.rubikFontName,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Custom progress bar with fully rounded fill caps + countdown number
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      // Track
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Fill — FractionallySizedBox gives both caps rounded
                      FractionallySizedBox(
                        widthFactor: _countdownController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _remainingSeconds.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: TileTextStyles.rubikFontName,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),

          if (warning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              warning,
              style: TextStyle(
                fontSize: 12,
                fontFamily: TileTextStyles.rubikFontName,
                color: colorScheme.error,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelDeletion,
                child: Text(
                  AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _confirmDeletion,
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.error.withValues(alpha: 0.15),
                  foregroundColor: colorScheme.error,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text(
                  AppLocalizations.of(context)?.deleteNow ?? 'Delete Now',
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
