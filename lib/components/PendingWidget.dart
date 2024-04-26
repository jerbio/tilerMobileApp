import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/styles.dart';

class PendingWidget extends StatelessWidget {
  Decoration decoration = TileStyles.defaultBackground;
  String? imageAsset;
  double? height;
  double? width;
  PendingWidget({backgroundDecoration, this.imageAsset}) {
    if (backgroundDecoration != null && backgroundDecoration is Decoration) {
      decoration = backgroundDecoration;
    }
  }
  @override
  Widget build(BuildContext context) {
    Widget imageAsset = Image.asset(
      this.imageAsset ?? 'assets/images/tiler_logo_black.png',
      fit: BoxFit.cover,
      scale: 7,
      alignment: Alignment.center,
    );

    if (this.imageAsset != null && this.imageAsset!.contains('.json')) {
      imageAsset =
          Lottie.asset(this.imageAsset!, height: height ?? 200, width: width);
    }

    return Container(
      decoration: this.decoration,
      child: Center(
          child: Stack(children: [
        if (this.imageAsset == null)
          Center(
              child: SizedBox(
            child: Center(child: CircularProgressIndicator()),
            height: 200.0,
            width: 200.0,
          )),
        Center(child: imageAsset),
      ])),
    );
  }
}
