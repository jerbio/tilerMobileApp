import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Add this import
import 'package:tiler_app/components/TextInputWidget.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/data/request/NewTile.dart';

class NewTileSheetWidget extends StatefulWidget {
  final Function? onAddTile;
  final Function? onCancel;
  final NewTile? newTile;
  NewTileSheetWidget({this.onAddTile, this.onCancel, this.newTile});
  @override
  NewTileSheetState createState() => NewTileSheetState();
}

class NewTileSheetState extends State<NewTileSheetWidget> {
  late final NewTile newTile;
  @override
  void initState() {
    super.initState();
    this.newTile = this.widget.newTile ?? NewTile();
  }

  Widget _renderOptionalFields() {
    return SizedBox.shrink();
  }

  void onTileNameChange(String? tileName) {
    newTile.Name = "";
    if (tileName != null && tileName.isNotEmpty) {
      newTile.Name = tileName;
      setState(() {});
    }
  }

  void onDurationChange(Duration? duration) {
    newTile.DurationDays = "";
    newTile.DurationHours = "";
    newTile.DurationMinute = "";
    if (duration != null && duration.inMinutes > 0) {
      int totalMinutes = duration.inMinutes;
      int dayInMinutes = Duration.minutesPerDay;
      int hourInMinutes = Duration.minutesPerHour;
      int days = totalMinutes ~/ dayInMinutes;
      totalMinutes = totalMinutes % dayInMinutes;
      int hours = totalMinutes ~/ hourInMinutes;
      int minutes = totalMinutes % hourInMinutes;
      newTile.DurationDays = days.toString();
      newTile.DurationHours = hours.toString();
      newTile.DurationMinute = minutes.toString();
    }
  }

  Duration? _getDuration() {
    int dayInMinutes = Duration.minutesPerDay;
    int hourInMinutes = Duration.minutesPerHour;
    int? totalMinutes;
    if (newTile.DurationDays != null && newTile.DurationDays!.isNotEmpty) {
      int? days = int.tryParse(newTile.DurationDays!);
      if (days != null) {
        totalMinutes = (totalMinutes ?? 0) + dayInMinutes * days;
      }
    }

    if (newTile.DurationHours != null && newTile.DurationHours!.isNotEmpty) {
      int? hours = int.tryParse(newTile.DurationHours!);
      if (hours != null) {
        totalMinutes = (totalMinutes ?? 0) + hourInMinutes * hours;
      }
    }

    if (newTile.DurationMinute != null && newTile.DurationMinute!.isNotEmpty) {
      int? minutes = int.tryParse(newTile.DurationMinute!);
      if (minutes != null) {
        totalMinutes = (totalMinutes ?? 0) + minutes;
      }
    }

    if (totalMinutes != null) {
      return Duration(minutes: totalMinutes);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextInputWidget(
          value: newTile.Name,
          onTextChange: (value) {
            newTile.Name = value;
          },
        ),
        DurationInputWidget(
          duration: _getDuration(),
          onDurationChange: onDurationChange,
        ),
        _renderOptionalFields(),
        ElevatedButton.icon(
            onPressed: () {
              if (this.widget.onAddTile != null) {
                this.widget.onAddTile!(newTile);
              }
            },
            icon: Icon(Icons.check),
            label: Text(AppLocalizations.of(context)!.complete)),
        ElevatedButton.icon(
            onPressed: () {
              if (this.widget.onCancel != null) {
                this.widget.onCancel!();
              }
            },
            icon: Icon(Icons.cancel),
            label: Text(AppLocalizations.of(context)!.cancel))
      ],
    );
  }
}
