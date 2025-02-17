import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/util.dart';

mixin PreTile {
  String id = Utility.getUuid;
  String? description;
  String? image;
  Duration? duration;
  Location? location;
  DateTime? startTime;
  DateTime? endTime;
}
