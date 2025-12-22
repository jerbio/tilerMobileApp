import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

class EditTileName extends StatefulWidget {
  String tileName;
  Function? onInputChange;
  bool isReadOnly = false;
  bool isProcrastinate;
  TextStyle? textStyle;
  double? width;
  EditTileName(
      {required this.tileName,
      this.onInputChange,
      this.isProcrastinate = false,
      this.isReadOnly = false,
      this.textStyle,
      this.width});

  String get name {
    return tileName;
  }

  @override
  _EditTileNameState createState() => _EditTileNameState();
}

class _EditTileNameState extends State<EditTileName> {
  late TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (this.widget.onInputChange != null) {
      _controller.text = this.widget.tileName;
      _controller.addListener(() {
        this.widget.tileName = _controller.text;
        this.widget.onInputChange!(_controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String procrastinateText =
        AppLocalizations.of(context)!.procrastinateBlockOut;
    return Container(
      width: this.widget.width ?? 380,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: TextFormField(
        minLines: 1,
        maxLines: 5,
        textInputAction:
            Platform.isAndroid ? TextInputAction.newline : TextInputAction.done,
        initialValue: this.widget.isProcrastinate ? procrastinateText : null,
        enabled: !(this.widget.isProcrastinate) && !(this.widget.isReadOnly),
        controller: this.widget.isProcrastinate ? null : _controller,
        style: this.widget.textStyle ??
            TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 22.5,
              fontWeight: FontWeight.w500,
            ),
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
              borderSide:
                  BorderSide(color: colorScheme.primaryContainer, width: 1)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: colorScheme.primaryContainer.withLightness(0.8),
                  width: 1)),
        ),
      ),
    );
  }
}
