import 'package:flutter/material.dart';

import '../../../styles.dart';

enum WidgetOrder { iconText, textIcon }

class onBoardingBottomButton extends StatelessWidget {
  final IconData? icon;
  final Function()? press;

  const onBoardingBottomButton({
    super.key,
    required this.press,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TileStyles.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ]),
      child: Container(
        width: 60.0,
        height: 60.0,
        child: IconButton(
            iconSize: 32.0,
            icon: Icon(icon, color: Colors.white),
            onPressed: press),
      ),
    );
  }
}
