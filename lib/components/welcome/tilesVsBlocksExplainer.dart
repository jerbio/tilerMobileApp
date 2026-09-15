import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Widget keys for the explainer's timeline cards, so tests can assert
/// where each card sits at the end of each beat.
class TilesVsBlocksExplainerKeys {
  TilesVsBlocksExplainerKeys._();

  static const Key standupBlock = ValueKey('explainer-block-standup');
  static const Key dentistBlock = ValueKey('explainer-block-dentist');
  static const Key workoutTile = ValueKey('explainer-tile-workout');
  static const Key reportTile = ValueKey('explainer-tile-report');
  static const Key groceriesTile = ValueKey('explainer-tile-groceries');
}

/// The three beats of the explainer, in order.
enum ExplainerBeat { blocks, tiles, replan }

/// One card on the mini timeline: a fixed block or a flexible tile.
class _TimelineCard {
  final Key key;
  final String Function(AppLocalizations l10n) label;
  final bool isBlock;

  /// Slot (hour row) the card occupies before the re-plan beat.
  final int slotBefore;

  /// Slot it occupies once the re-plan beat has settled.
  final int slotAfter;

  /// Height in slots.
  final int span;

  /// Where in its entry beat (0..1) the card starts and finishes arriving.
  final double enterStart;
  final double enterEnd;

  /// Where in the re-plan beat (0..1) the card starts and finishes moving.
  final double moveStart;
  final double moveEnd;

  const _TimelineCard({
    required this.key,
    required this.label,
    required this.isBlock,
    required this.slotBefore,
    required this.slotAfter,
    this.span = 1,
    required this.enterStart,
    required this.enterEnd,
    this.moveStart = 0,
    this.moveEnd = 0,
  });

  bool get moves => slotBefore != slotAfter;
}

/// Animated "Tiles vs Blocks" explainer for the welcome screen
/// (product-tour-onboarding-redesign.md, stage 4.4).
///
/// A mini day timeline plays three beats of [beatDuration] each:
///   1. **blocks** — two pinned blocks land: fixed time.
///   2. **tiles** — three tiles slide into the free gaps: flexible.
///   3. **replan** — the dentist block jumps earlier and the tiles re-seat
///      around it: change a block and Tiler re-plans the tiles.
/// It then holds the final frame (no loop). With
/// `MediaQuery.disableAnimations` it shows the final frame immediately.
///
/// Built in Flutter rather than as a Lottie asset so the captions and card
/// labels are localised and the colours follow the theme.
class TilesVsBlocksExplainer extends StatefulWidget {
  /// Length of each of the three beats.
  static const Duration beatDuration = Duration(seconds: 2);

  static const int beatCount = 3;

  /// Total play time before the explainer settles.
  static Duration get totalDuration => beatDuration * beatCount;

  /// Called once when the last beat has settled.
  final VoidCallback? onFinished;

  const TilesVsBlocksExplainer({Key? key, this.onFinished}) : super(key: key);

  @override
  State<TilesVsBlocksExplainer> createState() => _TilesVsBlocksExplainerState();
}

