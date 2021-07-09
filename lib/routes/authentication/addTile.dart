import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddTile extends StatefulWidget {
  Function? onAddTileClose;
  Function? onAddingATile;
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  TextEditingController tileName = TextEditingController();
  @override
  Widget build(BuildContext context) {
    List<Widget> childrenWidgets = [];
    Widget tileNameContainer = Container(
        child: TextField(
      controller: tileName,
      decoration: InputDecoration(
        hintText: 'Tile Name',
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(10, 20, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(50.0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
          borderSide: BorderSide(color: Colors.white, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
    ));
    childrenWidgets.add(tileNameContainer);

    Widget retValue = Scaffold(
        body: Container(
      child: Column(
        children: childrenWidgets,
      ),
    ));

    return retValue;
  }

  @override
  void dispose() {
    tileName.dispose();
    super.dispose();
  }
}
