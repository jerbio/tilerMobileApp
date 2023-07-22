import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

class EditTileName extends StatefulWidget {
  String tileName;
  Function? onInputChange;
  bool isReadOnly = false;
  bool isProcrastinate;
  EditTileName(
      {required this.tileName,
      this.onInputChange,
      this.isProcrastinate = false,
      this.isReadOnly = false});

  String get name {
    return tileName;
  }

  @override
  _EditTileNameState createState() => _EditTileNameState();
}

class _EditTileNameState extends State<EditTileName> {
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.primaryColorLightHSL.toColor();
  late TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (this.widget.onInputChange != null) {
      _controller.text = this.widget.tileName;
      _controller.addListener(() {
        this.widget.tileName = _controller.text;
        this.widget.onInputChange!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String procrastinateText =
        AppLocalizations.of(context)!.procrastinateBlockOut;
    return FractionallySizedBox(
        widthFactor: 1,
        child: Container(
          width: 380,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: TextFormField(
            minLines: 1,
            maxLines: 5,
            textInputAction: Platform.isAndroid
                ? TextInputAction.newline
                : TextInputAction.done,
            initialValue:
                this.widget.isProcrastinate ? procrastinateText : null,
            enabled:
                !(this.widget.isProcrastinate) && !(this.widget.isReadOnly),
            controller: this.widget.isProcrastinate ? null : _controller,
            style: TextStyle(
                fontSize: 22.5,
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(31, 31, 31, 1)),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.tileName,
              filled: true,
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
              fillColor: Colors.transparent,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textBorderColor, width: 1)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: textBorderColor.withLightness(0.8), width: 1)),
            ),
          ),
        ));
  }
}
