import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/nextTileSuggestionWidget.dart';

class NextTileSuggestionCarouselWidget extends StatefulWidget {
  List<NextTileSuggestion> nextTileSuggestions;
  NextTileSuggestionCarouselWidget({required this.nextTileSuggestions});

  @override
  State<StatefulWidget> createState() => _NextTileSuggestionCarouselState();
}

class _NextTileSuggestionCarouselState
    extends State<NextTileSuggestionCarouselWidget> {
  List<NextTileSuggestion>? nextTileSuggestions;

  @override
  void initState() {
    super.initState();
    nextTileSuggestions = this.widget.nextTileSuggestions;
  }

  @override
  Widget build(BuildContext context) {
    Widget retValue = SizedBox.shrink();
    if (this.nextTileSuggestions != null &&
        this.nextTileSuggestions!.length > 0) {
      List<NextTileSuggestion> orderedTileSuggestions =
          this.nextTileSuggestions!.toList();
      orderedTileSuggestions.sort((tileA, tileB) {
        return tileA.name!.compareTo(tileB.name!);
      });

      retValue = Container(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            aspectRatio: 2.0,
            enlargeCenterPage: true,
          ),
          items: orderedTileSuggestions
              .map((e) => Expanded(
                  child: NextTileSuggestionWidget(nextTileSuggestion: e)))
              .toList(),
        ),
      );
    }

    return retValue;
  }
}
