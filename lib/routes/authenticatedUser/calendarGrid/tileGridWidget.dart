// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';

import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TileGridWidget extends GridPositionableWidget {
  final TilerEvent tilerEvent;
  final double? tileGridHeight;
  BoxDecoration? decoration;
  final Function? onTap;
  TileGridWidget(
      {required this.tilerEvent,
      double? left,
      this.tileGridHeight,
      this.onTap,
      this.decoration,
      Duration durationPerUnitTime = GridPositionableWidget.durationPerHeight})
      : super(
            left: left,
            height: tileGridHeight ??
                GridPositionableWidget.defaultHeigtPerDuration,
            durationPerCell: durationPerUnitTime);

  @override
  TileGridWidgetState createState() => TileGridWidgetState();
}

class TileGridWidgetState extends GridPositionableState {
  late TilerEvent? tilerEvent;
  static final Duration minDuration = Duration(minutes: 20);
  late ThemeData theme;
  late ColorScheme colorScheme;
  @override
  void initState() {
    super.initState();
    if (this.widget is TileGridWidget) {
      tilerEvent = (this.widget as TileGridWidget).tilerEvent;
    }
    if (this.tilerEvent != null) {
      this.topPosition = this
          .evalTopPosition(TimeOfDay.fromDateTime(this.tilerEvent!.startTime));
    }
    this.widgetHeight = durationToHeight();
    if (this.widget is TileGridWidget) {
      this.widgetHeight =
          (this.widget as TileGridWidget).tileGridHeight ?? this.widgetHeight;
    }

    this.leftPosition = 80.0;
    this.widgetWidth = 270;
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    super.didChangeDependencies();
  }

  double durationToHeight() {
    Duration duration = minDuration;
    if (this.tilerEvent?.duration != null &&
        this.tilerEvent!.duration.inMilliseconds > duration.inMilliseconds) {
      duration = this.tilerEvent!.duration;
    }

    return (duration.inMilliseconds /
            this.widget.durationPerCell.inMilliseconds) *
        this.widget.height;
  }

  void onTapPreviewTile(TilerEvent tile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:  colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TileDimensions.borderRadius)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: PreviewDetailsTileWidget(tile),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (this.tilerEvent != null) {
      return Positioned(
        top: topPosition,
        left: leftPosition,
        child: Container(
          height: this.widgetHeight,
          width: widgetWidth,
          child: InkWell(
              onTap: () {
                onTapPreviewTile(tilerEvent!);
                if (this.widget is TileGridWidget) {
                  if ((this.widget as TileGridWidget).onTap != null) {
                    (this.widget as TileGridWidget).onTap!(
                        tilerEvent: this.tilerEvent);
                  }
                }
              },
              child: _TilerEventInnerGridWidget(tilerEvent: tilerEvent!)),
        ),
      );
    }
    if (constant.isDebug) {
      return Container(
        color: colorScheme.onError,
        child: Text("failed to render tiler grid widget"),
      );
    }
    return SizedBox.shrink();
  }
}

class _TilerEventInnerGridWidget extends StatelessWidget {
  final TilerEvent tilerEvent;
  final Decoration? decoration;

  _TilerEventInnerGridWidget({required this.tilerEvent, this.decoration});

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;

    EdgeInsets gridPadding = EdgeInsets.all(10);
    if (this.tilerEvent.duration.inMilliseconds <=
        TileGridWidgetState.minDuration.inMilliseconds) {
      gridPadding = EdgeInsets.fromLTRB(10, 5, 0, 0);
    }
    Color color = Color.fromRGBO(tilerEvent.colorRed ?? 255,
        tilerEvent.colorGreen ?? 255, tilerEvent.colorGreen ?? 255, 1);
    String name = this.tilerEvent.name ?? "--no--name";
    Decoration uiDecoration = this.decoration ??
        BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: tileThemeExtension.shadowBase.withValues(alpha:0.1),
              spreadRadius: 0.5,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        );
    if (tilerEvent.isWhatIf == true) {
      color = Utility.randomColor;
      name = AppLocalizations.of(context)!.foreCastTile;
      if (this.decoration == null) {
        uiDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surfaceContainerLow,
          border: Border.all(
            color: colorScheme.primary,
            width: 1,
          ),
        );
      }
    }
    return Container(
        decoration: uiDecoration,
        padding: gridPadding,
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: new TextStyle(
            fontSize: 13.0,
            fontFamily: TileTextStyles.rubikFontName,
            color:  colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ));
  }
}
