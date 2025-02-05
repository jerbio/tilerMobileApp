import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/styles.dart';
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
    const double iconSize = 12;
    const double fontSize = 12;
    const TextStyle textStyle = TextStyle(
        fontSize: fontSize,
        fontFamily: TileStyles.rubikFontName,
        overflow: TextOverflow.ellipsis,
        color: const Color.fromRGBO(40, 40, 40, 1));

    return Card(
      surfaceTintColor: Colors.transparent,
      color: TileStyles.defaultWidgetBackgroundColor,
      elevation: TileStyles.defaultCardElevation,
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
                          fontSize: 12, fontFamily: TileStyles.rubikFontName)),
                  SizedBox(height: 8),
                  if (widget.tileShareCluster?.endTimeInMs != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
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
                    TileStyles.multiShareIcon,
                    color: TileStyles.primaryColor,
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
                      color: TileStyles.primaryColor,
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
