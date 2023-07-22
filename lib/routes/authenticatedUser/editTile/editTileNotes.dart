import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditTileNote extends StatefulWidget {
  String tileNote;
  Function? onInputChange;
  bool isProcrastinate;
  bool isReadOnly = false;
  EditTileNote(
      {required this.tileNote,
      this.onInputChange,
      this.isProcrastinate = false,
      this.isReadOnly = false});

  String get note {
    return tileNote;
  }

  @override
  _EditTileNoteState createState() => _EditTileNoteState();
}

class _EditTileNoteState extends State<EditTileNote> {
  final Color textBackgroundColor = Colors.white;
  final Color textBorderColor = TileStyles.primaryColorLightHSL.toColor();
  late TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (this.widget.onInputChange != null) {
      _controller.text = this.widget.tileNote;
      _controller.addListener(() {
        this.widget.tileNote = _controller.text;
        this.widget.onInputChange!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String procrastinateText =
        AppLocalizations.of(context)!.procrastinateBlockOut;
    return FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
          width: 380,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: TextFormField(
            minLines: 5,
            maxLines: 10,
            textInputAction: Platform.isAndroid
                ? TextInputAction.newline
                : TextInputAction.done,
            initialValue:
                this.widget.isProcrastinate ? procrastinateText : null,
            enabled:
                !(this.widget.isProcrastinate) && !(this.widget.isReadOnly),
            controller: this.widget.isProcrastinate ? null : _controller,
            style: TextStyle(
                fontSize: 20,
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(31, 31, 31, 1)),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.noteEllipsis,
              filled: true,
              isDense: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
                borderSide: BorderSide(color: textBorderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
                borderSide: BorderSide(
                  color: textBorderColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ));
  }
}
