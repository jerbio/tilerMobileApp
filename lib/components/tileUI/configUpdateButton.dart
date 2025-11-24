import 'dart:ffi';
import 'dart:ui' as dartUI;
import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class ConfigUpdateButton extends StatefulWidget {
  final Icon? prefixIcon;
  final String text;
  final Function? onPress;
  final Decoration? decoration;
  final Bool? isPopulated;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final ButtonStyle? buttonStyle;
  final EdgeInsets? iconPadding;
  final BoxConstraints? constraints;


  ConfigUpdateButton(
      {required this.text,
      this.decoration,
      this.onPress,
      this.prefixIcon,
      this.isPopulated,
      this.textStyle,
      this.buttonStyle,
      this.constraints,
      this.iconPadding = const EdgeInsets.fromLTRB(5, 2, 5, 5),
      this.padding = const EdgeInsets.fromLTRB(5, 10, 10, 7),
      this.textColor});

  @override
  ConfigUpdateButtonState createState() => ConfigUpdateButtonState();
}

class ConfigUpdateButtonState extends State<ConfigUpdateButton> {
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }
  Widget build(BuildContext context) {
    List<Widget> childWidgets = [];
    if (this.widget.prefixIcon != null) {
      childWidgets.add(Container(
          margin: this.widget.iconPadding, child: this.widget.prefixIcon!));
    }
    String textButtonString = this.widget.text;
    Widget textButton = TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: dartUI.Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: this.widget.textStyle ??
            TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
        foregroundColor: this.widget.textColor??colorScheme.onSurface,
      ),
      onPressed: () async {
        if (this.widget.onPress != null) {
          await this.widget.onPress!();
        }
      },
      child: Text(
        textButtonString,
        overflow: TextOverflow.ellipsis,
        style: this.widget.textStyle ??
            TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
            ),
      ),
    );

    childWidgets.add(textButton);

    Widget retValue = new ElevatedButton(
      style: this.widget.buttonStyle ?? TileButtonStyles.stripped(),
      onPressed: () {
        if (this.widget.onPress != null) {
          this.widget.onPress!();
        }
      },
      child: Container(
        constraints: this.widget.constraints ??
            BoxConstraints(
                minWidth: (MediaQuery.of(context).size.width * 0.30)),
        decoration: this.widget.decoration,
        padding: this.widget.padding,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: childWidgets,
        ),
      ),
    );

    return retValue;
  }
}