class _TilesVsBlocksExplainerState extends State<TilesVsBlocksExplainer>
    with SingleTickerProviderStateMixin {
  /// Hour rows on the timeline, 9:00 through 16:00.
  static const int _firstHour = 9;
  static const int _slotCount = 8;

  // Slots: 0=9:00 1=10:00 2=11:00 3=12:00 4=13:00 5=14:00 6=15:00 7=16:00.
  static const List<_TimelineCard> _cards = [
    _TimelineCard(
      key: TilesVsBlocksExplainerKeys.standupBlock,
      label: _standupLabel,
      isBlock: true,
      slotBefore: 0,
      slotAfter: 0,
      enterStart: 0.0,
      enterEnd: 0.4,
    ),
    _TimelineCard(
      key: TilesVsBlocksExplainerKeys.dentistBlock,
      label: _dentistLabel,
      isBlock: true,
      slotBefore: 5,
      slotAfter: 2,
      enterStart: 0.25,
      enterEnd: 0.65,
      // The card announces the change first (badge + highlight over
      // [_announceWindow]), then moves.
      moveStart: 0.3,
      moveEnd: 0.6,
    ),
    _TimelineCard(
      key: TilesVsBlocksExplainerKeys.workoutTile,
      label: _workoutLabel,
      isBlock: false,
      slotBefore: 1,
      slotAfter: 1,
      enterStart: 0.0,
      enterEnd: 0.4,
    ),
    _TimelineCard(
      key: TilesVsBlocksExplainerKeys.reportTile,
      label: _reportLabel,
      isBlock: false,
      slotBefore: 2,
      slotAfter: 3,
      span: 2,
      enterStart: 0.2,
      enterEnd: 0.6,
      moveStart: 0.55,
      moveEnd: 0.85,
    ),
    _TimelineCard(
      key: TilesVsBlocksExplainerKeys.groceriesTile,
      label: _groceriesLabel,
      isBlock: false,
      slotBefore: 6,
      slotAfter: 5,
      enterStart: 0.4,
      enterEnd: 0.8,
      moveStart: 0.65,
      moveEnd: 0.95,
    ),
  ];

  static const double _captionFontSize = 16;
  static const double _captionLineHeight = 1.35;

  /// Slot the moving block lands on, for the re-plan caption.
  static const int _movedBlockSlotAfter = 2;

  /// Window (0..1 of the re-plan beat) over which the moving block's
  /// "Moved" badge and highlight fade in — before it starts moving.
  static const double _announceStart = 0.0;
  static const double _announceEnd = 0.2;

  static String _standupLabel(AppLocalizations l) =>
      l.welcomeExplainerBlockStandup;
  static String _dentistLabel(AppLocalizations l) =>
      l.welcomeExplainerBlockDentist;
  static String _workoutLabel(AppLocalizations l) =>
      l.welcomeExplainerTileWorkout;
  static String _reportLabel(AppLocalizations l) =>
      l.welcomeExplainerTileReport;
  static String _groceriesLabel(AppLocalizations l) =>
      l.welcomeExplainerTileGroceries;

  late final AnimationController _controller;
  bool _finishedNotified = false;
  bool _motionResolved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TilesVsBlocksExplainer.totalDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_finishedNotified) {
          _finishedNotified = true;
          widget.onFinished?.call();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionResolved) return;
    _motionResolved = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Which beat the controller is in, and progress (0..1) within it.
  (ExplainerBeat, double) _beatAt(double value) {
    final double scaled = value * TilesVsBlocksExplainer.beatCount;
    int index = scaled.floor();
    if (index >= TilesVsBlocksExplainer.beatCount) {
      index = TilesVsBlocksExplainer.beatCount - 1;
    }
    final double local = value >= 1.0 ? 1.0 : (scaled - index).clamp(0.0, 1.0);
    return (ExplainerBeat.values[index], local);
  }

  /// 0..1 progress of a sub-animation that runs from [start] to [end]
  /// within a beat at local progress [t].
  double _window(double t, double start, double end) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return Curves.easeOutCubic.transform((t - start) / (end - start));
  }

  /// Vertical slot the card sits at for the given beat/progress, as a
  /// fractional slot (mid-move values are in between).
  double _slotFor(_TimelineCard card, ExplainerBeat beat, double t) {
    if (beat != ExplainerBeat.replan || !card.moves) {
      return beat == ExplainerBeat.replan
          ? card.slotAfter.toDouble()
          : card.slotBefore.toDouble();
    }
    final double p = _window(t, card.moveStart, card.moveEnd);
    return card.slotBefore + (card.slotAfter - card.slotBefore) * p;
  }

  /// Entry progress (0 = not yet visible, 1 = settled) for the card.
  double _entryFor(_TimelineCard card, ExplainerBeat beat, double t) {
    final ExplainerBeat entryBeat =
        card.isBlock ? ExplainerBeat.blocks : ExplainerBeat.tiles;
    if (beat.index < entryBeat.index) return 0.0;
    if (beat.index > entryBeat.index) return 1.0;
    return _window(t, card.enterStart, card.enterEnd);
  }

  String _captionFor(
      BuildContext context, AppLocalizations l10n, ExplainerBeat beat) {
    switch (beat) {
      case ExplainerBeat.blocks:
        return l10n.welcomeExplainerBlocksCaption;
      case ExplainerBeat.tiles:
        return l10n.welcomeExplainerTilesCaption;
      case ExplainerBeat.replan:
        // Name the block that changed and where it went, so the tiles
        // re-seating reads as a consequence rather than a shuffle.
        final String newTime = MaterialLocalizations.of(context)
            .formatTimeOfDay(
                TimeOfDay(hour: _firstHour + _movedBlockSlotAfter, minute: 0));
        return l10n.welcomeExplainerReplanCaption(newTime);
    }
  }

  /// 0..1 strength of the "this block is changing" announcement (badge +
  /// highlight) for the given beat/progress. Only a *block* that moves
  /// announces itself — it is the cause; the tiles that re-seat afterwards
  /// are the effect and stay unbadged. Stays at 1 once shown so the badge
  /// persists into the final frame.
  double _announceFor(_TimelineCard card, ExplainerBeat beat, double t) {
    if (!card.isBlock || !card.moves || beat != ExplainerBeat.replan) {
      return 0.0;
    }
    return _window(t, _announceStart, _announceEnd);
  }

  /// 0..1 strength of the Tiler mark ("Re-planned" + the app's AI glyph)
  /// on a tile Tiler re-seats: fades in over the first half of the tile's
  /// own move, so the mark and the motion read as one act. A tile Tiler
  /// leaves alone never gets one — that absence is part of the message.
  /// Stays at 1 once shown so the mark persists into the final frame.
  double _readjustFor(_TimelineCard card, ExplainerBeat beat, double t) {
    if (card.isBlock || !card.moves || beat != ExplainerBeat.replan) {
      return 0.0;
    }
    final double midMove = card.moveStart + (card.moveEnd - card.moveStart) / 2;
    return _window(t, card.moveStart, midMove);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final (beat, t) = _beatAt(_controller.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildTimeline(context, l10n, colorScheme, beat, t),
            ),
            const SizedBox(height: 12),
            _buildLegend(l10n, colorScheme),
            const SizedBox(height: 8),
            // Caption: cross-fades between beats. Its height is fixed at
            // two lines so a longer caption never steals height from the
            // timeline above (which would shift every card mid-beat).
            SizedBox(
              height: _captionFontSize * _captionLineHeight * 2,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _captionFor(context, l10n, beat),
                  key: ValueKey<ExplainerBeat>(beat),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: _captionFontSize,
                    height: _captionLineHeight,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend(AppLocalizations l10n, ColorScheme colorScheme) {
    Widget item(Color fill, Color border, IconData? icon, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border, width: 1.5),
            ),
            child: icon == null
                ? null
                : Icon(icon, size: 9, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(
            colorScheme.onPrimary.withValues(alpha: 0.18),
            colorScheme.onPrimary,
            Icons.push_pin,
            l10n.welcomeExplainerLegendBlock),
        const SizedBox(width: 18),
        item(colorScheme.onPrimary, colorScheme.onPrimary, null,
            l10n.welcomeExplainerLegendTile),
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ExplainerBeat beat,
    double t,
  ) {
    final materialL10n = MaterialLocalizations.of(context);
    const double labelWidth = 52.0;
    const double cardGap = 3.0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final double rowHeight = constraints.maxHeight / _slotCount;
        final double cardLeft = labelWidth + 4;
        final double cardWidth = constraints.maxWidth - cardLeft - 6;

        final List<Widget> layers = [];

        // Hour grid.
        for (int slot = 0; slot < _slotCount; slot++) {
          final time = TimeOfDay(hour: _firstHour + slot, minute: 0);
          layers.add(Positioned(
            left: 0,
            right: 0,
            top: slot * rowHeight,
            height: rowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    materialL10n.formatTimeOfDay(time),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ));
        }

        // Cards. Blocks are drawn first so an in-flight tile passes over
        // nothing it should not.
        for (final card in _cards) {
          final double entry = _entryFor(card, beat, t);
          if (entry <= 0.0) continue; // not part of the story yet
          final double slot = _slotFor(card, beat, t);
          final double announce = _announceFor(card, beat, t);
          final double readjust = _readjustFor(card, beat, t);
          final double top = slot * rowHeight + cardGap;
          final double height = card.span * rowHeight - cardGap * 2;

          // Blocks drop in from slightly above; tiles slide in from the
          // right edge.
          final double dx = card.isBlock ? 0.0 : (1.0 - entry) * cardWidth;
          final double dy = card.isBlock ? (1.0 - entry) * -14.0 : 0.0;

          layers.add(Positioned(
            left: cardLeft + dx,
            top: top + dy,
            width: cardWidth,
            height: height,
            child: Opacity(
              opacity: entry.clamp(0.0, 1.0),
              child: _TimelineCardView(
                cardKey: card.key,
                label: card.label(l10n),
                isBlock: card.isBlock,
                colorScheme: colorScheme,
                announce: announce,
                badgeLabel: l10n.welcomeExplainerMovedBadge,
                readjust: readjust,
                readjustLabel: l10n.welcomeExplainerReplannedBadge,
              ),
            ),
          ));
        }

        return Stack(children: layers);
      }),
    );
  }
}

