import 'package:flutter/material.dart';

/// A sliver list that turns changes to [items] into animations (redesign T11,
/// no snapping): cards that leave shrink and fade out, cards that arrive grow
/// and fade in from zero height, so nothing jumps. Cards are identified by
/// [idOf]; a card that stays takes its fresh data (and position) without
/// animating.
class TileShareAnimatedCardList<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) idOf;
  final Widget Function(T item) itemBuilder;

  const TileShareAnimatedCardList({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
  });

  @override
  State<TileShareAnimatedCardList<T>> createState() =>
      _TileShareAnimatedCardListState<T>();
}

class _TileShareAnimatedCardListState<T>
    extends State<TileShareAnimatedCardList<T>> {
  static const Duration _inDuration = Duration(milliseconds: 300);
  static const Duration _outDuration = Duration(milliseconds: 220);

  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  late List<T> _shown;

  @override
  void initState() {
    super.initState();
    _shown = List<T>.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant TileShareAnimatedCardList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.items);
  }

  void _sync(List<T> target) {
    final Set<String> targetIds = target.map(widget.idOf).toSet();
    final SliverAnimatedListState? list = _listKey.currentState;

    // Leaving cards animate out (from the end, so indexes stay valid).
    for (int i = _shown.length - 1; i >= 0; i--) {
      if (targetIds.contains(widget.idOf(_shown[i]))) continue;
      final T gone = _shown.removeAt(i);
      list?.removeItem(
        i,
        (context, animation) => _transition(animation, widget.itemBuilder(gone)),
        duration: _outDuration,
      );
    }

    // Arriving cards animate in at their place.
    final Set<String> presentIds = _shown.map(widget.idOf).toSet();
    for (int j = 0; j < target.length; j++) {
      final String id = widget.idOf(target[j]);
      if (presentIds.contains(id)) continue;
      final int at = j < _shown.length ? j : _shown.length;
      _shown.insert(at, target[j]);
      presentIds.add(id);
      list?.insertItem(at, duration: _inDuration);
    }

    // Cards that stayed take their fresh data (and order) without animating.
    _shown = List<T>.of(target);
  }

  Widget _transition(Animation<double> animation, Widget child) {
    final Animation<double> curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) => _transition(
        animation,
        widget.itemBuilder(_shown[index]),
      ),
    );
  }
}
