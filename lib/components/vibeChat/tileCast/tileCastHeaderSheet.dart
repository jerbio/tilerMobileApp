import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Auto-hiding TileCast header.
///
/// Combines a slim, always-visible control strip (prev / position / next /
/// list + a grab handle) with a title panel that slides down to reveal the
/// focused action's name, then retracts on its own.
///
/// Meant to be overlaid on top of the carousel schedule (via a [Stack]) so the
/// verbose action title never permanently steals vertical space. Reserve
/// [collapsedHeight] worth of top padding on the underlying schedule so the
/// strip does not cover its content.
///
/// Behaviour:
/// * Whenever [index] changes the title peeks open for [autoHideDelay], then
///   slides shut again.
/// * Dragging (or tapping) the grab handle opens the title and *pins* it —
///   auto-hide is suspended until the user closes it again.
class TileCastHeaderSheet extends StatefulWidget {
  static const stripKey = ValueKey('tilecast_strip');
  static const handleKey = ValueKey('tilecast_handle');
  static const prevKey = ValueKey('tilecast_prev');
  static const nextKey = ValueKey('tilecast_next');
  static const listKey = ValueKey('tilecast_list');
  static const titleKey = ValueKey('tilecast_title');
  static const positionKey = ValueKey('tilecast_position');
  static const warningDotKey = ValueKey('tilecast_warning_dot');
  static const staleBannerKey = ValueKey('tilecast_stale_banner');
  static const nonViableKey = ValueKey('tilecast_nonviable');

  /// Height of the always-visible control strip. Use this to pad the schedule
  /// that renders beneath the overlay.
  static const double collapsedHeight = 46.0;

  final VibePreviewAction action;
  final int index;
  final int total;
  final bool isStale;
  final bool isNonViable;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onOpenList;

  /// How long the title stays open after an automatic peek before retracting.
  final Duration autoHideDelay;

  /// Slide animation duration.
  final Duration slideDuration;

  const TileCastHeaderSheet({
    Key? key,
    required this.action,
    required this.index,
    required this.total,
    this.isStale = false,
    this.isNonViable = false,
    this.onPrev,
    this.onNext,
    this.onOpenList,
    this.autoHideDelay = const Duration(seconds: 3),
    this.slideDuration = const Duration(milliseconds: 260),
  }) : super(key: key);

  @override
  State<TileCastHeaderSheet> createState() => _TileCastHeaderSheetState();
}

class _TileCastHeaderSheetState extends State<TileCastHeaderSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoHideTimer;
  bool _pinned = false;
  bool _dragging = false;

  bool get _reduceMotion =>
      WidgetsBinding.instance.disableAnimations ||
      (mounted && MediaQuery.maybeOf(context)?.disableAnimations == true);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
      value: 1, // start revealed so the first action is announced
    );
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant TileCastHeaderSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _peek();
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Reveal the title, then arm the auto-hide timer (unless pinned).
  void _peek() {
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    if (_pinned) return;
    _autoHideTimer = Timer(widget.autoHideDelay, () {
      if (!mounted || _pinned || _dragging) return;
      if (_reduceMotion) {
        _controller.value = 0;
      } else {
        _controller.reverse();
      }
    });
  }

  void _toggle() {
    _autoHideTimer?.cancel();
    final opening = _controller.value < 0.5;
    _pinned = opening; // pin when the user opens it manually
    if (_reduceMotion) {
      _controller.value = opening ? 1 : 0;
    } else {
      opening ? _controller.forward() : _controller.reverse();
    }
    if (!opening) _scheduleAutoHide();
    setState(() {});
  }

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _autoHideTimer?.cancel();
  }

  void _onDragUpdate(DragUpdateDetails details, double panelHeight) {
    if (panelHeight <= 0) return;
    _controller.value =
        (_controller.value + details.primaryDelta! / panelHeight)
            .clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final bool open = velocity.abs() > 250
        ? velocity > 0
        : _controller.value >= 0.5;
    _pinned = open;
    if (_reduceMotion) {
      _controller.value = open ? 1 : 0;
    } else {
      open ? _controller.forward() : _controller.reverse();
    }
    if (!open) _scheduleAutoHide();
    setState(() {});
  }

  String _resolveTitle(AppLocalizations localization) {
    final description = widget.action.action?.descriptions;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }
    return localization.reviewChanges;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    final bool hasWarning = widget.isNonViable || widget.isStale;

    return Material(
      key: TileCastHeaderSheet.stripKey,
      color: colorScheme.surfaceContainerLowest,
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStrip(context, colorScheme, localization, hasWarning),
          _buildSlidingTitle(context, colorScheme, localization),
        ],
      ),
    );
  }

  Widget _buildStrip(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localization,
    bool hasWarning,
  ) {
    final bool canGoPrev = widget.index > 0;
    final bool canGoNext = widget.index < widget.total - 1;

    return SizedBox(
      height: TileCastHeaderSheet.collapsedHeight,
      child: Row(
        children: [
          IconButton(
            key: TileCastHeaderSheet.prevKey,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: canGoPrev ? widget.onPrev : null,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: GestureDetector(
              key: TileCastHeaderSheet.handleKey,
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: (d) => _onDragUpdate(d, _panelHeight),
              onVerticalDragEnd: _onDragEnd,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasWarning) ...[
                        Icon(
                          key: TileCastHeaderSheet.warningDotKey,
                          Icons.info_outline_rounded,
                          size: 13,
                          color: widget.isNonViable
                              ? colorScheme.error
                              : colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${widget.index + 1} / ${widget.total}',
                        key: TileCastHeaderSheet.positionKey,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: TileCastHeaderSheet.nextKey,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canGoNext ? widget.onNext : null,
            tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          ),
          IconButton(
            key: TileCastHeaderSheet.listKey,
            icon: const Icon(Icons.list_rounded),
            onPressed: widget.onOpenList,
            tooltip: localization.reviewChanges,
          ),
        ],
      ),
    );
  }

  /// Estimated height of the revealed title panel, used to translate drag
  /// deltas into animation progress.
  double get _panelHeight {
    double height = 44;
    if (widget.isNonViable) height += 30;
    if (widget.isStale) height += 34;
    return height;
  }

  Widget _buildSlidingTitle(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localization,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      axisAlignment: -1,
      child: Container(
        width: double.infinity,
        color: colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _resolveTitle(localization),
              key: TileCastHeaderSheet.titleKey,
              textAlign: TextAlign.center,
              maxLines: _pinned ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (widget.isNonViable) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: Container(
                  key: TileCastHeaderSheet.nonViableKey,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 14, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 4),
                      Text(
                        localization.previewNonViableLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.isStale) ...[
              const SizedBox(height: 6),
              Container(
                key: TileCastHeaderSheet.staleBannerKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 14, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        localization.previewStaleBanner,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
