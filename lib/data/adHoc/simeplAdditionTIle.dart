import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';

class SimpleAdditionTile with PreTile {
  String? description;
  Duration? duration;
  DateTime? endTime;
  Location? location;
  SimpleAdditionTile({this.description, this.duration, this.endTime, this.location});
}
