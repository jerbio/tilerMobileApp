import 'dart:async';
import 'package:flutter/material.dart';

class AutoSwitchingWidget extends StatefulWidget {
  final Duration duration;
  final List<Widget> children;

  const AutoSwitchingWidget({
    Key? key,
    required this.duration,
    required this.children,
  }) : super(key: key);

  @override
  _AutoSwitchingWidgetState createState() => _AutoSwitchingWidgetState();
}

class _AutoSwitchingWidgetState extends State<AutoSwitchingWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.children.length > 1) {
      _timer = Timer.periodic(widget.duration, (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.children.length;
        });
      });
    }
  }

  @override
  void didUpdateWidget(AutoSwitchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration ||
        oldWidget.children.length != widget.children.length) {
      _timer?.cancel();
      if (widget.children.length > 1) {
        _timer = Timer.periodic(widget.duration, (timer) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.children.length;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return SizedBox.shrink();
    return widget.children[_currentIndex];
    // return AnimatedSwitcher(
    //     duration: Duration(milliseconds: 100),
    //     child: widget.children[_currentIndex]);
  }
}
