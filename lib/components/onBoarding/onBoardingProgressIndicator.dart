import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';

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
                    ? TileColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: TileColors.primaryColor,
                  width: 2,
                ),
                boxShadow: stepIndex <= currentPage
                    ? [
                        BoxShadow(
                          color: TileColors.primaryColor.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null),
            child: Center(
              child: Text(
                (stepIndex + 1).toString(),
                style: TextStyle(
                  color: stepIndex <= currentPage
                      ? Colors.white
                      : TileColors.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: DottedLine(
              direction: Axis.horizontal,
              lineThickness: 3.0,
              dashLength: 3.0,
              lineLength: 65,
              dashGapLength: 8.0,
              dashRadius: 4,
              dashColor: TileColors.primaryColor,
            ),
          );
        }
      }),
    );
  }
}
