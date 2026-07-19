import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/tileUI/timeScrubGeometry.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/freeSlot.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// A full-width open time window rendered inline within the timeline, in the
/// same lane as travel connectors — between the tile that precedes the gap and
/// the tile that follows it.
///
/// It is visually distinct from tiles and alert chips (a dashed "open window"
/// treatment) and taps through to [AddTile] with the window pre-filled so the
/// user can schedule directly into the gap.
class FreeSlotRow extends StatelessWidget {
  final FreeSlot slot;

  /// When true (preview mode) the row renders but does not navigate.
  final bool preview;

  const FreeSlotRow({
    Key? key,
    required this.slot,
    this.preview = false,
  }) : super(key: key);

  void _openAddTile(BuildContext context) {
    if (preview) return;
    final preTile = SimpleAdditionTile(duration: slot.duration)
      ..startTime = slot.startTime;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTile(
          preTile: preTile,
          autoDeadline: slot.endTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat.jm();

    // "Open / available" palette — a calm green to signal free, bookable time.
    // Deliberately not the alert-chip warning colors or the travel gradient.
    final Color accent =
        slot.isLive ? const Color(0xFF2E9E5B) : const Color(0xFF4CAF7D);
    final String range =
        '${timeFmt.format(slot.startTime)} – ${timeFmt.format(slot.endTime)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
      child: GestureDetector(
        onTap: () => _openAddTile(context),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: accent.withOpacity(0.55),
            radius: 12,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            slot.duration.toHumanLocalized(context),
                            style: TextStyle(
                              fontFamily: TileTextStyles.rubikFontName,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.freeSlotHeader,
                            style: TextStyle(
                              fontFamily: TileTextStyles.rubikFontName,
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                          if (slot.isLive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.freeSlotNow,
                                style: const TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        range,
                        style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (slot.isLive)
                        _LiveFreeSlotFooter(slot: slot, accent: accent),
                    ],
                  ),
                ),
                if (!preview)
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: accent.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live-only footer: a countdown to the end of the open window plus a slim
/// depleting scrubber, with a gentle pulse to signal "this time is yours to
/// grab." Non-live slots never build this, so the extra timer/animation cost
/// is confined to the one window that is actually happening now.
class _LiveFreeSlotFooter extends StatefulWidget {
  final FreeSlot slot;
  final Color accent;
  const _LiveFreeSlotFooter({required this.slot, required this.accent});

  @override
  State<_LiveFreeSlotFooter> createState() => _LiveFreeSlotFooterState();
}

class _LiveFreeSlotFooterState extends State<_LiveFreeSlotFooter>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // Refresh the countdown and bar each second while the window is live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowMs = Utility.msCurrentTime;
    final geometry = TimeScrubGeometry(
      startMs: widget.slot.startMs,
      endMs: widget.slot.endMs,
      nowMs: nowMs,
    );
    final double remainingFraction = (1.0 - geometry.progress).clamp(0.0, 1.0);
    final int spanMs = widget.slot.endMs - widget.slot.startMs;
    final Duration remaining = Duration(
      milliseconds: (widget.slot.endMs - nowMs).clamp(0, spanMs),
    );

    return Padding(
      key: const ValueKey('freeSlotLiveFooter'),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: widget.accent),
          const SizedBox(width: 6),
          Text(
            remaining.toHumanLocalized(context),
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) {
                final double glow = 0.35 + (_glow.value * 0.45);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 5,
                    color: widget.accent.withOpacity(0.15),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: remainingFraction,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.accent.withOpacity(glow),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(glow * 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a rounded dashed border to reinforce the "open / unbooked" reading.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    const double dashWidth = 4;
    const double dashGap = 3;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
