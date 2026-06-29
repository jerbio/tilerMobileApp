import 'package:flutter/material.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/previewChart.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/preview_day_digest.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/preview_sundial_card.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    super.initState();
    _timeline = this.widget.timeline ?? Utility.restOfTodayTimeline();
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
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
    TextStyle previewMessageStyle = TextStyle(
        fontSize: 15,
        fontFamily: TileTextStyles.rubikFontName,
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
    final List<Widget> carouselDayRibbonBatch = [
      // Slide 1: always-on sundial summary card.
      PreviewSundialCard(
        subEvents: this.widget.subEvents,
        timeline: this._timeline,
      ),
    ];

    if (_previewSummary != null) {
      if (_previewSummary!.classification != null &&
          _previewSummary!.classification!.sections != null &&
          _previewSummary!.classification!.sections!.isNotEmpty) {
        carouselDayRibbonBatch.add(PreviewChart(
            previewGrouping: _previewSummary!.classification!.sections!,
            icon: Icon(
              Icons.message,
              color: colorScheme.onSurface,
            ),
            timeline: this._timeline,
            header: Text(
              AppLocalizations.of(context)!.previewClassificationName,
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: TileTextStyles.rubikFontName,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface),
            )));
      }

      // The tag slide is intentionally omitted in v1 of the redesigned
      // preview carousel; tag grouping data still flows from the server
      // but is not surfaced here.

      if (_previewSummary!.location != null &&
          _previewSummary!.location!.sections != null &&
          _previewSummary!.location!.sections!.isNotEmpty) {
        carouselDayRibbonBatch.add(PreviewChart(
          previewGrouping: _previewSummary!.location!.sections!,
          icon: Icon(Icons.location_on_sharp, color: colorScheme.onSurface),
          timeline: this._timeline,
          header: Text(
            AppLocalizations.of(context)!.previewLocationName,
            style: TextStyle(
                fontSize: 18,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
        ));
      }
    }

    return CarouselSlider(
      items: carouselDayRibbonBatch,
      options: CarouselOptions(
          viewportFraction: 1,
          autoPlayInterval: Duration(seconds: 10),
          initialPage: 0,
          enableInfiniteScroll: false,
          reverse: false,
          scrollDirection: Axis.horizontal,
          // The taller PreviewChart slides (header ~30 + 20 gap + 220 ring
          // + padding ≈ 290) only exist when classification/location
          // sections are present. When the sundial is the lone slide it
          // only needs ~200 (arc 120 + label + chevron), so we avoid
          // reserving chart-sized dead space that would otherwise squeeze
          // the day-digest summary below it.
          height: carouselDayRibbonBatch.length > 1 ? 270 : 200,
          autoPlay: carouselDayRibbonBatch.length > 1),
    );
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        renderCharts(),
        Expanded(
          child: PreviewDayDigest(
            subEvents: this.widget.subEvents,
            timeline: this._timeline,
          ),
        ),
      ],
    );
  }
}
