import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/util.dart';

class AutoTile with PreTile {
  String id = Utility.getUuid;
  String? description;
  String? image;
  Duration? duration;
  Location? location;
  String? categoryId;
  DateTime? startTime;
  DateTime? endTime;
  bool isLastCard;
  AutoTile(
      {required this.description,
      this.image,
      this.duration,
      this.categoryId,
      this.isLastCard = false,
      this.startTime,
      this.endTime});
}