class _TimelineCardView extends StatelessWidget {
  final Key cardKey;
  final String label;
  final bool isBlock;
  final ColorScheme colorScheme;

  /// 0..1: how strongly the card announces that it is changing (border
  /// highlight + "Moved" badge). 0 for cards that are not changing.
  final double announce;
  final String badgeLabel;

  /// 0..1: how strongly the card shows Tiler's mark ("Re-planned" + the AI
  /// glyph) for a tile Tiler re-seated. 0 for everything else.
  final double readjust;
  final String readjustLabel;

  const _TimelineCardView({
    required this.cardKey,
    required this.label,
    required this.isBlock,
    required this.colorScheme,
    this.announce = 0.0,
    this.badgeLabel = '',
    this.readjust = 0.0,
    this.readjustLabel = '',
  });

  /// Small pill used for both the block's "Moved" badge and the tile's
  /// Tiler mark; [inverted] draws it in the surface colours so it stands
  /// out on a brand-coloured tile.
  Widget _pill(IconData icon, String text, double strength,
      {required bool inverted}) {
    final Color bg = inverted ? colorScheme.onPrimary : colorScheme.primary;
    final Color fg = inverted ? colorScheme.primary : colorScheme.onPrimary;
    return Opacity(
      opacity: strength.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color fill = isBlock
        ? colorScheme.onSurface.withValues(alpha: 0.10)
        : colorScheme.primary;
    final Color text = isBlock ? colorScheme.onSurface : colorScheme.onPrimary;
    final Color restingBorder = colorScheme.onSurface.withValues(alpha: 0.35);
    final Color? border = isBlock
        ? Color.lerp(restingBorder, colorScheme.primary, announce)
        : null;

    return Container(
      key: cardKey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: border == null
            ? null
            : Border.all(color: border, width: 1.2 + announce * 0.8),
      ),
      child: Row(
        children: [
          if (isBlock) ...[
            Icon(Icons.push_pin, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (announce > 0.0) ...[
            const SizedBox(width: 6),
            _pill(Icons.swap_vert, badgeLabel, announce, inverted: false),
          ],
          if (readjust > 0.0) ...[
            const SizedBox(width: 6),
            // The app's own AI glyph (the home FAB): this is Tiler acting.
            _pill(Icons.auto_awesome, readjustLabel, readjust, inverted: true),
          ],
        ],
      ),
    );
  }
}
