import 'package:flutter/material.dart';

/// A column whose keyed [children] arrive and leave with an animation
/// (redesign T11, no snapping) - the in-page twin of
/// `TileShareAnimatedCardList`: a child that arrives grows and fades in from
/// zero height, a child that leaves shrinks and fades out where it was, so
/// the ones around it never jump. A child that stays (same key) takes its
/// fresh widget without animating. Every child needs a key.
class AnimatedKeyedColumn extends StatefulWidget {
  final List<Widget> children;

  const AnimatedKeyedColumn({super.key, required this.children});

  static const Duration inDuration = Duration(milliseconds: 300);
  static const Duration outDuration = Duration(milliseconds: 220);

  @override
  State<AnimatedKeyedColumn> createState() => _AnimatedKeyedColumnState();
}

class _Entry {
  final Key key;
  Widget child;
  final AnimationController controller;
  bool leaving = false;

  _Entry(this.key, this.child, this.controller);
}

class _AnimatedKeyedColumnState extends State<AnimatedKeyedColumn>
    with TickerProviderStateMixin {
  final List<_Entry> _entries = <_Entry>[];

  @override
  void initState() {
    super.initState();
    for (final Widget child in widget.children) {
      // What is there at first is simply shown.
      _entries.add(_Entry(_keyOf(child), child, _controller(1)));
    }
  }

  static Key _keyOf(Widget child) {
    assert(child.key != null, 'AnimatedKeyedColumn children need keys');
    return child.key!;
  }

  AnimationController _controller(double value) => AnimationController(
        vsync: this,
        duration: AnimatedKeyedColumn.inDuration,
        reverseDuration: AnimatedKeyedColumn.outDuration,
        value: value,
      );

  @override
  void didUpdateWidget(covariant AnimatedKeyedColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<Widget> next = widget.children;
    final Set<Key> nextKeys = next.map(_keyOf).toSet();
    final Map<Key, _Entry> byKey = {for (final _Entry e in _entries) e.key: e};
    final List<_Entry> merged = <_Entry>[];
    int old = 0;

    void flushLeaving() {
      // Children that left stay where they were while they animate out.
      while (old < _entries.length && !nextKeys.contains(_entries[old].key)) {
        _leave(_entries[old]);
        merged.add(_entries[old]);
        old++;
      }
    }

    for (final Widget child in next) {
      flushLeaving();
      final Key key = _keyOf(child);
      final _Entry? existing = byKey[key];
      if (existing != null) {
        existing.child = child;
        if (existing.leaving) {
          // Back before it finished leaving: it comes back.
          existing.leaving = false;
          existing.controller.forward();
        }
        merged.add(existing);
        if (old < _entries.length && identical(_entries[old], existing)) old++;
      } else {
        final _Entry entry = _Entry(key, child, _controller(0));
        entry.controller.forward();
        merged.add(entry);
      }
    }
    flushLeaving();
    // Anything not placed yet (moved past) is kept only if it is leaving.
    for (; old < _entries.length; old++) {
      final _Entry e = _entries[old];
      if (!merged.contains(e)) {
        _leave(e);
        merged.add(e);
      }
    }
    _entries
      ..clear()
      ..addAll(merged);
  }

  void _leave(_Entry entry) {
    if (entry.leaving) return;
    entry.leaving = true;
    entry.controller.reverse().whenComplete(() {
      if (!mounted || !entry.leaving) return;
      setState(() => _entries.remove(entry));
      entry.controller.dispose();
    });
  }

  @override
  void dispose() {
    for (final _Entry e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final _Entry e in _entries)
          KeyedSubtree(
            key: ValueKey<Key>(e.key),
            child: _Transition(animation: e.controller, child: e.child),
          ),
      ],
    );
  }
}

class _Transition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Transition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
