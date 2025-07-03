import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/theme/tile_decorations.dart';

class PendingWidget extends StatelessWidget {
  Decoration decoration = TileDecorations.defaultBackground;
  String? imageAsset;
  double? height;
  double? width;
  double? blurSigma;
  bool blurBackGround = false;
  PendingWidget(
      {backgroundDecoration, this.imageAsset, this.blurBackGround = true,this.blurSigma}) {
    if (backgroundDecoration != null && backgroundDecoration is Decoration) {
      decoration = backgroundDecoration;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          if(this.imageAsset==null)
          Center(
              child: SizedBox(
                child: CircularProgressIndicator(
                  color: colorScheme.tertiary,
                ),
                height: 200.0,
                width: 200.0,
              )),
          Center(
              child: imageAsset
          ),
        ],
      ),
    );

    Widget backgroundBlurWithCenterWidget = Container(
        width: (MediaQuery.of(context).size.width),
        height: (MediaQuery.of(context).size.height),
        child: new Center(
            child: new ClipRect(
                child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: blurSigma??2.0, sigmaY: blurSigma??2.0),
          child: new Container(
            width: (MediaQuery.of(context).size.width),
            height: (MediaQuery.of(context).size.height),
            child: centerRenderWidget,
            decoration: new BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
          ),
        )
            )
        )
    );

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
