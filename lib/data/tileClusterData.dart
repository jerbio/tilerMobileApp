import 'package:flutter/scheduler.dart';
import 'package:tiler_app/data/emailDesignatedUser.dart';
import 'package:tiler_app/data/phoneDesignatedUser.dart';
import 'package:tiler_app/data/tileTemplateData.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class TileClusterData {
  String? name;
  List<EmailDesignatedUser>? emails;
  List<PhoneDesignatedUser>? phoneNumbers;
  List<TileTemplateData>? tileTemplates;
  int? durationInMs;
  int? startTimeInMs;
  int? endTimeInMs;
  TilePriority priority = TilePriority.medium;
}
