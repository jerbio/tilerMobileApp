import 'package:tiler_app/data/emailDesignatedUser.dart';
import 'package:tiler_app/data/phoneDesignatedUser.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class TileTemplateData {
  String? name;
  List<EmailDesignatedUser>? emails;
  List<PhoneDesignatedUser>? phoneNumbers;
  int? durationInMs;
  int? startTimeInMs;
  int? endTimeInMs;
  TilePriority priority = TilePriority.medium;
}
