import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class EmptyDayTile extends StatefulWidget {
  DateTime? deadline;
  EmptyDayTile({this.deadline});
  @override
  EmptyDayTileState createState() => EmptyDayTileState();
}

class EmptyDayTileState extends State<EmptyDayTile> {
  late List<AutoTile> autoTiles;
  @override
  void initState() {
    Map<int, List<AutoTile>> autoTilesByDuration =
        Utility.adHocAutoTilesByDuration;

    int durationInMs = autoTilesByDuration.keys.toList().getRandomize().first;
    List<AutoTile> autoTilesWithDuplicateCategory =
        autoTilesByDuration[durationInMs]!
            .getRandomize()
            .cast<AutoTile>()
            .toList();
    Map<String, AutoTile> categoryIds = {};
    autoTiles = <AutoTile>[];
    for (var eachAutoTile in autoTilesWithDuplicateCategory) {
      if (!categoryIds.containsKey(eachAutoTile.categoryId)) {
        autoTiles.add(eachAutoTile);
        categoryIds[eachAutoTile.categoryId] = eachAutoTile;
      }
    }
    autoTiles.insert(0, Utility.lastCards.randomEntry);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (MediaQuery.of(context).size.height) - 200,
      padding: EdgeInsets.all(20),
      child: AppinioSwiper(
        cards: autoTiles.map((autoTile) {
          return Container(
            child: Column(
              children: [
                Expanded(
                    child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: Image.asset(
                          autoTile.image,
                          fit: BoxFit.cover,
                        ))),
                FractionallySizedBox(
                  alignment: FractionalOffset.center,
                  widthFactor: 1,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black87.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 1,
                          blurStyle: BlurStyle.normal,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
                                child: Text(
                                  autoTile.description,
                                  style: TileStyles.fullScreenTextFieldStyle,
                                ))),
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                child: Text(
                                  autoTile.isLastCard
                                      ? '   '
                                      : autoTile.duration.toHuman +
                                          ' (' +
                                          AppLocalizations.of(context)!
                                              .swipeRightToTileIt +
                                          ')',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontFamily: TileStyles.rubikFontName,
                                      fontWeight: FontWeight.w500),
                                ))),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }).toList(),
        onSwipe: (index, direction) {
          AutoTile autoTile = autoTiles[index];
          if (autoTile.isLastCard) {
            return;
          }
          if (AppinioSwiperDirection.right == direction) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddTile(
                        autoTile: autoTile,
                        autoDeadline: this.widget.deadline)));
          }
        },
      ),
    );
  }
}
