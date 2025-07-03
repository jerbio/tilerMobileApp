import 'package:flutter/material.dart';


class AnimatedLine extends StatefulWidget {
  Duration duration;
  Color color;
  bool reverse = false;
  AnimatedLine(this.duration, this.color, {this.reverse = false});
  @override
  State<StatefulWidget> createState() => _AnimatedLineState();
}

class _AnimatedLineState extends State<AnimatedLine>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    var controller =
        AnimationController(duration: this.widget.duration, vsync: this);

    animation = Tween(begin: 1.0, end: 0.0).animate(controller)
      ..addListener(() {
        setState(() {
          _progress = animation.value;
        });
      });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: LinePainter(_progress, this.widget.color,
            reverse: this.widget.reverse));
  }
}

class LinePainter extends CustomPainter {
  late Paint _paint;
  late Color color;
  bool reverse = false;
  double _progress;

  LinePainter(this._progress, this.color, {this.reverse = false}) {
    _paint = Paint()
      ..color = this.color
      ..strokeWidth = 8.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // if (!reverse) {
    //   canvas.drawLine(Offset(0.0, 0.0),
    //       Offset(0 * _progress, size.height - size.height * _progress), _paint);
    //   return;
    // }
    // canvas.drawLine(
    //     Offset(0 * _progress, size.height - (size.height * _progress)),
    //     Offset(0.0, 0.0),
    //     _paint);

    canvas.drawLine(Offset(0.0, 0.0),
        Offset(0 * _progress, size.height - size.height * _progress), _paint);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate._progress != _progress;
  }
}
