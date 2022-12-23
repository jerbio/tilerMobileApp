import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/util.dart';

class EventNameSearchWidget extends SearchWidget {
  EventNameSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      context,
      renderBelowTextfield = true,
      Key? key})
      : super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            onBackButtonPressed: () {
              Navigator.pop(context);
            },
            key: key);
  @override
  EventNameSearchState createState() => EventNameSearchState();
}

class EventNameSearchState extends SearchWidgetState {
  TileNameApi tileNameApi = new TileNameApi();
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  TextEditingController textController = TextEditingController();
  List<Widget> nameSearchResult = [];

  Function? createSetAsNowCallBack(String tileId) {
    Function retValue = () async => {await calendarEventApi.setAsNow(tileId)};
    return retValue;
  }

  Function? createDeletionCallBack(String tileId, String thirdPartyId) {
    Function retValue =
        () async => {await calendarEventApi.delete(tileId, thirdPartyId)};
    return retValue;
  }

  Function? createCompletionCallBack(String tileId) {
    Function retValue = () async => {await calendarEventApi.complete(tileId)};
    return retValue;
  }

  Widget tileToEventNameWidget(TilerEvent tile) {
    List<Widget> childWidgets = [];
    Widget textContainer;
    if (tile.name != null) {
      if (tile.start != null && tile.end != null) {
        DateTime start =
            DateTime.fromMillisecondsSinceEpoch(tile.start!.toInt());
        DateTime end = DateTime.fromMillisecondsSinceEpoch(tile.end!.toInt());
        String monthString = Utility.returnMonth(end);
        monthString = monthString.substring(0, 3);
        Widget deadlineContainer = Container(
          margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
          padding: EdgeInsets.fromLTRB(15, 0, 20, 0),
          child: Column(
            children: [
              Text(monthString, style: TextStyle(fontSize: 25)),
              Text(end.day.toString(), style: TextStyle(fontSize: 20)),
            ],
          ),
        );
        childWidgets.add(deadlineContainer);
      }

      List<Widget> detailWidgets = [];
      textContainer = FractionallySizedBox(
          widthFactor: 0.8,
          child: Container(
            margin: EdgeInsets.fromLTRB(30, 10, 0, 0),
            child: Expanded(
                child: Text(tile.name!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18))),
          ));
      detailWidgets.add(textContainer);
      Function setAsNowCallBack = createSetAsNowCallBack(tile.id!)!;
      Function completionCallBack = createCompletionCallBack(tile.id!)!;
      Function deletionCallBack =
          createDeletionCallBack(tile.id!, tile.thirdpartyId)!;
      Widget iconContainer =
          // FractionallySizedBox(
          //     widthFactor: 0.9,
          //     child:
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                // width: 200,
                color: Colors.blue,
                margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      iconSize: 40,
                      color: Colors.red,
                      onPressed: () => {deletionCallBack()},
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      iconSize: 40,
                      color: Colors.green,
                      onPressed: () => {completionCallBack()},
                    )
                  ],
                ),
              ))
          //)
          ;

      Widget nowButton = Align(
          alignment: Alignment.topRight,
          child: Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: IconButton(
                  icon: Transform.rotate(
                    angle: -pi / 2,
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 35,
                    ),
                  ),
                  onPressed: () => {setAsNowCallBack()})));

      detailWidgets.add(iconContainer);
      detailWidgets.add(nowButton);

      Container detailContainer = Container(
        margin: EdgeInsets.fromLTRB(60, 10, 0, 0),
        child: Stack(
          children: detailWidgets,
        ),
      );
      childWidgets.add(detailContainer);
    }

    Key dismissibleKey = Key(tile.id!);
    Widget retValue = Dismissible(
        key: dismissibleKey,
        child: Container(
          height: 150,
          padding: EdgeInsets.fromLTRB(7, 7, 7, 7),
          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: childWidgets,
          ),
        ));

    return retValue;
  }

  Future<List<Widget>> _onInputFieldChange(
      String name, Function callBackOnCloseInput) async {
    List<Widget> retValue = this.nameSearchResult;

    if (name.length > 3) {
      List<TilerEvent> tileEvents = await tileNameApi.getTilesByName(name);
      retValue = tileEvents.map((tile) => tileToEventNameWidget(tile)).toList();
      if (retValue.length == 0) {
        retValue = [
          Container(
            child: Text('No match was found'),
          )
        ];
      }
    }

    setState(() {
      nameSearchResult = retValue;
    });

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    String hintText = 'Tile name';
    this.widget.onChanged = this._onInputFieldChange;
    this.widget.textField = TextField(
      controller: textController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.arrow_back),
        hintText: hintText,
      ),
    );
    var hslLightColor = HSLColor.fromColor(Color.fromRGBO(0, 194, 237, 1));
    hslLightColor = hslLightColor.withLightness(hslLightColor.lightness + 0.4);
    var hslDarkColor = HSLColor.fromColor(Color.fromRGBO(0, 119, 170, 1));
    hslDarkColor = hslDarkColor.withLightness(hslDarkColor.lightness + 0.4);

    this.widget.resultBoxDecoration = BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
          hslLightColor.toColor(),
          hslLightColor.toColor(),
          hslLightColor.toColor(),
          hslDarkColor.toColor(),
          hslDarkColor.toColor()
        ]));
    return Scaffold(
      body: super.build(context),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
