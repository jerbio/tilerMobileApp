import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tileThemeExtension.dart';
import 'package:tiler_app/util.dart';

class TilerCheckBox extends StatefulWidget {
  bool? isChecked;
  String text;
  Function? onChange;
  TilerCheckBox({this.isChecked, required this.text, this.onChange, Key? key})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => TilerCheckBoxState();
}

class TilerCheckBoxState extends State<TilerCheckBox> {
  bool isChecked = false;
  String text = '';
  @override
  void initState() {
    super.initState();
    if (this.widget.isChecked != null) {
      isChecked = this.widget.isChecked!;
    } else {
      this.widget.isChecked = isChecked;
    }
    text = this.widget.text;
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
      MaterialState.selected
    };

    if (states.any(interactiveStates.contains)) {
      return Theme.of(context).colorScheme.primary;
    }
    return Colors.transparent;
  }

  onTap() {
    bool currentChecked = isChecked;
    if (this.widget.isChecked != null) {
      currentChecked = this.widget.isChecked!;
    }
    setState(() {
      this.widget.isChecked = !currentChecked;
      isChecked = this.widget.isChecked!;
    });
    if (this.widget.onChange != null) {
      this.widget.onChange!(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    bool checkStatus = isChecked;
    if (this.widget.isChecked != null) {
      checkStatus = this.widget.isChecked!;
    }
    Widget checkBox = Container(
        margin: EdgeInsets.fromLTRB(20, 0, 2, 0),
        width: 24,
        height: 24,
        child: Stack(
          children: [
            Transform.scale(
                scale:  1,
                child: Checkbox(
                  checkColor: Colors.transparent,
                  fillColor: MaterialStateProperty.resolveWith(getColor),
                  value: checkStatus,
                  splashRadius: 15,
                  shape: CircleBorder(
                      side:
                          BorderSide(width: 2, color: colorScheme.primary,
                          ),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value!;
                    });
                    if (this.widget.onChange != null) {
                      this.widget.onChange!(this);
                    }
                  },
                ))
          ],
        ));

    Widget textBox = Container(
      margin: EdgeInsets.fromLTRB(12, 0, 0, 0),
      child: Text(this.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize:15,
              fontWeight: FontWeight.w600,
              color: checkStatus
                  ? colorScheme.onSurface
                  :colorScheme.onPrimary.withLightness(0.7),
              ),
          ),
      );
    return new GestureDetector(
        onTap: onTap,
        child: Container(
          child: Row(children: [checkBox, textBox]),
        ));
  }
}
