import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';

import '../../styles.dart';

class OnBoardingProgressIndicator extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  OnBoardingProgressIndicator({
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages * 2 - 1, (index) {
        if (index % 2 == 0) {
          int stepIndex = index ~/ 2;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stepIndex <= currentPage
                  ? TileStyles.primaryColor
                  : Colors.transparent,
              border: Border.all(
                color: TileStyles.primaryColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                (stepIndex + 1).toString(),
                style: TextStyle(
                  color: stepIndex <= currentPage
                      ? Colors.white
                      : TileStyles.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: DottedLine(
              direction: Axis.horizontal,
              lineThickness: 6.0,
              dashLength: 6.0,
              lineLength: 65,
              dashGapLength: 4.0,
              dashRadius: 4,
              dashColor: TileStyles.primaryColor,
            ),
          );
        }
      }),
    );
  }
}
