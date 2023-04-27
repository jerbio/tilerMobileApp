import 'package:tiler_app/data/tileObject.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class NextTileSuggestion extends TilerObj {
  String? id;
  String? name;
  String? locationName;
  bool? isConvertedToTile;
  TilerEvent? tilerEvent;
  String? location;

  NextTileSuggestion.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('locationName')) {
      locationName = json['locationName'];
    }

    if (json.containsKey('isConvertedToTile')) {
      isConvertedToTile = json['isConvertedToTile'];
    }

    if (json.containsKey('tilerEvent')) {
      tilerEvent = json['tilerEvent'];
    }

    if (json.containsKey('location')) {
      location = json['location'];
    }
  }
}
