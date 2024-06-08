import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/styles.dart';
import '../../constants.dart' as Constants;

class SearchWidget extends StatefulWidget {
  Function? onChanged;
  Function? onInputCompletion;
  TextField? textField;
  bool renderBelowTextfield;
  BoxDecoration? resultBoxDecoration;
  EdgeInsetsGeometry? resultMargin;

  SearchWidget(
      {this.onChanged,
      this.textField,
      this.onInputCompletion,
      this.renderBelowTextfield = true,
      this.resultBoxDecoration,
      this.resultMargin,
      Key? key})
      : super(key: key);

  @override
  SearchWidgetState createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  List<TextEditingController> createdControllers = [];
  Widget? resultViewContainer;
  String searchedText = '';
  bool showResponseContainer = false;
  final Container blankResult = Container();
  Future<void> onInputChangeDefault() async {
    Function collapseResultContainer = (seletedObject) {
      setState(() {
        showResponseContainer = false;
      });
    };
    Function? onInputChangedAsync = this.widget.onChanged;
    if (this.widget.textField?.controller?.text != searchedText) {
      if (onInputChangedAsync != null &&
          this.widget.textField != null &&
          this.widget.textField!.controller != null) {
        if (this.widget.textField != null &&
            this.widget.textField!.controller != null) {
          setState(() {
            searchedText = this.widget.textField!.controller!.text;
            showResponseContainer = true;
          });
        }
        BoxDecoration resultContainerDecoration = BoxDecoration(
          color: TileStyles.primaryColorLightHSL.toColor(),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.white70.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        );

        if (this.widget.textField!.controller!.text.length >
            Constants.autoCompleteMinCharLength) {
          // this whole if block is a hack relying on the autoCompleteMinCharLength
          setState(() {
            resultViewContainer = GestureDetector(
                onTap: () {
                  setState(() {
                    showResponseContainer = false;
                  });
                },
                child: Container(
                  decoration: resultContainerDecoration,
                  height: 75,
                  width: 500,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Shimmer.fromColors(
                          baseColor: TileStyles.primaryColorLightHSL
                              .toColor()
                              .withAlpha(100),
                          highlightColor: Colors.white.withAlpha(100),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(31, 31, 31, 0.8),
                                borderRadius: BorderRadius.circular(8)),
                          )),
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                                margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                child: Icon(Icons.search)),
                            Flexible(
                              child: Container(
                                child: Text(
                                  this.widget.textField!.controller!.text,
                                  style: TextStyle(
                                      fontSize: 22.5,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ));
          });
        }

        List<Widget> retrievedWidgets = await onInputChangedAsync(
            this.widget.textField!.controller!.text, collapseResultContainer);
        if (retrievedWidgets.length > 0) {
          setState(() {
            resultViewContainer = GestureDetector(
                onTap: () {
                  setState(() {
                    showResponseContainer = false;
                  });
                },
                child: Container(
                    decoration: this.widget.resultBoxDecoration,
                    child: ListView(
                      children: retrievedWidgets,
                    )));
          });
        } else {
          setState(() {
            resultViewContainer = blankResult;
            showResponseContainer = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextField? textField = this.widget.textField;
    List<Widget> allWidgets = [];

    double heightOfTextContainer = 120;
    double topMarginOfListContainer = heightOfTextContainer;
    double bottomMarginOfListContainer = 0;
    if (!this.widget.renderBelowTextfield) {
      topMarginOfListContainer = 0;
      bottomMarginOfListContainer = heightOfTextContainer * 4;
    }
    TextEditingController? textEditingController;

    if (textField == null) {
      textEditingController = TextEditingController();
      textField = TextField(
        controller: textEditingController,
      );
      this.widget.textField = textField;
      createdControllers.add(textEditingController);
    } else {
      if (textField.controller != null) {
        textEditingController = textField.controller!;
      }
    }

    textEditingController?.addListener(this.onInputChangeDefault);
    Container textFieldContainer = Container(
      margin: EdgeInsets.fromLTRB(0, 13, 0, 0),
      child: textField,
    );

    allWidgets = [textFieldContainer];

    if (showResponseContainer) {
      EdgeInsetsGeometry? resultsMargin = this.widget.resultMargin;
      if (resultsMargin == null) {
        resultsMargin = EdgeInsets.fromLTRB(
            0, topMarginOfListContainer, 0, bottomMarginOfListContainer);
      }
      Container listContainer = Container(
        margin: resultsMargin,
        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: resultViewContainer,
      );
      allWidgets.add(listContainer);
    }

    return Container(
      margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Stack(
        children: allWidgets,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in createdControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
