import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/styles.dart';

class PendingWidget extends StatelessWidget {
  Decoration decoration = TileStyles.defaultBackgroundDecoration;
  String? imageAsset;
  double? height;
  double? width;
  bool blurBackGround = false;
  PendingWidget(
      {backgroundDecoration, this.imageAsset, this.blurBackGround = true}) {
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

    Widget centerRenderWidget = Center(
        child: Stack(children: [
      if (this.imageAsset == null)
        Center(
            child: SizedBox(
          child: Center(child: CircularProgressIndicator()),
          height: 200.0,
          width: 200.0,
        )),
      Center(child: imageAsset),
    ]));

    Widget backgroundBlurWithCenterWidget = Container(
        width: (MediaQuery.of(context).size.width),
        height: (MediaQuery.of(context).size.height),
        child: new Center(
            child: new ClipRect(
                child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: new Container(
            width: (MediaQuery.of(context).size.width),
            height: (MediaQuery.of(context).size.height),
            child: centerRenderWidget,
            decoration: new BoxDecoration(
                color: Colors.grey.shade200.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
          ),
        ))));

    Widget pendingRender = centerRenderWidget;
    if (this.blurBackGround) {
      pendingRender = backgroundBlurWithCenterWidget;
    }

    return Container(
      decoration: this.decoration,
      child: pendingRender,
    );
  }
}
