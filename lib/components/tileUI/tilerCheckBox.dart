import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

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
      return TileStyles.primaryColor;
    }
    return TileStyles.disabledColor;
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
    bool checkStatus = isChecked;
    if (this.widget.isChecked != null) {
      checkStatus = this.widget.isChecked!;
    }
    Widget checkBox = Container(
        decoration: BoxDecoration(
          color: TileStyles.disabledColor,
          border: Border.all(
            color: Colors.white,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
        width: 38,
        height: 38,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(1, 0, 0, 1),
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Stack(
                  children: [Icon(Icons.check, color: Colors.white, size: 35)]),
            ),
            Transform.scale(
                scale: 2.0,
                child: Checkbox(
                  checkColor: Colors.white,
                  fillColor: MaterialStateProperty.resolveWith(getColor),
                  value: checkStatus,
                  splashRadius: 20,
                  shape: CircleBorder(
                      side:
                          BorderSide(width: 5, color: TileStyles.primaryColor)),
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
      margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Text(this.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: checkStatus
                  ? TileStyles.enabledTextColor
                  : TileStyles.disabledTextColor)),
    );
    return new GestureDetector(
        onTap: onTap,
        child: Container(
          child: Row(children: [checkBox, textBox]),
        ));
  }
}
