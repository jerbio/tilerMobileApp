import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TileShareSimpleWidget extends StatefulWidget {
  final TileShareClusterData? tileShareCluster;
  final bool? isReadOnly;
  final Function? onDelete;

  TileShareSimpleWidget(
      {required this.tileShareCluster, this.isReadOnly, this.onDelete});

  @override
  _TileShareState createState() => _TileShareState();
}

class _TileShareState extends State<TileShareSimpleWidget> {
  late bool isReadOnly = false;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  @override
  void initState() {
    super.initState();
    isReadOnly = this.widget.isReadOnly ?? true;
  }

  String getTileShareContactString() {
    String retValue = "";
    if (this.widget.tileShareCluster != null) {
      List<Contact> contacts =
          (this.widget.tileShareCluster!.contacts ?? <Contact>[]).toList();

      retValue = (contacts.map((e) => e.displayedIdentifier ?? ''))
          .join(AppLocalizations.of(context)!.commaDelimiter);
      if (this.widget.tileShareCluster!.isMoreContact == true) {
        if (contacts.isNotEmpty) {
          retValue += AppLocalizations.of(context)!.commaDelimiter +
              Utility.ellipsisText;
        }
      }
    }
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme= theme.colorScheme;
    const double iconSize = 12;
    const double fontSize = 12;
    const TextStyle textStyle = TextStyle(
        fontFamily: TileTextStyles.rubikFontName,
        fontSize: fontSize,
        overflow: TextOverflow.ellipsis,);

    return Card(
      surfaceTintColor: Colors.transparent,
      elevation: TileDimensions.defaultCardElevation,
      margin: EdgeInsets.all(5),
      child: Padding(
          padding: EdgeInsets.all(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.tileShareCluster?.name ?? ""}',
                      style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          fontSize: 12,
                      )
                  ),
                  SizedBox(height: 8),
                  if (widget.tileShareCluster?.endTimeInMs != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.onSurface,
                          size: iconSize,
                        ),
                        rowSpacer,
                        Expanded(
                          child: Text(
                            maxLines: 1,
                            MaterialLocalizations.of(context).formatFullDate(
                                DateTime.fromMillisecondsSinceEpoch(
                                    widget.tileShareCluster!.endTimeInMs!)),
                            style: textStyle,
                          ),
                        )
                      ],
                    )
                  else
                    SizedBox.shrink(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_2_outlined,
                        color: colorScheme.onSurface,
                        size: iconSize,
                      ),
                      rowSpacer,
                      Expanded(
                          child: Text(
                              maxLines: 1,
                              getTileShareContactString(),
                              style: textStyle))
                    ],
                  ),
                ],
              ),
              if (this.widget.tileShareCluster?.isMultiTilette == true)
                Positioned(
                  child: Icon(
                    Icons.bento_outlined,
                    color: colorScheme.primary,
                  ),
                  right: 0,
                )
              else
                SizedBox.shrink(),
              if (isReadOnly == false)
                Positioned(
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(
                      Icons.delete,
                      color: colorScheme.primary,
                    ),
                    onPressed: () {
                      if (this.widget.onDelete != null) {
                        this.widget.onDelete!();
                      }
                    },
                    alignment: Alignment.bottomRight,
                  ),
                  right: 0,
                  bottom: 0,
                )
              else
                SizedBox.shrink(),
            ],
          )),
    );
  }
}
