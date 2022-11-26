import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CancelAndProceedTemplateWidget extends StatefulWidget {
  Function? onCancel;
  Function? onProceed;
  Function? isProceedAllowed;
  Widget? child;
  PreferredSizeWidget? appBar;

  CancelAndProceedTemplateWidget(
      {this.onCancel,
      this.onProceed,
      this.child,
      this.isProceedAllowed,
      this.appBar});

  @override
  CancelAndProceedTemplateWidgetState createState() =>
      CancelAndProceedTemplateWidgetState();
}

class CancelAndProceedTemplateWidgetState
    extends State<CancelAndProceedTemplateWidget> {
  Widget build(BuildContext context) {
    Widget? proceedButton;
    Widget cancelButton = Container(
      width: 60,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              HSLColor.fromAHSL(1, 198, 1, 0.33).toColor(),
              HSLColor.fromAHSL(1, 191, 1, 0.46).toColor()
            ],
          )),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0.0,
          primary: Colors.transparent,
          onPrimary: Colors.transparent,
          shadowColor: Colors.transparent, // foreground
        ),
        child: Center(
            child: Container(
          margin: EdgeInsets.fromLTRB(10, 0, 50, 50),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: null,
            ),
          ),
        )),
        onPressed: () {
          if (this.widget.onCancel != null) {
            Navigator.pop(context);
            this.widget.onCancel!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );

    if ((this.widget.isProceedAllowed != null &&
            this.widget.isProceedAllowed!()) ||
        this.widget.onProceed != null) {
      proceedButton = Container(
        width: 60,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                HSLColor.fromAHSL(1, 191, 1, 0.46).toColor(),
                HSLColor.fromAHSL(1, 198, 1, 0.33).toColor()
              ],
            )),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            primary: Colors.transparent,
            onPrimary: Colors.transparent,
            shadowColor: Colors.transparent, // foreground
          ),
          child: Center(
              child: Container(
            margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.white,
              ),
              onPressed: null,
            ),
          )),
          onPressed: () {
            if (this.widget.onProceed != null) {
              Navigator.pop(context);
              this.widget.onProceed!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    List<Widget> bottomButtons = [];
    bottomButtons.add(cancelButton);
    if (proceedButton != null) {
      bottomButtons.add(proceedButton);
    }

    List<Widget> stackWidgets = [];
    if (this.widget.child != null) {
      stackWidgets.add(this.widget.child!);
    }
    stackWidgets.add(Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
            height: 80,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: Row(
              children: bottomButtons,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ))));

    Widget contentAndButton = Stack(
      children: stackWidgets,
    );
    return Scaffold(
      appBar: this.widget.appBar,
      body: SafeArea(
        child: contentAndButton,
      ),
    );
  }
}
