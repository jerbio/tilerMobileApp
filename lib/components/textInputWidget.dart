import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class TextInputWidget extends StatefulWidget {
  final Function? onTextChange;
  final String? placeHolder;
  final String? value;
  TextInputWidget({this.onTextChange, this.placeHolder, this.value});
  @override
  State<StatefulWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  String? value = null;
  late final TextEditingController textFieldController;
  @override
  void initState() {
    super.initState();
    textFieldController = TextEditingController(text: this.widget.value);
    if (this.widget.onTextChange != null) {
      textFieldController.addListener(() {
        if (textFieldController.value != value) {
          value = textFieldController.text;
          this.widget.onTextChange!(value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tileNameContainer = Container(
        height: TileStyles.inputHeight,
        decoration: BoxDecoration(
          borderRadius: TileStyles.inputFieldBorderRadius,
          boxShadow: [
            TileStyles.inputFieldBoxShadow,
          ],
        ),
        child: TextField(
          controller: textFieldController,
          style: TextStyle(
              fontSize: TileStyles.inputFontSize,
              fontFamily: TileStyles.rubikFontName,
              color: TileStyles.inputFieldTextColor,
              fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: this.widget.placeHolder,
            hintStyle: TextStyle(
                color: TileStyles.inputFieldTextColor,
                fontWeight: FontWeight.w100),
            filled: true,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(10, 15, 10, 15),
            fillColor: textBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                const Radius.circular(50.0),
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
                width: 1.5,
              ),
            ),
          ),
        ));
    return tileNameContainer;
  }

  @override
  void dispose() {
    super.dispose();
    textFieldController.dispose();
  }
}
