import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/util.dart';

class AutoTile {
  String id = Utility.getUuid;
  String description;
  String image;
  Duration duration;
  Location? location;
  String categoryId;
  bool isLastCard;
  AutoTile(
      {required this.description,
      required this.image,
      required this.duration,
      required this.categoryId,
      this.isLastCard = false});
}
