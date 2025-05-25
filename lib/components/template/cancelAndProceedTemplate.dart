import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class CancelAndProceedTemplateWidget extends StatefulWidget {
  Function? onCancel;
  Function? onProceed;
  Function? loadingFinished;
  Function? isProceedAllowed;
  Widget? bottomWidget;
  Widget? pendingWidget;
  bool hideButtons = false;
  String routeName;

  Widget? child;
  PreferredSizeWidget? appBar;

  CancelAndProceedTemplateWidget(
      {required this.routeName,
        this.onCancel,
        this.onProceed,
        this.child,
        this.isProceedAllowed,
        this.appBar,
        this.bottomWidget,
        this.hideButtons = false});

  @override
  CancelAndProceedTemplateWidgetState createState() =>
      CancelAndProceedTemplateWidgetState();
}

enum CancelAndProceedPathRoute { cancel, proceed }

class CancelAndProceedTemplateWidgetState
    extends State<CancelAndProceedTemplateWidget> {
  bool showLoading = false;
  final String cancelAndProceedMapKey = 'cancelAndProceedData';
  final String historyKey = 'history';
  final String exitRouteKey = 'exitRoute';

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  Map<String, dynamic>? _getCancelAndProceedData() {
    var routeParams = ModalRoute.of(context)?.settings.arguments as Map?;
    if (routeParams != null) {
      if (!routeParams.containsKey(cancelAndProceedMapKey) ||
          routeParams[cancelAndProceedMapKey] == null) {
        routeParams[cancelAndProceedMapKey] = <String, dynamic>{};
      }
      Map<String, dynamic> cancelAndProceedData =
      routeParams[cancelAndProceedMapKey];
      if (routeParams[cancelAndProceedMapKey] == null) {
        cancelAndProceedData = {};
        cancelAndProceedData[historyKey] = [];
        routeParams[cancelAndProceedMapKey] = cancelAndProceedData;
      }
      return cancelAndProceedData;
    }
    return null;
  }

  List? _getRouteHistory() {
    Map<String, dynamic>? cancelAndProceedData = _getCancelAndProceedData();
    if (cancelAndProceedData != null) {
      return cancelAndProceedData[historyKey];
    }
    return null;
  }

  Map<String, dynamic> _generateRouteInfo() {
    return {"routeName": this.widget.routeName};
  }

  void _setRouteAsProceed() {
    var routeHistory = this._getRouteHistory();
    if (routeHistory != null) {
      Map<String, dynamic> routeInfo = _generateRouteInfo();
      routeInfo[exitRouteKey] = CancelAndProceedPathRoute.proceed;
    }
  }

  void _setRouteAsCancelled() {
    var routeHistory = this._getRouteHistory();
    if (routeHistory != null) {
      Map<String, dynamic> routeInfo = _generateRouteInfo();
      routeInfo[exitRouteKey] = CancelAndProceedPathRoute.cancel;
    }
  }

  Widget build(BuildContext context) {
    double iconSize = 25;
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
            color: TileColors.primaryColor),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            foregroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent, // foreground
          ),
          child: Center(
              child: Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 60, 50),
                  child: Transform.rotate(
                      angle: math.pi / 4,
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        onPressed: null,
                      )))),
          onPressed: () async {
            _setRouteAsCancelled();
            if (this.widget.onCancel != null) {
              Navigator.pop(context);
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
            color: TileColors.primaryColor),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0.0,
              foregroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent, // foreground
              alignment: Alignment.topLeft),
          child: Container(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: null,
            ),
          ),
          onPressed: () async {
            _setRouteAsProceed();
            if (this.widget.onProceed != null) {
              var proceedResult = this.widget.onProceed!();
              if (proceedResult is Future) {
                setState(() {
                  showLoading = true;
                });
                return proceedResult.then((value) {
                  if (mounted) {
                    setState(() {
                      showLoading = false;
                    });
                  }
                  if (value != false) {
                    Navigator.pop(context);
                  }
                }).whenComplete(() {
                  setState(() {
                    showLoading = false;
                  });
                });
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
      backgroundColor: TileStyles.defaultBackgroundColor,
      appBar: this.widget.appBar,
      body: SafeArea(
        child: contentAndButton,
      ),
    );
  }
}
