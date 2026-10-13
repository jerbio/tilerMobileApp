import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/util.dart';

/// The day before and after a schedule change, side by side: every tile in
/// time order on each side, a line joining each moved tile's old and new
/// spot, tiles that left the day dimmed with where they went, and tiles that
/// arrived marked with where they came from.
class ScheduleChangeBeforeAfter extends StatelessWidget {
  final ScheduleChangeSummary summary;

  const ScheduleChangeBeforeAfter({super.key, required this.summary});

  static const double rowHeight = 48;
  static const double _gutter = 40;
  static const double _rowGap = 4;

  static Key rowKey(String side, String id) => Key('before_after_${side}_$id');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final before = summary.beforeDay;
    final after = summary.afterDay;
    final delta = summary.delta;

    // Which rows to join: tiles on the day on both sides that moved.
    final links = <(int, int)>[];
    for (var i = 0; i < before.length; i++) {
      final kind = delta.changeFor(before[i].uniqueId)?.kind;
      if (kind != TileChangeKind.moved &&
          kind != TileChangeKind.movedAndResized &&
          kind != TileChangeKind.resized) {
        continue;
      }
      final j = after.indexWhere((t) => t.uniqueId == before[i].uniqueId);
      if (j >= 0) links.add((i, j));
    }
    final rows = before.length > after.length ? before.length : after.length;
    final height = rows * (rowHeight + _rowGap);
    final headerStyle = theme.textTheme.labelMedium
        ?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Text(l10n.scheduleChangeBefore, style: headerStyle)),
          const SizedBox(width: _gutter),
          Expanded(child: Text(l10n.scheduleChangeAfter, style: headerStyle)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: LayoutBuilder(builder: (context, constraints) {
            final column = (constraints.maxWidth - _gutter) / 2;
            return Stack(children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinkPainter(
                    links: links,
                    leftX: column,
                    rightX: column + _gutter,
                    rowExtent: rowHeight + _rowGap,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: column,
                child: Column(children: [
                  for (final tile in before)
                    _Row(
                      key: rowKey('before', tile.uniqueId),
                      tile: tile,
                      side: _Side.before,
                      change: delta.changeFor(tile.uniqueId),
                    ),
                ]),
              ),
              Positioned(
                left: column + _gutter,
                top: 0,
                width: column,
                child: Column(children: [
                  for (final tile in after)
                    _Row(
                      key: rowKey('after', tile.uniqueId),
                      tile: tile,
                      side: _Side.after,
                      change: delta.changeFor(tile.uniqueId),
                    ),
                ]),
              ),
            ]);
          }),
        ),
      ],
    );
  }
}

enum _Side { before, after }

/// One tile on one side: its time and name, highlighted when it changed.
class _Row extends StatelessWidget {
  final SubCalendarEvent tile;
  final _Side side;
  final TileChange? change;

  const _Row({super.key, required this.tile, required this.side, this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final materialL10n = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context)!;
    String time(int ms) => materialL10n.formatTimeOfDay(
        TimeOfDay.fromDateTime(Utility.localDateTimeFromMs(ms)),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    String date(int ms) =>
        materialL10n.formatMediumDate(Utility.localDateTimeFromMs(ms));

    final kind = change?.kind;
    final changed = kind != null;
    // Left the day (before side) or is gone: dimmed, with where it went.
    final leaving = side == _Side.before &&
        (kind == TileChangeKind.movedToOtherDay ||
            kind == TileChangeKind.removed);
    String? note;
    if (side == _Side.before && kind == TileChangeKind.movedToOtherDay) {
      note = '→ ${date(change!.after!.start!)}';
    } else if (side == _Side.before && kind == TileChangeKind.removed) {
      note = l10n.scheduleChangeRemoved;
    } else if (side == _Side.after &&
        kind == TileChangeKind.movedFromOtherDay) {
      note = '← ${date(change!.before!.start!)}';
    }
    final name = (tile.name?.trim().isNotEmpty ?? false)
        ? tile.name!.trim()
        : l10n.untitledTile;
    final accent = tile.color ?? colorScheme.primary;

    return Opacity(
      opacity: leaving ? 0.55 : 1,
      child: Container(
        height: ScheduleChangeBeforeAfter.rowHeight,
        margin:
            const EdgeInsets.only(bottom: ScheduleChangeBeforeAfter._rowGap),
        padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
        decoration: BoxDecoration(
          color: changed && !leaving
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              note == null ? time(tile.start!) : '${time(tile.start!)}  $note',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: changed
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
                decoration:
                    side == _Side.before && kind == TileChangeKind.removed
                        ? TextDecoration.lineThrough
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curves from each moved tile's row on the left to its row on the right.
class _LinkPainter extends CustomPainter {
  final List<(int, int)> links;
  final double leftX;
  final double rightX;
  final double rowExtent;
  final Color color;

  _LinkPainter({
    required this.links,
    required this.leftX,
    required this.rightX,
    required this.rowExtent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = color;
    final middle = (leftX + rightX) / 2;
    for (final (i, j) in links) {
      final from = Offset(
          leftX, i * rowExtent + ScheduleChangeBeforeAfter.rowHeight / 2);
      final to = Offset(
          rightX, j * rowExtent + ScheduleChangeBeforeAfter.rowHeight / 2);
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(middle, from.dy, middle, to.dy, to.dx, to.dy),
        line,
      );
      canvas.drawCircle(from, 3, dot);
      canvas.drawCircle(to, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) =>
      old.links != links ||
      old.leftX != leftX ||
      old.rightX != rightX ||
      old.color != color;
}
