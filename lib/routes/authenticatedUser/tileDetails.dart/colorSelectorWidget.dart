import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

class ColorSelectorWidget extends StatefulWidget {
  final Color color;
  final TextStyle? textStyle;
  final Function? onColorUpdate;
  ColorSelectorWidget(
      {required this.color, this.textStyle, this.onColorUpdate});

  @override
  _ColorSelectorWidget createState() => _ColorSelectorWidget();
}

class _ColorSelectorWidget extends State<ColorSelectorWidget> {
  late Color _color;
  @override
  void initState() {
    super.initState();
    this._color = this.widget.color;
  }

  Widget renderColorPicker() {
    return InkWell(
      onTap: () {
        Color? colorHolder = _color;
        Map<String, dynamic> colorParams = {'color': colorHolder};

        Navigator.pushNamed(context, '/PickColor', arguments: colorParams)
            .whenComplete(() {
          Color? populatedColor = colorParams['color'] as Color?;
          if (populatedColor != null) {
            setState(() {
              _color = populatedColor;
            });
            if (this.widget.onColorUpdate != null) {
              this.widget.onColorUpdate!(_color);
            }
          }
        });
      },
      child: Container(
          padding: EdgeInsets.all(10),
          width: MediaQuery.sizeOf(context).width *
              TileDimensions.tileWidthRatio *
              TileDimensions.tileWidthRatio *
              TileDimensions.tileWidthRatio,
          color: this._color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return renderColorPicker();
  }
}
