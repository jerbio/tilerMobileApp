import 'package:flutter/material.dart';

const defaultChartValueStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

const defaultLegendStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.bold,
);
 String toHuman(Duration duration,
      {bool all = false, bool includeSeconds = false, abbreviations = false}) {
    Duration durationLeft = duration;
    var stringArr = [];
    int days = durationLeft.inDays;
    if (days > 0) {
      Duration dayDuration = Duration(days: days);
      durationLeft = durationLeft - dayDuration;
      String dayString = 'days';
      if (days == 1) {
        dayString = 'day';
      }
      stringArr.add('$days $dayString');
    }

    int hours = durationLeft.inHours;
    if (hours > 0) {
      Duration hourDuration = Duration(hours: hours);
      durationLeft = durationLeft - hourDuration;

      String hourString = 'hours';
      if (abbreviations) {
        hourString = 'hrs';
      }
      if (hours == 1) {
        hourString = 'hour';
        if (abbreviations) {
          hourString = 'hr';
        }
      }
      stringArr.add('$hours $hourString');
    }

    int minute = durationLeft.inMinutes;
    if (minute > 0) {
      Duration minDuration = Duration(minutes: minute);
      durationLeft = durationLeft - minDuration;

      String minuteString = 'minutes';
      if (abbreviations) {
        minuteString = 'mins';
      }
      if (minute == 1) {
        minuteString = 'minute';
        if (abbreviations) {
          minuteString = 'min';
        }
      }
      stringArr.add('$minute $minuteString');
    }

    if (includeSeconds) {
      int seconds = durationLeft.inSeconds;
      if (seconds > 0) {
        Duration secondDuration = Duration(minutes: seconds);
        durationLeft = durationLeft - secondDuration;

        String secondString = 'seconds';
        if (abbreviations) {
          secondString = 's';
        }
        if (seconds == 1) {
          secondString = 'second';
          if (abbreviations) {
            secondString = 's';
          }
        }
        stringArr.add('$seconds $secondString');
      }
    }

    String retValue = '';
    if (stringArr.length > 1) {
      if (all) {
        var subAllStrings = stringArr.sublist(0, stringArr.length - 1);
        retValue = subAllStrings.join(', ');
        retValue += " and ";
      } else {
        stringArr = [stringArr[0]];
      }
    } else if (stringArr.length == 0) {
      stringArr = ["0 Minutes"];
    }
    String lastString = stringArr.last;
    retValue += "$lastString";
    return retValue;
    }
      
const List<Color> defaultColorList = [
  Color(0xFFff7675),
  Color(0xFF74b9ff),
  Color(0xFF55efc4),
  Color(0xFFffeaa7),
  Color(0xFFa29bfe),
  Color(0xFFfd79a8),
  Color(0xFFe17055),
  Color(0xFF00b894),
];

Color getColor(List<Color> colorList, int index) {
  if (index > (colorList.length - 1)) {
    final newIndex = index % (colorList.length - 1);
    return colorList.elementAt(newIndex);
  }
  return colorList.elementAt(index);
}

List<Color> getGradient(List<List<Color>> gradientList, int index,
    {required bool isNonGradientElementPresent,
    required List<Color> emptyColorGradient}) {
  index = isNonGradientElementPresent ? index - 1 : index;
  if (index == -1) {
    return emptyColorGradient;
  } else if (index > (gradientList.length - 1)) {
    final newIndex = index % gradientList.length;
    return gradientList.elementAt(newIndex);
  }
  return gradientList.elementAt(index);
}
