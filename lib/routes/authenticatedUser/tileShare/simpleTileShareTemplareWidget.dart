import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/contactListView.dart';
import 'package:tiler_app/routes/authenticatedUser/userListView.dart';
import 'package:tiler_app/styles.dart';

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
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  @override
  void initState() {
    super.initState();
    isReadOnly = this.widget.isReadOnly ?? true;
  }

  @override
  Widget build(BuildContext context) {
    String creatorInfo = widget.tileShareTemplate?.creator?.username ??
        widget.tileShareTemplate?.creator?.email ??
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
                  Text('${widget.tileShareTemplate?.name ?? ""}',
                      style: TextStyle(
                          fontSize: 24, fontFamily: TileStyles.rubikFontName)),
                  SizedBox(height: 8),
                  if (widget.tileShareTemplate?.start != null)
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
                                  widget.tileShareTemplate!.end!)),
                          style: TileStyles.defaultTextStyle,
                        )
                      ],
                    )
                  else
                    SizedBox.shrink(),
                  SizedBox(height: 8),
                  if (widget.tileShareTemplate != null &&
                      widget.tileShareTemplate?.designatedUsers != null &&
                      widget.tileShareTemplate!.designatedUsers!.isNotEmpty)
                    UserListViewWidget(
                      contacts: widget.tileShareTemplate!.designatedUsers!
                          .map((e) => e.toContact())
                          .where((element) => element != null)
                          .map<Contact>((e) => e!)
                          .toList(),
                      // isReadOnly: true,
                    )
                  else
                    SizedBox.shrink()
                ],
              ),
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
