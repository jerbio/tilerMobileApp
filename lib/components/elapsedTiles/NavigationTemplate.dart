import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/styles.dart';

class NavigationTemplateWidget extends StatefulWidget {
  Function? onCancel;
  Function? onProceed;
  Function? loadingFinished;
  Function? isProceedAllowed;
  Widget? bottomWidget;
  Widget? pendingWidget;
  bool hideButtons = false;

  Widget? child;
  PreferredSizeWidget? appBar;

  NavigationTemplateWidget(
      {this.onCancel,
      this.onProceed,
      this.child,
      this.isProceedAllowed,
      this.appBar,
      this.bottomWidget,
      this.hideButtons = false});

  @override
  NavigationTemplateWidgetState createState() =>
      NavigationTemplateWidgetState();
}

class NavigationTemplateWidgetState extends State<NavigationTemplateWidget> {
  bool showLoading = false;

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  Widget build(BuildContext context) {
    bool isKeyboardShown = _keyboardIsVisible();
    Widget? proceedButton;
    Widget cancelButton = Align(
      alignment: Alignment.bottomRight,
      child: Container(
        alignment: Alignment.centerRight,
        // margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        width: TileStyles.proceedAndCancelButtonWidth,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                TileStyles.primaryColor,
                HSLColor.fromColor(TileStyles.primaryColor)
                    .withLightness(
                        HSLColor.fromColor(TileStyles.primaryColor).lightness +
                            0.3)
                    .toColor()
              ],
            )),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            foregroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
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
              this.widget.onCancel!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
                HSLColor.fromColor(TileStyles.primaryColor)
                    .withLightness(
                        HSLColor.fromColor(TileStyles.primaryColor).lightness +
                            0.3)
                    .toColor(),
                TileStyles.primaryColor,
              ],
            )),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            foregroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
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
              Navigator.pop(context, proceedResult);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    if (!this.widget.hideButtons && !showLoading) {
      bottomButtons.add(cancelButton);
      if (proceedButton != null) {
        bottomButtons.add(proceedButton);
      } else {
        bottomButtons.add(SizedBox.fromSize(
          size: Size.fromWidth(TileStyles.proceedAndCancelButtonWidth),
        ));
      }

      if (this.widget.bottomWidget != null) {
        bottomButtons.insert(
            1,
            Container(
                padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                width: MediaQuery.of(context).size.width -
                    2 * TileStyles.proceedAndCancelButtonWidth,
                child: this.widget.bottomWidget!));
      }

      if (isKeyboardShown) {
        bottomButtons = [];
      }
    }

    List<Widget> stackWidgets = [];
    if (this.widget.child != null) {
      stackWidgets.add(this.widget.child!);
    }

    if (showLoading) {
      Widget blurWidget = Container(
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
          ))));
      stackWidgets.add(blurWidget);
      stackWidgets.add(this.widget.pendingWidget ??
          PendingWidget(
            imageAsset: TileStyles.evaluatingScheduleAsset,
          ));
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
