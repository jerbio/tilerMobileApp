import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late  TileThemeExtension tileThemeExtension;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;

  }
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
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.r),
              topRight: Radius.circular(10.r),
              bottomLeft: Radius.circular(10.r),
              bottomRight: Radius.circular(10.r)
          ),
          boxShadow: [
            BoxShadow(
              color: tileThemeExtension.shadowSearch.withValues(alpha: 0.2),
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
                  height: 75.h,
                  width: 500.w,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Shimmer.fromColors(
                          baseColor: colorScheme.primaryContainer.withAlpha(100),
                          highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
                          child: Container(
                            decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8.r)),
                          )),
                      Container(
                        padding: EdgeInsets.all(20.r),
                        child: Row(
                          children: [
                            Container(
                                margin: EdgeInsets.fromLTRB(0, 5.h, 0, 0),
                                child: Icon(Icons.search)),
                            Flexible(
                              child: Container(
                                child: Text(
                                  this.widget.textField!.controller!.text,
                                  style: TextStyle(
                                      fontSize: 22.5.sp,
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

    double heightOfTextContainer = 120.h;
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
      margin: EdgeInsets.fromLTRB(0, 13.h, 0, 0),
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
        padding: EdgeInsets.all(5.r),
        child: resultViewContainer,
      );
      allWidgets.add(listContainer);
    }

    return Container(
      margin: EdgeInsets.fromLTRB(0, 10.h, 0, 0),
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
