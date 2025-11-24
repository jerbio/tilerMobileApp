import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';


class OnBoardingProgressIndicator extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  OnBoardingProgressIndicator({
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate( 7, (index) {
        if (index % 2 == 0) {
          int stepIndex = index ~/ 2;
           if( totalPages-currentPage>4) {
            stepIndex =currentPage+stepIndex ;
            }else{
               int backOffset = 4 - stepIndex;
               int adjustment = totalPages - currentPage - backOffset;
               stepIndex= currentPage + adjustment;
             }
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stepIndex <= currentPage
                    ? colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: colorScheme.primary,
                  width: 2,
                ),
                boxShadow: stepIndex <= currentPage
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
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
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
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
              dashColor: colorScheme.primary,
            ),
          );
        }
      }),
    );
  }
}
