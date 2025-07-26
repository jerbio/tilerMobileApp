import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
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
  final AppinioSwiperController controller = AppinioSwiperController();
  late ThemeData theme;
  late ColorScheme colorScheme;
  late  TileThemeExtension tileThemeExtension;
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
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
                color: colorScheme.primary,
              ),
              dayIndex > this.emptyDayIndex
                  ? Icon(
                      Icons.arrow_right_outlined,
                      color:colorScheme.primary,
                    )
                  : Icon(Icons.arrow_left_outlined,
                      color: colorScheme.primary),
              Text(
                DateFormat('d MMM').format(Utility.getTimeFromIndex(dayIndex)),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    color: colorScheme.primary
                ),
              )
            ],
          ),
          width: 40,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var cardData =
        autoTiles.where((autoTile) => autoTile.image != null).toList();
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
                    border: Border.all(color: colorScheme.onInverseSurface, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.75),
                        colorScheme.primary
                            .withLightness(
                            HSLColor.fromColor(colorScheme.primary).lightness + .2)
                            .withValues(alpha: 0.75),
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
                              color: colorScheme.onPrimary,
                              size: 60,
                            ),
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Text(
                                AppLocalizations.of(context)!.addTile,
                                style: TextStyle(
                                    fontSize: 45,
                                    color: colorScheme.onPrimary
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                  ),
                ),
              ),
              AppinioSwiper(
                controller: controller,
                cardCount: cardData.length,
                onSwipeEnd: (previousIndex, index, activity) {
                  index = index - 1;
                  if (index == -1 || index >= cardData.length) {
                    return;
                  }

                  AutoTile autoTile = autoTiles[index];
                  if (autoTile.isLastCard) {
                    return;
                  }
                  switch (activity) {
                    case Swipe():
                      if (activity.direction == AxisDirection.right) {
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

                      break;
                    case Unswipe():
                      break;
                    case CancelSwipe():
                      break;
                    case DrivenActivity():
                      break;
                  }
                },
                swipeOptions: SwipeOptions.only(left: true, right: true),
                cardBuilder: (BuildContext context, int index) {
                  AutoTile autoTile = autoTiles[index];

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
                                  bottomRight: Radius.circular(10)
                              ),
                              color: colorScheme.surfaceContainerLowest,
                              boxShadow: [
                                BoxShadow(
                                  color:  tileThemeExtension.shadowEmptyTile.withValues(alpha: 0.2),
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
                                          style: TileTextStyles.fullScreenTextFieldStyle
                                        ),
                                    ),
                                ),
                                Flexible(
                                    child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 10, 20, 10),
                                        child: Text(
                                          autoTile.isLastCard
                                              ? '   '
                                              : (autoTile.duration?.toHuman ??
                                                  ''),
                                          style:TextStyle(
                                              color: tileThemeExtension.onSurfaceVariantSecondary,
                                              fontSize: 16,
                                              fontFamily:
                                              TileTextStyles.rubikFontName,
                                              fontWeight: FontWeight.w500
                                          ),
                                        )
                                    )
                                ),
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
                                              color: tileThemeExtension.onSurfaceVariantSecondary,
                                              fontSize: 16,
                                              fontFamily:
                                              TileTextStyles.rubikFontName,
                                              fontWeight: FontWeight.w500
                                          ),
                                        )
                                    )
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
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
    super.dispose();
  }
}
