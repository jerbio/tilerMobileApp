import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/styles.dart';

class EditTileName extends StatefulWidget{
  SubCalendarEvent subEvent;
  late String tileName;
  Function? onInputChange;
  EditTileName({required this.subEvent, this.onInputChange}) {
    tileName = subEvent.name == null ? "" : subEvent.name!;
  }

  String get name {
    return tileName;
  }
  
  @override
  _EditTileNameState createState() => _EditTileNameState();
}

class _EditTileNameState extends State<EditTileName> {
  late TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
        if(this.widget.onInputChange != null){
      // this.widget.nameEditingController.addListener(() {
      //   this.widget.onInputChange!();
      // })
      _controller.text  = this.widget.subEvent.name == null ? "" : this.widget.subEvent.name!;
      _controller.addListener(() {
        this.widget.tileName = _controller.text;
        // this.widget.nameEditingController = TextEditingController(text: _controller.text);
        this.widget.onInputChange!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
      Flexible(
          child: new Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: TextField(
                // controller: this.widget.nameEditingController,
                controller: _controller,
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(31, 31, 31, 1)),
              )))
        ],
      ),
    );
  }
}