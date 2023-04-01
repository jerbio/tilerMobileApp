import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class PendingWidget extends StatelessWidget {
  Decoration decoration = TileStyles.defaultBackground;
  PendingWidget({backgroundDecoration}) {
    if (backgroundDecoration != null && backgroundDecoration is Decoration) {
      decoration = backgroundDecoration;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: this.decoration,
      child: Center(
          child: Stack(children: [
        Center(
            child: SizedBox(
          child: CircularProgressIndicator(),
          height: 200.0,
          width: 200.0,
        )),
        Center(
            child: Image.asset('assets/images/tiler_logo_black.png',
                fit: BoxFit.cover, scale: 7)),
      ])),
    );
  }
}
