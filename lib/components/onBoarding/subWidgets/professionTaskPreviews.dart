import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative examples anchored to profession rows. They never intercept taps
/// or change a row's size, and only fully visible rows take part in the rotation.
class ProfessionTaskPreviews extends StatefulWidget {
  final List<Widget> children;
  final List<String> previews;
  final Widget? footer;

  const ProfessionTaskPreviews({
    super.key,
    required this.children,
    required this.previews,
    this.footer,
  }) : assert(children.length == previews.length);

  @override
  State<ProfessionTaskPreviews> createState() => _ProfessionTaskPreviewsState();
}

class _ProfessionTaskPreviewsState extends State<ProfessionTaskPreviews>
    with WidgetsBindingObserver {
  final _random = math.Random();
  final _active = <int>{};
  final _hideTimers = <int, Timer>{};
  final _remaining = <int>[];
  late final List<GlobalKey> _anchors;
  Timer? _nextTimer;
  bool _motionAllowed = false;
  bool _foreground = true;
  bool _playing = false;
  int? _lastPreview;

  @override
  void initState() {
    super.initState();
    _anchors = List.generate(widget.children.length, (_) => GlobalKey());
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _motionAllowed = !media.disableAnimations &&
        !media.accessibleNavigation &&
        media.viewInsets.bottom == 0 &&
        media.textScaler.scale(10) <= 13 &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void didChangeMetrics() {
    if (mounted) _syncPlayback();
  }

  void _syncPlayback() {
    // Scaffold removes keyboard insets from its body, so also check the view.
    final shouldPlay = _motionAllowed &&
        _foreground &&
        View.of(context).viewInsets.bottom == 0;
    if (_playing == shouldPlay) return;
    _playing = shouldPlay;
    if (_playing) {
      _nextTimer = Timer(const Duration(milliseconds: 350), _showNext);
    } else {
      _cancelTimers();
      if (_active.isNotEmpty) setState(_active.clear);
    }
  }

  bool _isVisible(int index) {
    final anchorContext = _anchors[index].currentContext;
    final row = anchorContext?.findRenderObject();
    if (anchorContext == null || row is! RenderBox || !row.hasSize)
      return false;
    final viewport =
        Scrollable.maybeOf(anchorContext)?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return false;
    final rowRect = row.localToGlobal(Offset.zero) & row.size;
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    return rowRect.top >= viewportRect.top + 12 &&
        rowRect.bottom <= viewportRect.bottom;
  }

  void _showNext() {
    if (!mounted || !_playing) return;
    final candidates = List.generate(widget.children.length, (index) => index)
        .where((index) => !_active.contains(index) && _isVisible(index))
        .toList();
    if (candidates.length > 1) candidates.remove(_lastPreview);
    final available = _remaining.where(candidates.contains).toList();
    if (available.isEmpty) {
      _remaining
        ..clear()
        ..addAll(candidates..shuffle(_random));
    }
    final next = available.isNotEmpty
        ? available.first
        : (_remaining.isEmpty ? null : _remaining.last);
    if (next != null && _active.length < 2) {
      _remaining.remove(next);
      _lastPreview = next;
      setState(() => _active.add(next));
      // Allow 250 ms to pop in, then linger fully visible for three seconds.
      _hideTimers[next] = Timer(const Duration(milliseconds: 3250), () {
        _hideTimers.remove(next);
        if (mounted) setState(() => _active.remove(next));
      });
    }
    _nextTimer = Timer(
      Duration(milliseconds: 2100 + _random.nextInt(600)),
      _showNext,
    );
  }

  void _cancelTimers() {
    _nextTimer?.cancel();
    for (final timer in _hideTimers.values) {
      timer.cancel();
    }
    _hideTimers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < widget.children.length; index++)
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              key: _anchors[index],
              clipBehavior: Clip.none,
              children: [
                widget.children[index],
                PositionedDirectional(
                  top: -8,
                  end: 8,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: AnimatedSwitcher(
                        duration: _motionAllowed
                            ? const Duration(milliseconds: 250)
                            : Duration.zero,
                        reverseDuration: _motionAllowed
                            ? const Duration(milliseconds: 250)
                            : Duration.zero,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            alignment: Alignment.centerRight,
                            scale: animation.drive(Tween(begin: 0.85, end: 1.0)
                                .chain(CurveTween(curve: Curves.easeOutCubic))),
                            child: child,
                          ),
                        ),
                        child: _active.contains(index)
                            ? _TaskPreviewBubble(
                                key: ValueKey('profession_preview_$index'),
                                text: widget.previews[index],
                                maxWidth: math.max(0,
                                    math.min(300, constraints.maxWidth - 48)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}

class _TaskPreviewBubble extends StatelessWidget {
  final String text;
  final double maxWidth;

  const _TaskPreviewBubble(
      {required super.key, required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            colors.primary.withValues(alpha: 0.08), colors.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, height: 1.2, color: colors.onSurface),
      ),
    );
  }
}
