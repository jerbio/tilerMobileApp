import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/tileUI/newTileUIPreview.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class EmptyDayTile extends StatefulWidget {
  final DateTime? deadline;
  final int dayIndex;
  EmptyDayTile({this.deadline, required this.dayIndex});
  @override
  EmptyDayTileState createState() => EmptyDayTileState();
}

class EmptyDayTileState extends State<EmptyDayTile> {
  late List<AutoTile> autoTiles;
  late int emptyDayIndex;
  @override
  void initState() {
    Map<int, List<AutoTile>> autoTilesByDuration =
        Utility.adHocAutoTilesByDuration;
    emptyDayIndex = this.widget.dayIndex ??
        Utility.getDayIndex(this.widget.deadline ?? Utility.currentTime());
    int daySeed = emptyDayIndex;
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
      if (eachAutoTile.categoryId != null &&
          !categoryIds.containsKey(eachAutoTile.categoryId)) {
        autoTiles.add(eachAutoTile);
        categoryIds[eachAutoTile.categoryId!] = eachAutoTile;
      }
    }
    super.initState();
    this.disableTileListCarousel();
  }

  void disableTileListCarousel() {
    if (this.mounted) {
      context
          .read<TileListCarouselBloc>()
          .add(DisableCarouselScrollEvent(dayIndex: this.widget.dayIndex));
    }
  }

  void enableTileListCarousel() {
    if (this.mounted) {
      context
          .read<TileListCarouselBloc>()
          .add(EnableCarouselScrollEvent(isImmediate: true));
    }
  }

  void dateTap(int dayIndex) {
    int updatedDayIndex = dayIndex;
    DateTime newDate = Utility.getTimeFromIndex(updatedDayIndex).dayDate;
    DateTime currentDate = Utility.getTimeFromIndex(this.emptyDayIndex).dayDate;
    this.enableTileListCarousel();
    if (currentDate.millisecondsSinceEpoch != newDate.millisecondsSinceEpoch) {
      this.context.read<UiDateManagerBloc>().add(DateChangeEvent(
          previousSelectedDate: currentDate, selectedDate: newDate));
    }
  }

  Widget buttonClickButton(int dayIndex) {
    return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (this.emptyDayIndex != 0) {
            dateTap(dayIndex);
          }
        },
        onTap: () {
          if (this.emptyDayIndex != 0) {
            dateTap(dayIndex);
          }
        },
        child: Container(
          alignment: Alignment.center,
          height: (MediaQuery.of(context).size.height),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                color: TileStyles.primaryColor,
              ),
              dayIndex > this.emptyDayIndex
                  ? Icon(
                      Icons.arrow_right_outlined,
                      color: TileStyles.primaryColor,
                    )
                  : Icon(Icons.arrow_left_outlined,
                      color: TileStyles.primaryColor),
              Text(
                DateFormat('d MMM').format(Utility.getTimeFromIndex(dayIndex)),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: TileStyles.rubikFontName,
                    color: TileStyles.primaryColor),
              )
            ],
          ),
          width: 40,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buttonClickButton(this.emptyDayIndex - 1),
        Container(
          height: (MediaQuery.of(context).size.height) * 0.80,
          width: (MediaQuery.of(context).size.width) * 0.78,
          padding: EdgeInsets.all(15),
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
                            arguments: newTileParams);
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
                                style: TextStyle(
                                    fontSize: 45, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      )),
                ),
              ),
              AppinioSwiper(
                cards: autoTiles
                    .where((autoTile) => autoTile.image != null)
                    .map((autoTile) {
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
                                  autoTile.image!,
                                  fit: BoxFit.cover,
                                ))),
                        FractionallySizedBox(
                          alignment: FractionalOffset.center,
                          widthFactor: 1,
                          child: Container(
                            height: 125,
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
                                Flexible(
                                    child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 10, 20, 0),
                                        child: Text(
                                          autoTile.description ?? "",
                                          style: TileStyles
                                              .fullScreenTextFieldStyle,
                                        ))),
                                Flexible(
                                    child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 10, 20, 10),
                                        child: Text(
                                          autoTile.isLastCard
                                              ? '   '
                                              : (autoTile.duration?.toHuman ??
                                                  ''),
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              fontWeight: FontWeight.w500),
                                        ))),
                                Flexible(
                                    child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 20, 0),
                                        child: Text(
                                          autoTile.isLastCard
                                              ? '   '
                                              : '(' +
                                                  AppLocalizations.of(context)!
                                                      .swipeRightToTileIt +
                                                  ')',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              fontWeight: FontWeight.w500),
                                        )))
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
                    AnalysticsSignal.send('AUTO_TILE_ADD', additionalInfo: {
                      'description': autoTile.description,
                      'duration': autoTile.duration?.inMilliseconds ?? -1
                    });
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddTile(
                                preTile: autoTile,
                                autoDeadline: this.widget.deadline)));
                  }
                },
              )
            ],
          ),
        ),
        buttonClickButton(this.emptyDayIndex + 1),
      ],
    );
  }

  @override
  void dispose() {
    // this.enableTileListCarousel();
    super.dispose();
  }
}
