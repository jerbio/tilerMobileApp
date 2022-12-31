import 'package:flutter/material.dart';
import 'package:swipe_deck/swipe_deck.dart';
import 'package:tiler_app/util.dart';

class EmptyDayTile extends StatefulWidget {
  @override
  EmptyDayTileState createState() => EmptyDayTileState();
}

class EmptyDayTileState extends State<EmptyDayTile> {
  @override
  Widget build(BuildContext context) {
    var images = [
      'assets/images/regenerativeArt/pictimely_we_are_not_Gods_064eb660-6cca-44bb-b75b-12da4555ef30.png',
      'assets/images/regenerativeArt/pictimely_build_a_pillow_fort_d77bbb89-2e18-4e70-a547-a78d9b9eee83.png',
      'assets/images/regenerativeArt/pictimely_cute_photo_of_woman_and_man_working_together_looking__49c9615b-3c01-4914-aa4c-be6aaeba779d.png',
      'assets/images/regenerativeArt/pictimely_Do_some_origami_43731a0a-393c-434e-ab3e-1c5bb10143b2.png',
      'assets/images/regenerativeArt/pictimely_feeling_idle_excited_at_a_dance_party_2efb40a6-7b44-49d9-a038-50f197bb506a.png',
      'assets/images/regenerativeArt/pictimely_Have_a_movie_marathon_e574a17c-3c4a-439b-8c94-7ae1771495f4.png',
      'assets/images/regenerativeArt/pictimely_image_of_someone_creating_or_making_something_or_a_ma_2a50defa-b851-4671-9cfd-41eaa5636130.png',
      'assets/images/regenerativeArt/pictimely_Make_a_bird_feeder_28f817f4-f638-4730-bf9c-4273f6a6ef33.png',
      'assets/images/regenerativeArt/pictimely_Reorganize_your_closets_abdd967a-9592-444b-b772-0326fa46d8ea.png',
    ];

    return Container(
      height: (MediaQuery.of(context).size.height) - 200,
      padding: EdgeInsets.all(20),
      child: SwipeDeck(
        startIndex: 3,
        emptyIndicator: Container(
          child: Center(
            child: Text("Nothing Here"),
          ),
        ),
        cardSpreadInDegrees: 5, // Change the Spread of Background Cards
        onSwipeLeft: () {
          print("USER SWIPED LEFT -> GOING TO NEXT WIDGET");
        },
        onSwipeRight: () {
          print("USER SWIPED RIGHT -> GOING TO PREVIOUS WIDGET");
        },
        onChange: (index) {
          print(images[index]);
        },
        widgets: images
            .getRandomize()
            .map((e) => GestureDetector(
                  onTap: () {
                    print(e);
                  },
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        const Radius.circular(8.0),
                      ),
                      child: Image.asset(
                        e,
                        fit: BoxFit.cover,
                      )),
                ))
            .toList(),
      ),
    );

    // return Container(
    //   height: (MediaQuery.of(context).size.height),
    //   child: Text('We got nothing'),
    // );
  }
}
