import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/styles.dart';

import '../../constants.dart';
import 'timeScrub.dart';

class TileWidget extends StatefulWidget {
  late Timeline timeline;
  TileWidgetState? _state;
  TileWidget(timeline) : super(key: Key(timeline.id)) {
    assert(timeline != null);
    this.timeline = timeline;
  }
  @override
  TileWidgetState createState() {
    _state = TileWidgetState();
    return _state!;
  }

  Future<TileWidgetState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<TileWidgetState> retValue = new Future.delayed(
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

class TileWidgetState extends State<TileWidget> {
  void updateTimeline(Timeline timeline) async {
    this.widget.timeline = timeline;
  }

  @override
  Widget build(BuildContext context) {
    var timeline = widget.timeline;

    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: TileStyles.tileWidth,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              borderRadius: BorderRadius.circular(TileStyles.borderRadius),
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
                  borderRadius: BorderRadius.circular(TileStyles.borderRadius),
                ),
                child: Column(
                  children: allElements,
                )),
          )),
    );
  }
}
