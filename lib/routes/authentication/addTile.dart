import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/services.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tuple/tuple.dart';

class AddTile extends StatefulWidget {
  Function? onAddTileClose;
  Function? onAddingATile;
  final ScheduleApi scheduleApi = ScheduleApi();
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  TextEditingController tileName = TextEditingController();
  TextEditingController splitCount = TextEditingController();
  Duration _duration = Duration(hours: 0, minutes: 0);
  DateTime _endTime = Utility.todayTimeline().endTime!.add(Utility.oneDay);

  Widget getTileNameWidget() {
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
    return tileNameContainer;
  }

  Widget getSplitCountWidget() {
    Widget splitCountContainer = Container(
        child: TextField(
      controller: splitCount,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: InputDecoration(
        hintText: 'Split Count',
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
    return splitCountContainer;
  }

  Widget generateDurationPicker() {
    Widget retValue = DurationPicker(
        duration: _duration,
        onChange: (val) {
          setState(() => _duration = val);
        },
        snapToMins: 10.0);
    return retValue;
  }

  void onEndTimeTap() async {
    TimeOfDay _endTimeOfDay = TimeOfDay.fromDateTime(_endTime);
    final TimeOfDay? revisedEndTime =
        await showTimePicker(context: context, initialTime: _endTimeOfDay);
    if (revisedEndTime != null) {
      DateTime updatedEndTime = new DateTime(_endTime.year, _endTime.month,
          _endTime.day, revisedEndTime.hour, revisedEndTime.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  void onEndDateTap() async {
    DateTime _endDate = this._endTime;
    DateTime firstDate = _endTime.add(Duration(days: -14));
    DateTime lastDate = _endTime.add(Duration(days: 90));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select a deadline',
    );
    if (revisedEndDate != null) {
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endTime.hour,
          _endTime.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  void onSubmitButtonTap() async {
    NewTile tile = new NewTile();
    tile.Name = this.tileName.value.text;
    tile.DurationHours = this._duration.inHours.toString();
    tile.DurationMins = this._duration.inMinutes.toString();
    tile.DurationDays = this._duration.inDays.toString();
    tile.EndYear = this._endTime.year.toString();
    tile.EndMonth = this._endTime.month.toString();
    tile.EndDay = this._endTime.day.toString();
    tile.EndHour = this._endTime.hour.toString();
    tile.EndMins = this._endTime.minute.toString();

    DateTime now = DateTime.now();
    tile.StartYear = now.year.toString();
    tile.StartMonth = now.month.toString();
    tile.StartDay = now.day.toString();
    tile.StartHour = '0';
    tile.StartMins = '0';
    tile.isEveryDay = false.toString();
    tile.isRestricted = false.toString();
    tile.isWorkWeek = false.toString();

    tile.Count = this.splitCount.value.text;
    Tuple2 newlyAddedTile = await this.widget.scheduleApi.addNewTile(tile);
    if (newlyAddedTile.item1 != null) {
      SubCalendarEvent subEvent = newlyAddedTile.item1;
      print(subEvent.name);
    }
  }

  Widget generateTimePicker(BuildContext context) {
    Widget endTimeContainer = Container(
        child: Row(
      children: [
        Text(_endTime.toString()),
        ElevatedButton(
          onPressed: this.onEndTimeTap,
          child: Text('SELECT TIME'),
        ),
        ElevatedButton(
          onPressed: this.onEndDateTap,
          child: Text('SELECT DATE'),
        )
      ],
    ));
    return endTimeContainer;
  }

  Widget generateSubmitTile() {
    Widget submitContainer = Container(
        child: ElevatedButton(
      onPressed: this.onSubmitButtonTap,
      child: Text('Submit Tile'),
    ));
    return submitContainer;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenWidgets = [];
    Widget tileNameWidget = this.getTileNameWidget();
    Widget durationPicker = this.generateDurationPicker();
    Widget timePicker = this.generateTimePicker(context);
    Widget splitCountWidget = this.getSplitCountWidget();
    Widget submitTileWidget = this.generateSubmitTile();
    childrenWidgets.add(tileNameWidget);
    childrenWidgets.add(durationPicker);
    childrenWidgets.add(splitCountWidget);
    childrenWidgets.add(timePicker);
    childrenWidgets.add(submitTileWidget);

    Widget retValue = Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
