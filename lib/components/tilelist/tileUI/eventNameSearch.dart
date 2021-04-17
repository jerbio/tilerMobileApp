import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/tileUI/searchComponent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/util.dart';

class EventNameSearchWidget extends SearchWidget {
  EventNameSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      renderBelowTextfield = true,
      Key key})
      : super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            key: key);

  @override
  EventNameSearchState createState() => EventNameSearchState();
}

class EventNameSearchState extends SearchWidgetState {
  TileNameApi tileNameApi = new TileNameApi();
  TextEditingController textController = TextEditingController();
  Widget tileToEventNameWidget(TilerEvent tile) {
    Container textContainer = Container(
      child: Text(tile.name),
    );

    Container iconContainer = Container(
      alignment: Alignment.centerRight,
      child: Container(
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.green,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      // primary: Colors.transparent, // background
                      // onPrimary: Colors.white,
                      // shadowColor: Colors.transparent, // foreground
                      // alignment: Alignment(-1.0, -1.0)
                      ),
                  onPressed: Utility.noop,
                  child: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey,
                  )),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.transparent, // background
                    onPrimary: Colors.white,
                    shadowColor: Colors.transparent // foreground
                    ),
                onPressed: Utility.noop,
                child: Icon(Icons.check, color: Colors.grey)),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.transparent, // background
                    onPrimary: Colors.white,
                    shadowColor: Colors.transparent // foreground
                    ),
                onPressed: Utility.noop,
                child: Transform.rotate(
                  angle: -pi / 2,
                  child: Icon(Icons.chevron_right, color: Colors.grey),
                ))
          ],
        ),
      ),
    );
    return Row(
      children: [textContainer, iconContainer],
    );
  }

  Future<List<Widget>> _onInputFieldChange(String name) async {
    List<Widget> retValue = [
      Container(
        child: Text('No match was found'),
      )
    ];
    List<TilerEvent> tileEvents = await tileNameApi.getTilesByName(name);
    if (tileEvents.length > 0) {
      retValue = tileEvents.map((tile) => tileToEventNameWidget(tile)).toList();
    }

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    // this.widget.renderBelowTextfield = false;
    String hintText = 'Tile name';
    this.widget.onChanged = this._onInputFieldChange;
    this.widget.textField = TextField(
      controller: textController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.arrow_back),
        hintText: hintText,
      ),
    );
    return super.build(context);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
