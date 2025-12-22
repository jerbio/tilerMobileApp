import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/designatedUserCircle.dart';

import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class TileShareTemplateSimpleWidget extends StatefulWidget {
  final TileShareTemplate? tileShareTemplate;
  final bool? isReadOnly;
  final Function? onDelete;

  TileShareTemplateSimpleWidget(
      {required this.tileShareTemplate, this.isReadOnly, this.onDelete});

  @override
  _TileShareTemplateState createState() => _TileShareTemplateState();
}

class _TileShareTemplateState extends State<TileShareTemplateSimpleWidget> {
  late bool isReadOnly = false;
  late ThemeData theme;
  late ColorScheme colorScheme;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  final int maxContactItems = 5;
  @override
  void initState() {
    super.initState();
    isReadOnly = this.widget.isReadOnly ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  Widget generateUserCircles(List<DesignatedUser> designatedUsers) {
    List<Widget> allCircleWidgets = [];
    for (int i = 0; i < maxContactItems && i < designatedUsers.length; i++) {
      allCircleWidgets.add(DesignatedUserCircle(
        designatedUser: designatedUsers[i],
        color: TileColors
            .randomDefaultHues[i % TileColors.randomDefaultHues.length],
      ));
    }
    return Row(
      children: [
        ...allCircleWidgets,
        if (designatedUsers.length > maxContactItems)
          Text(
            AppLocalizations.of(context)!.numberOfMoreUsers(
                (designatedUsers.length - maxContactItems).toString()),
            style: TileTextStyles.defaultText,
          )
        else
          SizedBox.shrink()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fontSize = 12;
    const double iconSize = 12;
    const TextStyle textStyle = TextStyle(
      fontFamily: TileTextStyles.rubikFontName,
      fontSize: fontSize,
    );
    return Card(
      surfaceTintColor: Colors.transparent,
      elevation: TileDimensions.defaultCardElevation,
      margin: EdgeInsets.all(10),
      child: Padding(
          padding: EdgeInsets.all(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.tileShareTemplate?.name ?? ""}',
                      style: textStyle),
                  SizedBox(height: 8),
                  if (widget.tileShareTemplate?.end != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.onSurface,
                          size: iconSize,
                        ),
                        rowSpacer,
                        Text(
                          MaterialLocalizations.of(context).formatFullDate(
                              DateTime.fromMillisecondsSinceEpoch(
                                  widget.tileShareTemplate!.end!)),
                          style: textStyle,
                        )
                      ],
                    )
                  else
                    SizedBox.shrink(),
                  SizedBox(height: 8),
                  if (widget.tileShareTemplate != null &&
                      widget.tileShareTemplate?.designatedUsers != null &&
                      widget.tileShareTemplate!.designatedUsers!.isNotEmpty)
                    generateUserCircles(
                        widget.tileShareTemplate!.designatedUsers!),
                ],
              ),
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
