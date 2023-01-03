import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tiler_app/styles.dart';

class CancelAndProceedTemplateWidget extends StatefulWidget {
  Function? onCancel;
  Function? onProceed;
  Function? loadingFinished;
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
  bool showLoading = false;

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  Widget build(BuildContext context) {
    bool isKeyboardShown = _keyboardIsVisible();
    Widget? proceedButton;
    Widget cancelButton = Container(
      width: TileStyles.proceedAndCancelButtonWidth,
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
    List<Widget> bottomButtons = [];
    if ((this.widget.isProceedAllowed != null &&
            this.widget.isProceedAllowed!()) ||
        this.widget.onProceed != null) {
      proceedButton = Container(
        width: TileStyles.proceedAndCancelButtonWidth,
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
          onPressed: () async {
            if (this.widget.onProceed != null) {
              var proceedResult = this.widget.onProceed!();
              if (proceedResult is Future) {
                setState(() {
                  showLoading = true;
                });
                proceedResult.then((value) {
                  setState(() {
                    showLoading = false;
                  });
                  Navigator.pop(context);
                }).whenComplete(() {
                  setState(() {
                    showLoading = false;
                  });
                });
                return;
              }
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    bottomButtons.add(cancelButton);
    if (proceedButton != null) {
      bottomButtons.add(proceedButton);
    }
    if (isKeyboardShown) {
      bottomButtons = [];
    }

    if (showLoading) {
      bottomButtons = [
        Container(
          width: (MediaQuery.of(context).size.width),
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              HSLColor.fromAHSL(1, 191, 1, 0.46).toColor(),
              HSLColor.fromAHSL(1, 198, 1, 0.33).toColor()
            ],
          )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitFoldingCube(
                color: Colors.white,
                size: 20.0,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Text(AppLocalizations.of(context)!.loading,
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        )
      ];
    }

    List<Widget> stackWidgets = [];
    if (this.widget.child != null) {
      stackWidgets.add(this.widget.child!);
    }

    if (showLoading) {
      stackWidgets.add(Container(
          width: (MediaQuery.of(context).size.width),
          height: (MediaQuery.of(context).size.height),
          child: new Center(
              child: new ClipRect(
                  child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: new Container(
              width: (MediaQuery.of(context).size.width),
              height: (MediaQuery.of(context).size.height),
              decoration: new BoxDecoration(
                  color: Colors.grey.shade200.withOpacity(0.5)),
            ),
          )))));
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
      resizeToAvoidBottomInset: false,
      appBar: this.widget.appBar,
      body: SafeArea(
        child: contentAndButton,
      ),
    );
  }
}
