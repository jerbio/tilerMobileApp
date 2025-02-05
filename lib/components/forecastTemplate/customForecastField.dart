import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../styles.dart';

class CustomForecastField extends StatelessWidget {
  const CustomForecastField({
    super.key,
    required this.leadingIconPath,
    required this.textButtonString,
    required this.height,
    required this.width,
  });

  final String leadingIconPath;
  final String textButtonString;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: height / (height / 18),
      ),
      width: width,
      height: height / (height / 44),
      decoration: BoxDecoration(
        color: Color(0xFF1F1F1F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          height / (height / 6),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: height / (height / 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(leadingIconPath),
            SizedBox(
              width: height / (height / 15),
            ),
            Text(
              textButtonString,
              style: TextStyle(
                fontFamily: TileStyles.rubikFontName,
                fontSize: height / (height / 15),
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F1F1F),
              ),
            )
          ],
        ),
      ),
    );
  }
}
