import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart';
import 'timeScrub.dart';
//ey: not used
class ChillTimeWidget extends StatefulWidget {
  late Timeline timeline;
  ChillTimeWidgetState? _state;
  final List<String> chillTexts = ['Chill Now', 'Take a Break', 'Zen Mode'];
  final List<String> chillImagePaths = [
    'assets/images/person_in_bed.png',
    'assets/images/umbrella_on_ground.png',
    'assets/images/bath.png',
    'assets/images/person_in_lotus_position.png',
    'assets/images/pinched_fingers.png'
  ];
  ChillTimeWidget(timeline) {
    assert(timeline != null);
    this.timeline = timeline;
  }

  @override
  ChillTimeWidgetState createState() {
    _state = ChillTimeWidgetState();
    return _state!;
  }

  Future<ChillTimeWidgetState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<ChillTimeWidgetState> retValue = new Future.delayed(
          const Duration(milliseconds: stateRetrievalRetry), () {
        return this.state;
      });

      return retValue;
    }
  }

  void updateTimeline(Timeline timeline) async {
    this.timeline = timeline;
    var state = await this.state;
    state.updateTimeline(timeline);
  }
}

class ChillTimeWidgetState extends State<ChillTimeWidget> {
  void updateTimeline(Timeline timeline) async {
    this.widget.timeline = timeline;
  }

  @override
  Widget build(BuildContext context) {
    var timeline = widget.timeline;
    var tileBackGroundColor = Color.fromRGBO(51, 51, 51, 1);

    String chillText = this.widget.chillTexts.randomEntry;
    String chillImage = this.widget.chillImagePaths.randomEntry;
    var chillNameWidget = Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
      child: Text(
        chillText,
        style: TextStyle(
            fontSize: 20,
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),
    );

    var sleepIconAndRow = Row(
      children: [chillNameWidget],
    );

    var sleepInBedIcon = Container(
      margin: const EdgeInsets.fromLTRB(0, 50, 0, 0),
      alignment: Alignment.center,
      child: Image.asset(
        chillImage,
        scale: 1.5,
      ),
    );

    var timeScrub = FractionallySizedBox(
        alignment: FractionalOffset.center,
        widthFactor: TileDimensions.inputWidthFactor,
        child: Container(
            margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: TimeScrubWidget(
              timeline: timeline,
              loadTimeScrub: true,
            )));

    var allEntry = Column(
      children: [sleepIconAndRow, sleepInBedIcon, timeScrub],
    );

    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Material(
          type: MaterialType.transparency,
          child: FractionallySizedBox(
              widthFactor: TileDimensions.tileWidthRatio,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 5,
                  ),
                  borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 20,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    decoration: BoxDecoration(
                      color: tileBackGroundColor,
                      border: Border.all(
                        color: Colors.white,
                        width: 0.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(TileDimensions.borderRadius),
                    ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: allEntry,
                    )),
              ))),
    );
  }
}
