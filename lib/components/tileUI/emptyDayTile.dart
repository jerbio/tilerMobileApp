import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/tileUI/newTileUIPreview.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class EmptyDayTile extends StatefulWidget {
  DateTime? deadline;
  int? dayIndex;
  EmptyDayTile({this.deadline, this.dayIndex});
  @override
  EmptyDayTileState createState() => EmptyDayTileState();
}

class EmptyDayTileState extends State<EmptyDayTile> {
  late List<AutoTile> autoTiles;
  @override
  void initState() {
    Map<int, List<AutoTile>> autoTilesByDuration =
        Utility.adHocAutoTilesByDuration;

    int daySeed = this.widget.dayIndex ??
        Utility.getDayIndex(this.widget.deadline ?? Utility.currentTime());
    int durationInMs =
        autoTilesByDuration.keys.toList().getRandomize(seed: daySeed).first;
    List<AutoTile> autoTilesWithDuplicateCategory =
        autoTilesByDuration[durationInMs]!
            .getRandomize(seed: daySeed)
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (MediaQuery.of(context).size.height) * 0.80,
      width: (MediaQuery.of(context).size.width) * 0.80,
      padding: EdgeInsets.all(20),
      child: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    TileStyles.primaryColorHSL.toColor().withOpacity(0.75),
                    TileStyles.primaryColorHSL
                        .withLightness(
                            TileStyles.primaryColorHSL.lightness + .2)
                        .toColor()
                        .withOpacity(0.75),
                  ],
                ),
              ),
              height: (MediaQuery.of(context).size.height) * 0.90,
              width: (MediaQuery.of(context).size.width) * 0.90,
              child: GestureDetector(
                  onTap: () {
                    Map<String, dynamic> newTileParams = {'newTile': null};

                    Navigator.pushNamed(context, '/AddTile',
                            arguments: newTileParams)
                        .whenComplete(() {
                      var newSubEventParams = newTileParams['newTile'];
                      if (newSubEventParams != null) {
                        print('Newly created tile');
                        print(newTileParams);
                        var subEvent = newSubEventParams;
                        int redColor = subEvent.colorRed == null
                            ? 125
                            : subEvent.colorRed!;
                        int blueColor = subEvent.colorBlue == null
                            ? 125
                            : subEvent.colorBlue!;
                        int greenColor = subEvent.colorGreen == null
                            ? 125
                            : subEvent.colorGreen!;
                        double opacity = subEvent.colorOpacity == null
                            ? 1
                            : subEvent.colorOpacity!;
                        var nameColor = Color.fromRGBO(
                            redColor, greenColor, blueColor, opacity);

                        var hslColor = HSLColor.fromColor(nameColor);
                        Color bgroundColor = hslColor
                            .withLightness(hslColor.lightness)
                            .toColor()
                            .withOpacity(0.7);
                        showModalBottomSheet<void>(
                          context: context,
                          constraints: BoxConstraints(
                            maxWidth: 400,
                          ),
                          builder: (BuildContext context) {
                            var future = new Future.delayed(const Duration(
                                milliseconds: Constants.autoHideInMs));
                            future.asStream().listen((input) {
                              Navigator.pop(context);
                            });
                            return Container(
                              padding: const EdgeInsets.all(20),
                              height: 250,
                              width: 300,
                              decoration: BoxDecoration(
                                color: bgroundColor,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    NewTileSheet(subEvent: subEvent),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }).catchError((errorThrown) {
                      print('we have error');
                      print(errorThrown);
                      return errorThrown;
                    });
                  },
                  child: Container(
                    height: (MediaQuery.of(context).size.height) * 0.55,
                    width: (MediaQuery.of(context).size.width) * 0.55,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: TileStyles.primaryContrastColor,
                          size: 60,
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          child: Text(
                            AppLocalizations.of(context)!.addTile,
                            style: TextStyle(fontSize: 45, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  )),
            ),
          ),
          AppinioSwiper(
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
                                      style:
                                          TileStyles.fullScreenTextFieldStyle,
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
          )
        ],
      ),
    );
  }
}
