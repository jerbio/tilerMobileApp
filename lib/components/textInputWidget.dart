import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_box_shadows.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_spacing.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class TextInputWidget extends StatefulWidget {
  final Function? onTextChange;
  final String? placeHolder;
  final String? value;
  TextInputWidget({this.onTextChange, this.placeHolder, this.value, Key? key})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
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
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    Widget tileNameContainer = Container(
        height: TileDimensions.inputHeight,
        decoration: BoxDecoration(
          borderRadius: TileDimensions.inputFieldBorderRadius,
          boxShadow: [
            TileBoxShadows.inputFieldBoxShadow(tileThemeExtension.shadowHigh)
          ],
        ),
        child: TextField(
          controller: textFieldController,
          style: TextStyle(
              fontSize: TileDimensions.inputFontSize,
              fontFamily: TileTextStyles.rubikFontName,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: this.widget.placeHolder,
            hintStyle: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w100),
            filled: true,
            isDense: true,
            contentPadding: TileSpacing.inputFieldPadding,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: TileDimensions.inputFieldBorderRadius,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: TileDimensions.inputFieldBorderRadius,
              borderSide: BorderSide(color: colorScheme.onInverseSurface, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: TileDimensions.inputFieldBorderRadius,
              borderSide: BorderSide(
                color: colorScheme.onInverseSurface,
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
