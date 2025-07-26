import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

class TileThemeNew {
  TileThemeNew._();

  static const String evaluatingScheduleAsset =
      'assets/lottie/tiler-evaluating-card-swap.json';


  static Widget getShimmerPending(BuildContext context, Color highlightColor) {
    return Shimmer.fromColors(
      baseColor: Colors.transparent,
      highlightColor: highlightColor.withLightness(0.9),
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: ColoredBox(
          color:TileColors.shimmerBackground,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
        ),
      ),
    );
  }


  static AppBar CancelAndProceedAppBar(
      {required  String title}) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }


}