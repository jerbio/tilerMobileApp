import 'package:flutter/material.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/previewChart.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PreviewWidget extends StatefulWidget {
  final PreviewSummary? previewSummary;
  final List<TilerEvent> subEvents;
  final Timeline? timeline;
  PreviewWidget({this.previewSummary, required this.subEvents, this.timeline});
  @override
  State<StatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends State<PreviewWidget> {
  late Timeline _timeline;
  @override
  void initState() {
    super.initState();
    _timeline = this.widget.timeline ?? Utility.restOfTodayTimeline();
  }

  PreviewSummary? get _previewSummary {
    return this.widget.previewSummary;
  }

  String _generateMessageText() {
    Timeline dayTimeline = Utility.restOfTodayTimeline();
    List<TilerEvent> blockedTiles = [];
    List<TilerEvent> tiles = [];
    List<TilerEvent> tileShare = [];
    if (this.widget.subEvents.isNotEmpty) {
      this.widget.subEvents.forEach((eachSubEvent) {
        if (eachSubEvent.isInterfering(dayTimeline)) {
          if (eachSubEvent.isRigid == true) {
            blockedTiles.add(eachSubEvent);
          } else {
            tiles.add(eachSubEvent);
          }
          if (eachSubEvent.tileShareDesignatedId
              .isNot_NullEmptyOrWhiteSpace()) {
            tileShare.add(eachSubEvent);
          }
        }
      });
    }

    if (blockedTiles.isNotEmpty && tiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveCountBlocksCountTilesAndCountTileShares(
              blockedTiles.length.toString(),
              tiles.length.toString(),
              tileShare.length.toString());
    } else if (blockedTiles.isNotEmpty && tiles.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountBlocksAndCountTiles(
          blockedTiles.length.toString(), tiles.length.toString());
    } else if (blockedTiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountBlocksAndCountTileShares(
          blockedTiles.length.toString(), tileShare.length.toString());
    } else if (tiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountTilesAndCountTileShares(
          tiles.length.toString(), tileShare.length.toString());
    } else if (blockedTiles.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXBlocks(blockedTiles.length.toString());
    } else if (tiles.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXTiles(tiles.length.toString());
    } else if (tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXTileShares(tileShare.length.toString());
    }

    return AppLocalizations.of(context)!.noTilesPreview;
  }

  Widget renderMessage() {
    const TextStyle previewMessageStyle = TextStyle(
        fontSize: 15,
        color: TileStyles.accentContrastColor,
        fontFamily: TileStyles.rubikFontName,
        fontWeight: FontWeight.w500);
    return Container(
        child: Text(
      _generateMessageText(),
      style: previewMessageStyle,
    ));
  }

  Widget renderEmpty() {
    return SizedBox.shrink();
  }

  Widget renderText() {
    return SizedBox.shrink();
  }

  Widget renderCharts() {
    if (_previewSummary != null) {
      List<Widget> carouselDayRibbonBatch = [];
      if (_previewSummary!.classification != null &&
          _previewSummary!.classification!.sections != null &&
          _previewSummary!.classification!.sections!.isNotEmpty) {
        carouselDayRibbonBatch.add(PreviewChart(
            previewGrouping: _previewSummary!.classification!.sections!,
            icon: Icon(
              Icons.message,
              color: TileStyles.accentContrastColor,
            ),
            timeline: this._timeline,
            description: Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                AppLocalizations.of(context)!.previewClassificationName,
                style: TextStyle(
                    fontSize: 15,
                    color: TileStyles.accentContrastColor,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w500),
              ),
            )));
      }

      if (_previewSummary!.tag != null &&
          _previewSummary!.tag!.sections != null &&
          _previewSummary!.tag!.sections!.isNotEmpty) {
        carouselDayRibbonBatch.add(PreviewChart(
          previewGrouping: _previewSummary!.tag!.sections!,
          icon: Icon(
            Icons.discount_sharp,
            color: TileStyles.accentContrastColor,
          ),
          timeline: this._timeline,
          description: Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              AppLocalizations.of(context)!.previewTagName,
              style: TextStyle(
                  fontSize: 15,
                  color: TileStyles.accentContrastColor,
                  fontFamily: TileStyles.rubikFontName,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ));
      }

      if (_previewSummary!.location != null &&
          _previewSummary!.location!.sections != null &&
          _previewSummary!.location!.sections!.isNotEmpty) {
        carouselDayRibbonBatch.add(PreviewChart(
          previewGrouping: _previewSummary!.location!.sections!,
          icon: Icon(
            Icons.location_on_sharp,
            color: TileStyles.accentContrastColor,
          ),
          timeline: this._timeline,
          description: Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              AppLocalizations.of(context)!.previewLocationName,
              style: TextStyle(
                  fontSize: 15,
                  color: TileStyles.accentContrastColor,
                  fontFamily: TileStyles.rubikFontName,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ));
      }

      if (carouselDayRibbonBatch.isNotEmpty) {
        return CarouselSlider(
          items: carouselDayRibbonBatch,
          options: CarouselOptions(
              viewportFraction: 1,
              autoPlayInterval: Duration(seconds: 10),
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              scrollDirection: Axis.horizontal,
              autoPlay: true),
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget renderStats() {
    return SizedBox.shrink();
  }

  Widget renderPreview() {
    return Container(child: NewTileShareSheetWidget());
  }

  Widget renderModal() {
    return Container(child: NewTileShareSheetWidget());
  }

  @override
  Widget build(BuildContext context) {
    Color colorSection = Colors.transparent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        renderCharts(),
        Container(
            margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
            alignment: Alignment.center,
            width: MediaQuery.sizeOf(context).width,
            padding: EdgeInsets.fromLTRB(20, 50, 20, 50),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.5,
                center: Alignment.bottomRight,
                colors: <Color>[
                  colorSection.withLightness(0.65),
                  colorSection.withLightness(0.675),
                  colorSection.withLightness(0.70),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                ],
              ),
            ),
            child: renderMessage()),
      ],
    );
  }
}
