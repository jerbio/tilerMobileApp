import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

class TileShareSimpleWidget extends StatefulWidget {
  final TileShareClusterData? tileShareCluster;

  TileShareSimpleWidget({required this.tileShareCluster});

  @override
  _TileShareState createState() => _TileShareState();
}

class _TileShareState extends State<TileShareSimpleWidget> {
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  @override
  Widget build(BuildContext context) {
    String creatorInfo = widget.tileShareCluster?.creator?.username ??
        widget.tileShareCluster?.creator?.email ??
        "";

    return Card(
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Padding(
          padding: EdgeInsets.all(15),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.tileShareCluster?.name ?? ""}',
                      style: TextStyle(
                          fontSize: 24, fontFamily: TileStyles.rubikFontName)),
                  SizedBox(height: 8),
                  if (widget.tileShareCluster?.endTimeInMs != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                        ),
                        rowSpacer,
                        Text(
                          MaterialLocalizations.of(context).formatFullDate(
                              DateTime.fromMillisecondsSinceEpoch(
                                  widget.tileShareCluster!.endTimeInMs!)),
                          style: TileStyles.defaultTextStyle,
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
                        size: 16,
                      ),
                      rowSpacer,
                      Text(
                          (creatorInfo.contains('@') ? '' : '@') +
                              '${creatorInfo}',
                          style: TileStyles.defaultTextStyle)
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
            ],
          )),
    );
  }
}
