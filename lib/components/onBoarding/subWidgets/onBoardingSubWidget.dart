import 'package:flutter/material.dart';

class OnboardingSubWidget extends StatelessWidget {
  final String? title;
  final String? questionText;
  final String? questionSubText;
  final Widget? child;
  const OnboardingSubWidget({this.questionText, this.child, this.title, this.questionSubText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if(title!=null)
        Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600
              ),
          ),
        ),
        Text(
          questionText!,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w400,
          ),
          textAlign: title!=null?TextAlign.center:TextAlign.left,
        ),
        if(questionSubText!=null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            questionSubText!,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20.0),
        child!,
      ],
    );
  }
}
