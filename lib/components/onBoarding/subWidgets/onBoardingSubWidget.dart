import 'package:flutter/material.dart';

class OnboardingSubWidget extends StatelessWidget {
  final String? questionText;
  final Widget? child;
  const OnboardingSubWidget({this.questionText, this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            questionText!,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        SizedBox(height: 20.0),
        child!,
      ],
    );
  }
}
