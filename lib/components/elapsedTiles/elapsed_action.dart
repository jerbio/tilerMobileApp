import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import '../../styles.dart';
//ey: not used
class ElapsedActionButton extends StatelessWidget {
  ElapsedActionButton(
      {super.key,
      required this.height,
      required this.iconData,
      required this.label});

  double height;
  IconData iconData;
  String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: height / (height / 35),
          width: height / (height / 35),
          decoration: BoxDecoration(
            color: Color(0xFFD9D9D9C2).withOpacity(0.76),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(iconData),
          ),
        ),
        SizedBox(
          height: height / (height / 5),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: height / (height / 10),
          ),
        )
      ],
    );
  }
}
