import 'package:tiler_app/data/location.dart';

class AutoTile {
  String description;
  String image;
  Duration duration;
  Location? location;
  AutoTile(
      {required this.description, required this.image, required this.duration});
}
